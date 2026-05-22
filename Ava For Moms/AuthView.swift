import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @Environment(AuthManager.self) private var auth
    var onboardingData: OnboardingData?
    var onComplete: () -> Void

    // Three steps: email entry → OTP entry (email flow) or direct (Apple)
    enum Step { case email, otp }
    @State private var step: Step = .email
    @State private var email = ""
    @State private var otp = ""
    @State private var password = ""
    @State private var otpSent = false
    @State private var usePassword = false
    @FocusState private var emailFocused: Bool
    @FocusState private var otpFocused: Bool
    @FocusState private var passwordFocused: Bool

    init(onboardingData: OnboardingData?, onComplete: @escaping () -> Void) {
        self.onboardingData = onboardingData
        self.onComplete = onComplete
    }

    private var isNewUser: Bool { onboardingData != nil }
    private var emailValid: Bool { email.contains("@") && email.contains(".") }
    private var otpValid: Bool { otp.count == 6 }
    private var passwordValid: Bool { password.count >= 6 }

    var body: some View {
        ZStack {
            AvaTheme.bg.ignoresSafeArea()

            GeometryReader { geo in
                Circle().fill(AvaTheme.blush.opacity(0.2)).frame(width: 200)
                    .offset(x: geo.size.width - 60, y: -40)
            }.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // ── Header ─────────────────────────────────────────────
                    VStack(alignment: .leading, spacing: 10) {
                        if step == .otp {
                            Button { withAnimation { step = .email; otp = "" } } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 13, weight: .semibold))
                                    Text("Back")
                                        .font(AvaTheme.font(15, weight: .semibold))
                                }
                                .foregroundStyle(AvaTheme.inkMute)
                            }
                            .buttonStyle(.plain)
                            .padding(.bottom, 8)
                        }

                        Text(step == .email
                             ? (isNewUser ? "Create your account" : "Welcome back")
                             : "Check your email")
                            .font(AvaTheme.font(30, weight: .heavy))
                            .foregroundStyle(AvaTheme.ink).tracking(-0.8)

                        Text(step == .email
                             ? "Enter your email — we'll send you a code."
                             : "We sent a 6-digit code to\n\(email)")
                            .font(AvaTheme.font(16, weight: .medium))
                            .foregroundStyle(AvaTheme.inkMute).lineSpacing(3)
                    }
                    .padding(.horizontal, 28).padding(.top, 60).padding(.bottom, 32)

                    if step == .email {
                        emailStep
                    } else {
                        otpStep
                    }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: auth.errorMessage)
            .animation(.easeInOut(duration: 0.25), value: step)
        }
    }

    // MARK: - Step 1: Email + Apple

    private var emailStep: some View {
        VStack(spacing: 0) {
            // Apple Sign In
            Button {
                _Concurrency.Task {
                    await auth.signInWithApple()
                    if auth.state == .authenticated { await finishAuth() }
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "apple.logo").font(.system(size: 18, weight: .semibold))
                    Text(isNewUser ? "Continue with Apple" : "Sign in with Apple")
                        .font(AvaTheme.font(16, weight: .bold))
                }
                .foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(RoundedRectangle(cornerRadius: 14).fill(AvaTheme.ink))
            }
            .buttonStyle(.plain).padding(.horizontal, 28)

            // Divider
            HStack(spacing: 12) {
                Rectangle().fill(AvaTheme.line).frame(height: 1)
                Text("or email").font(AvaTheme.font(13, weight: .medium)).foregroundStyle(AvaTheme.inkSoft)
                Rectangle().fill(AvaTheme.line).frame(height: 1)
            }
            .padding(.horizontal, 28).padding(.vertical, 20)

            // Email field
            HStack(spacing: 12) {
                Image(systemName: "envelope").font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AvaTheme.inkSoft).frame(width: 20)
                TextField("your@email.com", text: $email)
                    .font(AvaTheme.font(15, weight: .medium)).foregroundStyle(AvaTheme.ink)
                    .keyboardType(.emailAddress).textContentType(.emailAddress)
                    .autocorrectionDisabled().textInputAutocapitalization(.never)
                    .focused($emailFocused).submitLabel(usePassword ? .next : .done)
                    .onSubmit { if usePassword { passwordFocused = true } else if emailValid { sendCode() } }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 14).fill(AvaTheme.cream))
            .padding(.horizontal, 28)

            // Password field (when toggled)
            if usePassword {
                HStack(spacing: 12) {
                    Image(systemName: "lock").font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AvaTheme.inkSoft).frame(width: 20)
                    SecureField("Password", text: $password)
                        .font(AvaTheme.font(15, weight: .medium)).foregroundStyle(AvaTheme.ink)
                        .textContentType(.password)
                        .focused($passwordFocused).submitLabel(.done)
                        .onSubmit { if emailValid && passwordValid { signInWithPassword() } }
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 14).fill(AvaTheme.cream))
                .padding(.horizontal, 28)
                .padding(.top, 10)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Error
            if let err = auth.errorMessage {
                errorBanner(err).padding(.horizontal, 28).padding(.top, 12)
            }

            // Primary action button
            Button(action: usePassword ? signInWithPassword : sendCode) {
                ZStack {
                    Text(usePassword ? "Sign in →" : "Send code →")
                        .font(AvaTheme.font(16, weight: .heavy)).foregroundStyle(.white)
                        .opacity(auth.isLoading ? 0 : 1)
                    if auth.isLoading { ProgressView().tint(.white) }
                }
                .frame(maxWidth: .infinity).padding(.vertical, 18)
                .background(Capsule().fill((usePassword ? (emailValid && passwordValid) : emailValid)
                    ? AnyShapeStyle(AvaTheme.blushTerracotta)
                    : AnyShapeStyle(AvaTheme.line)))
                .animation(.easeInOut(duration: 0.2), value: emailValid)
            }
            .buttonStyle(.plain)
            .disabled((usePassword ? !(emailValid && passwordValid) : !emailValid) || auth.isLoading)
            .padding(.horizontal, 28).padding(.top, 20)

            // Toggle between OTP and password
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    usePassword.toggle()
                    password = ""
                    auth.errorMessage = nil
                }
            } label: {
                Text(usePassword ? "Send me a code instead" : "Sign in with password instead")
                    .font(AvaTheme.font(14, weight: .semibold))
                    .foregroundStyle(AvaTheme.terracotta)
            }
            .buttonStyle(.plain).padding(.top, 14).padding(.bottom, 50)
            .frame(maxWidth: .infinity)
        }
        .onAppear { emailFocused = true }
    }

    // MARK: - Step 2: OTP entry

    private var otpStep: some View {
        VStack(spacing: 0) {
            // 6-digit code input
            HStack(spacing: 12) {
                Image(systemName: "number").font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AvaTheme.inkSoft).frame(width: 20)
                TextField("123456", text: $otp)
                    .font(AvaTheme.font(22, weight: .heavy)).foregroundStyle(AvaTheme.ink)
                    .keyboardType(.numberPad).textContentType(.oneTimeCode)
                    .focused($otpFocused)
                    .onChange(of: otp) { _, val in
                        // Keep only digits, max 6
                        otp = String(val.filter { $0.isNumber }.prefix(6))
                        if otp.count == 6 { verifyOTP() }
                    }
                    .tracking(8)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 14).fill(AvaTheme.cream))
            .padding(.horizontal, 28)

            // Error
            if let err = auth.errorMessage {
                errorBanner(err).padding(.horizontal, 28).padding(.top, 12)
            }

            // Verify button
            Button(action: verifyOTP) {
                ZStack {
                    Text("Verify →")
                        .font(AvaTheme.font(16, weight: .heavy)).foregroundStyle(.white)
                        .opacity(auth.isLoading ? 0 : 1)
                    if auth.isLoading { ProgressView().tint(.white) }
                }
                .frame(maxWidth: .infinity).padding(.vertical, 18)
                .background(Capsule().fill(otpValid
                    ? AnyShapeStyle(AvaTheme.blushTerracotta)
                    : AnyShapeStyle(AvaTheme.line)))
                .animation(.easeInOut(duration: 0.2), value: otpValid)
            }
            .buttonStyle(.plain).disabled(!otpValid || auth.isLoading)
            .padding(.horizontal, 28).padding(.top, 20)

            // Resend code
            Button { sendCode() } label: {
                Text("Resend code")
                    .font(AvaTheme.font(14, weight: .semibold))
                    .foregroundStyle(AvaTheme.terracotta)
            }
            .buttonStyle(.plain).padding(.top, 16).padding(.bottom, 50)
            .frame(maxWidth: .infinity)
        }
        .onAppear { otpFocused = true }
    }

    // MARK: - Actions

    private func signInWithPassword() {
        guard emailValid && passwordValid else { return }
        _Concurrency.Task {
            await auth.signInWithPassword(email: email, password: password)
            if auth.state == .authenticated { await finishAuth() }
        }
    }

    private func sendCode() {
        guard emailValid else { return }
        _Concurrency.Task {
            await auth.sendOTP(email: email)
            if auth.errorMessage == nil {
                withAnimation { step = .otp }
            }
        }
    }

    private func verifyOTP() {
        guard otpValid else { return }
        _Concurrency.Task {
            await auth.verifyOTP(email: email, token: otp)
            if auth.state == .authenticated { await finishAuth() }
        }
    }

    private func finishAuth() async {
        if let data = onboardingData { await auth.saveOnboardingData(data) }
        onComplete()
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.circle.fill")
            Text(message)
        }
        .font(AvaTheme.font(13, weight: .medium))
        .foregroundStyle(Color(hex: "C0392B"))
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

#Preview {
    AuthView(onboardingData: nil, onComplete: {}).environment(AuthManager())
}
