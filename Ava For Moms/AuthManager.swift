import SwiftUI
import Supabase
import AuthenticationServices
import CryptoKit

@Observable
@MainActor
final class AuthManager: NSObject {

    // MARK: - State

    enum AuthState { case loading, authenticated, unauthenticated }

    var state: AuthState = .loading
    var currentUserId: UUID?
    var isLoading = false
    var errorMessage: String?

    // Apple Sign In async bridge
    private var appleSignInContinuation: CheckedContinuation<ASAuthorization, Error>?
    private var pendingNonce: String?

    override init() {
        super.init()
        listenToAuthChanges()
    }

    // MARK: - Auth state listener

    private func listenToAuthChanges() {
        Task {
            for await (event, session) in supabase.auth.authStateChanges {
                switch event {
                case .initialSession:
                    if let s = session { currentUserId = s.user.id; state = .authenticated }
                    else               { state = .unauthenticated }
                case .signedIn:
                    if let s = session { currentUserId = s.user.id; state = .authenticated }
                case .signedOut, .userDeleted:
                    currentUserId = nil; state = .unauthenticated
                case .tokenRefreshed:
                    if let s = session { currentUserId = s.user.id }
                default: break
                }
            }
        }
    }

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
                appleSignInContinuation = cont
                let controller = ASAuthorizationController(authorizationRequests: [request])
                controller.delegate = self
                controller.presentationContextProvider = self
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
    // SDK method is signIn(email:password:) — NOT signInWithPassword

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

    // MARK: - Save onboarding data to Supabase
    // update() and insert() throw synchronously — separate try from await with let bindings

    func saveOnboardingData(_ data: OnboardingData) async {
        guard let userId = currentUserId else { return }
        do {
            // Update profile (returning: .minimal avoids a SELECT round-trip)
            let profileQuery = try supabase
                .from("profiles")
                .update(
                    ProfileUpdate(
                        name: data.name,
                        workStatus: data.workStatus.rawValue
                            .lowercased()
                            .replacingOccurrences(of: " ", with: "_"),
                        hasSchoolPickup: data.hasSchoolPickup,
                        mentalLoadAreas: data.mentalLoadAreas.map(\.rawValue),
                        onboardingCompleted: true
                    ),
                    returning: .minimal
                )
                .eq("id", value: userId)
            try await profileQuery.execute()

            // Insert partner
            if data.hasPartner, !data.partnerName.trimmingCharacters(in: .whitespaces).isEmpty {
                let partnerQuery = try supabase
                    .from("family_members")
                    .insert(
                        FamilyMemberInsert(
                            userId: userId.uuidString,
                            name: data.partnerName,
                            relationship: "partner",
                            age: nil,
                            colorHex: "#B6A092"
                        ),
                        returning: .minimal
                    )
                try await partnerQuery.execute()
            }

            // Insert kids
            for kid in data.kids where !kid.name.trimmingCharacters(in: .whitespaces).isEmpty {
                let kidQuery = try supabase
                    .from("family_members")
                    .insert(
                        FamilyMemberInsert(
                            userId: userId.uuidString,
                            name: kid.name,
                            relationship: "child",
                            age: kid.age,
                            colorHex: "#A5C09A"
                        ),
                        returning: .minimal
                    )
                try await kidQuery.execute()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Error mapping

    enum AuthError: LocalizedError {
        case invalidCredential
        var errorDescription: String? { "Sign in failed. Please try again." }
    }

    private func friendlyError(_ error: Error) -> String {
        let msg = error.localizedDescription.lowercased()
        if msg.contains("invalid login") || msg.contains("invalid credentials") {
            return "Incorrect email or password."
        }
        if msg.contains("already registered") || msg.contains("already exists") {
            return "An account with this email already exists — try signing in."
        }
        if msg.contains("weak") || msg.contains("at least") {
            return "Password must be at least 6 characters."
        }
        return "Something went wrong. Please try again."
    }

    // MARK: - Crypto (required for Apple Sign In nonce)

    private func randomNonceString(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            (0..<16)
                .map { _ -> UInt8 in var b: UInt8 = 0; _ = SecRandomCopyBytes(kSecRandomDefault, 1, &b); return b }
                .forEach { b in
                    guard remaining > 0 else { return }
                    if b < charset.count { result.append(charset[Int(b)]); remaining -= 1 }
                }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthManager: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        Task { @MainActor in
            appleSignInContinuation?.resume(returning: authorization)
            appleSignInContinuation = nil
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        Task { @MainActor in
            appleSignInContinuation?.resume(throwing: error)
            appleSignInContinuation = nil
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
// MainActor.assumeIsolated is safe here — Apple always calls presentationAnchor on the main thread.
// UIWindow(windowScene:) is used instead of deprecated UIWindow().

extension AuthManager: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            let scene = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first { $0.activationState == .foregroundActive }
                ?? UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .first

            if let scene {
                return scene.windows.first { $0.isKeyWindow }
                    ?? scene.windows.first
                    ?? UIWindow(windowScene: scene)
            }
            return UIWindow()
        }
    }
}

// MARK: - Encodable DB models (file-private)

private struct ProfileUpdate: Encodable {
    let name: String
    let workStatus: String
    let hasSchoolPickup: Bool
    let mentalLoadAreas: [String]
    let onboardingCompleted: Bool

    enum CodingKeys: String, CodingKey {
        case name
        case workStatus          = "work_status"
        case hasSchoolPickup     = "has_school_pickup"
        case mentalLoadAreas     = "mental_load_areas"
        case onboardingCompleted = "onboarding_completed"
    }
}

private struct FamilyMemberInsert: Encodable {
    let userId: String
    let name: String
    let relationship: String
    let age: Int?
    let colorHex: String

    enum CodingKeys: String, CodingKey {
        case name, relationship, age
        case userId   = "user_id"
        case colorHex = "color_hex"
    }
}
