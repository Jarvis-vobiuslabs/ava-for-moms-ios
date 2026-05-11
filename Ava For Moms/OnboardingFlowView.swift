import SwiftUI

struct OnboardingFlowView: View {
    @State private var step = 0
    @State private var data = OnboardingData()
    @State private var goingForward = true
    @State private var showSignIn = false   // "I already have an account" sheet

    private let totalSteps = 5  // progress bar covers steps 1–5

    var body: some View {
        ZStack(alignment: .top) {
            AvaTheme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                if step > 0 && step <= totalSteps {
                    progressBar
                        .padding(.top, 58)
                        .padding(.horizontal, 28)
                        .padding(.bottom, 6)
                        .transition(.opacity)
                }

                currentStep
                    .id(step)
                    .transition(pageTransition)
                    .animation(.easeInOut(duration: 0.28), value: step)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: step > 0 && step <= totalSteps)
        // Returning user sheet — environmentObject propagates automatically into sheets
        .sheet(isPresented: $showSignIn) {
            AuthView(onboardingData: nil, onComplete: { showSignIn = false })
        }
    }

    // MARK: - Step router

    @ViewBuilder
    private var currentStep: some View {
        switch step {
        case 0:
            OnboardingView(
                onComplete: advance,
                onSignIn: { showSignIn = true }
            )
        case 1:
            OnboardingNameView(data: data, onNext: advance, onBack: back)
        case 2:
            OnboardingFamilyView(data: data, onNext: advance, onBack: back)
        case 3:
            OnboardingWeekView(data: data, onNext: advance, onBack: back)
        case 4:
            OnboardingLoadView(data: data, onNext: advance, onBack: back)
        case 5:
            OnboardingPrivacyView(data: data, onNext: advance, onBack: back)
        case 6:
            // Paywall — onComplete advances to auth step
            PaywallView(data: data, onComplete: advance)
        default:
            // Step 7 — create account, save onboarding data, enter app
            // Auth state change automatically triggers ContentView to show MainTabView
            AuthView(onboardingData: data, onComplete: {})
        }
    }

    // MARK: - Progress bar

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(1...totalSteps, id: \.self) { i in
                Capsule()
                    .fill(step >= i ? AvaTheme.terracotta : AvaTheme.line)
                    .frame(height: 4)
                    .animation(.spring(duration: 0.3), value: step)
            }
        }
    }

    // MARK: - Navigation

    private func advance() {
        goingForward = true
        withAnimation(.easeInOut(duration: 0.28)) { step += 1 }
    }

    private func back() {
        goingForward = false
        withAnimation(.easeInOut(duration: 0.28)) { step -= 1 }
    }

    private var pageTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: goingForward ? .trailing : .leading),
            removal:   .move(edge: goingForward ? .leading  : .trailing)
        )
    }
}

#Preview {
    OnboardingFlowView()
        .environmentObject(AuthManager())
}
