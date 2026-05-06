import SwiftUI

struct OnboardingLoadView: View {
    @Bindable var data: OnboardingData
    let onNext: () -> Void
    let onBack: () -> Void

    private var canContinue: Bool { !data.mentalLoadAreas.isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            backButton

            VStack(alignment: .leading, spacing: 14) {
                Text("What's weighing\non you most?")
                    .font(AvaTheme.font(34, weight: .heavy))
                    .foregroundStyle(AvaTheme.ink)
                    .tracking(-1)
                    .lineSpacing(2)

                Text("Select everything that applies — Ava will focus there first.")
                    .font(AvaTheme.font(16, weight: .medium))
                    .foregroundStyle(AvaTheme.inkMute)
                    .lineSpacing(3)
            }
            .padding(.horizontal, 28)
            .padding(.top, 36)

            // Grid
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 10
            ) {
                ForEach(OnboardingData.MentalLoad.allCases, id: \.self) { load in
                    loadCard(load)
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 28)

            Spacer()

            Button(action: onNext) {
                Text(canContinue ? "Continue →" : "Select at least one")
                    .font(AvaTheme.font(16, weight: .heavy))
                    .foregroundStyle(canContinue ? .white : AvaTheme.inkSoft)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        Capsule().fill(canContinue ? AnyShapeStyle(AvaTheme.blushTerracotta) : AnyShapeStyle(AvaTheme.line))
                    )
                    .animation(.easeInOut(duration: 0.2), value: canContinue)
            }
            .buttonStyle(.plain)
            .disabled(!canContinue)
            .padding(.horizontal, 28)
            .padding(.bottom, 50)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private func loadCard(_ load: OnboardingData.MentalLoad) -> some View {
        let selected = data.mentalLoadAreas.contains(load)
        return Button {
            withAnimation(.spring(duration: 0.2)) {
                if selected { data.mentalLoadAreas.remove(load) }
                else        { data.mentalLoadAreas.insert(load) }
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(load.emoji).font(.system(size: 26))
                    Spacer()
                    if selected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                Text(load.rawValue)
                    .font(AvaTheme.font(14, weight: .bold))
                    .foregroundStyle(selected ? .white : AvaTheme.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 90, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(selected ? AvaTheme.terracotta : AvaTheme.cream)
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.2), value: selected)
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
}

#Preview {
    OnboardingLoadView(data: OnboardingData(), onNext: {}, onBack: {})
}
