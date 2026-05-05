import SwiftUI

struct OnboardingNameView: View {
    @Bindable var data: OnboardingData
    let onNext: () -> Void
    let onBack: () -> Void

    @FocusState private var focused: Bool
    private var canContinue: Bool { data.name.trimmingCharacters(in: .whitespaces).count >= 2 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            backButton

            VStack(alignment: .leading, spacing: 14) {
                Text("What should\nAva call you?")
                    .font(AvaTheme.font(34, weight: .heavy))
                    .foregroundStyle(AvaTheme.ink)
                    .tracking(-1)
                    .lineSpacing(2)

                Text("Just your first name — she'll use it every single day.")
                    .font(AvaTheme.font(16, weight: .medium))
                    .foregroundStyle(AvaTheme.inkMute)
                    .lineSpacing(3)
            }
            .padding(.horizontal, 28)
            .padding(.top, 36)

            // Name field
            VStack(alignment: .leading, spacing: 10) {
                TextField("Claire", text: $data.name)
                    .font(AvaTheme.font(36, weight: .heavy))
                    .foregroundStyle(AvaTheme.ink)
                    .focused($focused)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .onSubmit { if canContinue { onNext() } }

                Rectangle()
                    .fill(canContinue ? AvaTheme.terracotta : AvaTheme.line)
                    .frame(height: 2)
                    .animation(.easeInOut(duration: 0.2), value: canContinue)
            }
            .padding(.horizontal, 28)
            .padding(.top, 52)

            Spacer()

            continueButton
                .padding(.horizontal, 28)
                .padding(.bottom, 50)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .onAppear { focused = true }
    }

    private var backButton: some View {
        Button(action: onBack) {
            HStack(spacing: 6) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                Text("Back")
                    .font(AvaTheme.font(15, weight: .semibold))
            }
            .foregroundStyle(AvaTheme.inkMute)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }

    private var continueButton: some View {
        Button(action: onNext) {
            Text("Continue →")
                .font(AvaTheme.font(16, weight: .heavy))
                .foregroundStyle(canContinue ? .white : AvaTheme.inkSoft)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    Capsule().fill(canContinue ? AvaTheme.blushTerracotta : AvaTheme.line)
                )
                .animation(.easeInOut(duration: 0.2), value: canContinue)
        }
        .buttonStyle(.plain)
        .disabled(!canContinue)
    }
}

#Preview {
    let d = OnboardingData(); d.name = "Claire"
    return OnboardingNameView(data: d, onNext: {}, onBack: {})
}
