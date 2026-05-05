import SwiftUI

struct OnboardingFlowView: View {
    let onComplete: () -> Void

    @State private var step = 0
    @State private var data = OnboardingData()
    @State private var goingForward = true

    private let totalSteps = 5   // steps 1–5 show progress bar

    var body: some View {
        ZStack(alignment: .top) {
            AvaTheme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar — only visible on steps 1–5
                if step > 0 && step <= totalSteps {
                    progressBar
                        .padding(.top, 58)
                        .padding(.horizontal, 28)
                        .padding(.bottom, 6)
                        .transition(.opacity)
                }

                // Step content
                currentStep
                    .id(step)
                    .transition(pageTransition)
                    .animation(.easeInOut(duration: 0.28), value: step)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: step > 0 && step <= totalSteps)
    }

    // MARK: - Step router

    @ViewBuilder
    private var currentStep: some View {
        switch step {
        case 0:
            OnboardingView(onComplete: advance)
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
        default:
            PaywallView(data: data, onComplete: onComplete)
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
    OnboardingFlowView(onComplete: {})
}
