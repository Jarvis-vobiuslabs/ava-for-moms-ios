import SwiftUI
import Combine
import Supabase
import AuthenticationServices
import CryptoKit

// ─────────────────────────────────────────────────────────────────────────────
// File-level helper — Task{} lives here, outside @Observable, so the
// @Observable macro expansion doesn't interfere with Swift 6 type checking.
// ─────────────────────────────────────────────────────────────────────────────

private func makeAuthListenerTask(
    callback: @MainActor @escaping (AuthChangeEvent, Session?) -> Void
) -> _Concurrency.Task<Void, Never> {
    _Concurrency.Task {
        for await authState in supabase.auth.authStateChanges {
            await MainActor.run { callback(authState.event, authState.session) }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// AuthManager
// ─────────────────────────────────────────────────────────────────────────────

@Observable
final class AuthManager {

    enum AuthState { case loading, authenticated, unauthenticated }

    var state: AuthState = .loading
    var currentUserId: UUID?
    var isLoading = false
    var errorMessage: String?

    @ObservationIgnored private let appleHandler = AppleSignInHandler()
    @ObservationIgnored private var pendingNonce: String?
    @ObservationIgnored private var listenerTask: _Concurrency.Task<Void, Never>?

    init() {
        listenerTask = makeAuthListenerTask { [weak self] event, session in
            guard let self else { return }
            switch event {
            case .initialSession:
                if let s = session { self.currentUserId = s.user.id; self.state = .authenticated }
                else               { self.state = .unauthenticated }
            case .signedIn:
                if let s = session { self.currentUserId = s.user.id; self.state = .authenticated }
            case .signedOut, .userDeleted:
                self.currentUserId = nil; self.state = .unauthenticated
            case .tokenRefreshed:
                if let s = session { self.currentUserId = s.user.id }
            default: break
            }
        }
    }

    deinit { listenerTask?.cancel() }


    // MARK: - Sign in with Apple

    func signInWithApple() async {
        isLoading = true; errorMessage = nil
        defer { isLoading = false }
        do {
            let nonce = randomNonceString()
            pendingNonce = nonce

            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = sha256(nonce)

            let authorization = try await withCheckedThrowingContinuation { cont in
                appleHandler.continuation = cont
                let controller = ASAuthorizationController(authorizationRequests: [request])
                controller.delegate = appleHandler
                controller.presentationContextProvider = appleHandler
                controller.performRequests()
            }

            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = credential.identityToken,
                let idToken = String(data: tokenData, encoding: .utf8),
                let nonce = pendingNonce
            else { throw AuthError.invalidCredential }

            try await supabase.auth.signInWithIdToken(credentials: .init(
                provider: .apple, idToken: idToken, nonce: nonce
            ))
        } catch {
            if (error as? ASAuthorizationError)?.code != .canceled {
                errorMessage = friendlyError(error)
            }
        }
    }

    // MARK: - Email auth

    func signUp(email: String, password: String) async {
        isLoading = true; errorMessage = nil
        defer { isLoading = false }
        do    { try await supabase.auth.signUp(email: email, password: password) }
        catch { errorMessage = friendlyError(error) }
    }

    func signIn(email: String, password: String) async {
        isLoading = true; errorMessage = nil
        defer { isLoading = false }
        do    { try await supabase.auth.signIn(email: email, password: password) }
        catch { errorMessage = friendlyError(error) }
    }

    func signOut() async {
        do    { try await supabase.auth.signOut() }
        catch { errorMessage = error.localizedDescription }
    }

    // MARK: - Save onboarding data

    func saveOnboardingData(_ data: OnboardingData) async {
        guard let userId = currentUserId else { return }
        do {
            let workStatus = data.workStatus.rawValue.lowercased()
                .replacingOccurrences(of: " ", with: "_")
            let profileUpdate: [String: AnyJSON] = [
                "name": .string(data.name),
                "work_status": .string(workStatus),
                "has_school_pickup": .bool(data.hasSchoolPickup),
                "mental_load_areas": .array(data.mentalLoadAreas.map { .string($0.rawValue) }),
                "onboarding_completed": .bool(true),
            ]
            let pq = try supabase.from("profiles")
                .update(profileUpdate, returning: .minimal)
                .eq("id", value: userId)
            try await pq.execute()

            if data.hasPartner, !data.partnerName.trimmingCharacters(in: .whitespaces).isEmpty {
                let row: [String: AnyJSON] = [
                    "user_id": .string(userId.uuidString),
                    "name": .string(data.partnerName),
                    "relationship": .string("partner"),
                    "color_hex": .string("#B6A092"),
                ]
                try await (try supabase.from("family_members").insert(row, returning: .minimal)).execute()
            }

            for kid in data.kids where !kid.name.trimmingCharacters(in: .whitespaces).isEmpty {
                let row: [String: AnyJSON] = [
                    "user_id": .string(userId.uuidString),
                    "name": .string(kid.name),
                    "relationship": .string("child"),
                    "age": .integer(kid.age),
                    "color_hex": .string("#A5C09A"),
                ]
                try await (try supabase.from("family_members").insert(row, returning: .minimal)).execute()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Errors

    enum AuthError: LocalizedError {
        case invalidCredential
        var errorDescription: String? { "Sign in failed. Please try again." }
    }

    private func friendlyError(_ error: Error) -> String {
        let msg = error.localizedDescription.lowercased()
        if msg.contains("invalid login") || msg.contains("invalid credentials") { return "Incorrect email or password." }
        if msg.contains("already registered") || msg.contains("already exists") { return "An account with this email already exists — try signing in." }
        if msg.contains("weak") || msg.contains("at least") { return "Password must be at least 6 characters." }
        return "Something went wrong. Please try again."
    }

    // MARK: - Crypto

    private func randomNonceString(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            var random = [UInt8](repeating: 0, count: 16)
            _ = SecRandomCopyBytes(kSecRandomDefault, 16, &random)
            random.forEach { b in
                guard remaining > 0, b < charset.count else { return }
                result.append(charset[Int(b)]); remaining -= 1
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
