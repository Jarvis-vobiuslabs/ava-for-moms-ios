import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject private var auth: AuthManager
    var onboardingData: OnboardingData?
    var onComplete: () -> Void

    enum Mode { case signUp, signIn }
    @State private var mode: Mode
    @State private var email = ""
    @State private var password = ""
    @FocusState private var focused: Field?
    enum Field { case email, password }

    init(onboardingData: OnboardingData?, onComplete: @escaping () -> Void) {
        self.onboardingData = onboardingData
        self.onComplete = onComplete
        _mode = State(initialValue: onboardingData != nil ? .signUp : .signIn)
    }

    private var canSubmit: Bool { !email.isEmpty && password.count >= 6 && !auth.isLoading }

    var body: some View {
        ZStack {
            AvaTheme.bg.ignoresSafeArea()
            GeometryReader { geo in
                Circle().fill(AvaTheme.blush.opacity(0.2)).frame(width: 200)
                    .offset(x: geo.size.width - 60, y: -40)
            }.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 10) {
                        Text(mode == .signUp ? "Create your account" : "Welcome back")
                            .font(AvaTheme.font(30, weight: .heavy))
                            .foregroundStyle(AvaTheme.ink).tracking(-0.8)
                        Text(mode == .signUp ? "Takes 10 seconds." : "Sign in to continue.")
                            .font(AvaTheme.font(16, weight: .medium))
                            .foregroundStyle(AvaTheme.inkMute)
                    }
                    .padding(.horizontal, 28).padding(.top, 60).padding(.bottom, 32)

                    // Apple
                    Button {
                        Task { await auth.signInWithApple(); if auth.state == .authenticated { await finishAuth() } }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "apple.logo").font(.system(size: 18, weight: .semibold))
                            Text(mode == .signUp ? "Continue with Apple" : "Sign in with Apple")
                                .font(AvaTheme.font(16, weight: .bold))
                        }
                        .foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 14).fill(AvaTheme.ink))
                    }
                    .buttonStyle(.plain).padding(.horizontal, 28)

                    // Divider
                    HStack(spacing: 12) {
                        Rectangle().fill(AvaTheme.line).frame(height: 1)
                        Text("or").font(AvaTheme.font(13, weight: .medium)).foregroundStyle(AvaTheme.inkSoft)
                        Rectangle().fill(AvaTheme.line).frame(height: 1)
                    }
                    .padding(.horizontal, 28).padding(.vertical, 20)

                    // Fields
                    VStack(spacing: 12) {
                        inputField("envelope", placeholder: "Email address", text: $email,
                                   field: .email, secure: false,
                                   contentType: mode == .signUp ? .emailAddress : .username)
                        inputField("lock", placeholder: mode == .signUp ? "Create a password" : "Password",
                                   text: $password, field: .password, secure: true,
                                   contentType: mode == .signUp ? .newPassword : .password)
                    }
                    .padding(.horizontal, 28)

                    // Error
                    if let err = auth.errorMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill")
                            Text(err)
                        }
                        .font(AvaTheme.font(13, weight: .medium))
                        .foregroundStyle(Color(hex: "C0392B"))
                        .padding(.horizontal, 28).padding(.top, 12)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // CTA
                    Button {
                        Task {
                            if mode == .signUp { await auth.signUp(email: email, password: password) }
                            else               { await auth.signIn(email: email, password: password) }
                            if auth.state == .authenticated { await finishAuth() }
                        }
                    } label: {
                        ZStack {
                            Text(mode == .signUp ? "Create account" : "Sign in")
                                .font(AvaTheme.font(16, weight: .heavy)).foregroundStyle(.white)
                                .opacity(auth.isLoading ? 0 : 1)
                            if auth.isLoading { ProgressView().tint(.white) }
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 18)
                        .background(Capsule().fill(canSubmit
                            ? AnyShapeStyle(AvaTheme.blushTerracotta)
                            : AnyShapeStyle(AvaTheme.line)))
                        .animation(.easeInOut(duration: 0.2), value: canSubmit)
                    }
                    .buttonStyle(.plain).disabled(!canSubmit)
                    .padding(.horizontal, 28).padding(.top, 20)

                    // Toggle
                    Button { withAnimation { mode = mode == .signUp ? .signIn : .signUp } } label: {
                        Text(mode == .signUp
                             ? "Already have an account? **Sign in**"
                             : "No account? **Sign up**")
                            .font(AvaTheme.font(14, weight: .medium))
                            .foregroundStyle(AvaTheme.terracotta)
                    }
                    .buttonStyle(.plain).frame(maxWidth: .infinity)
                    .padding(.top, 16).padding(.bottom, 50)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: auth.errorMessage)
        }
    }

    private func finishAuth() async {
        if let data = onboardingData { await auth.saveOnboardingData(data) }
        onComplete()
    }

    private func inputField(
        _ icon: String, placeholder: String, text: Binding<String>,
        field: Field, secure: Bool, contentType: UITextContentType
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 15, weight: .medium))
                .foregroundStyle(AvaTheme.inkSoft).frame(width: 20)
            Group {
                if secure {
                    SecureField(placeholder, text: text).textContentType(contentType)
                } else {
                    TextField(placeholder, text: text)
                        .keyboardType(.emailAddress).textContentType(contentType)
                        .autocorrectionDisabled().textInputAutocapitalization(.never)
                }
            }
            .font(AvaTheme.font(15, weight: .medium)).foregroundStyle(AvaTheme.ink)
            .focused($focused, equals: field)
            .submitLabel(field == .email ? .next : .done)
            .onSubmit {
                if field == .email { focused = .password }
                else { Task {
                    if mode == .signUp { await auth.signUp(email: email, password: password) }
                    else               { await auth.signIn(email: email, password: password) }
                    if auth.state == .authenticated { await finishAuth() }
                }}
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(AvaTheme.cream))
    }
}

#Preview {
    AuthView(onboardingData: nil, onComplete: {})
        .environmentObject(AuthManager())
}
