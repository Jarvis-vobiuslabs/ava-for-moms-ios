import SwiftUI

struct OnboardingPrivacyView: View {
    var data: OnboardingData
    let onNext: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            backButton.frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            // Orb — same visual as welcome but smaller
            Circle()
                .fill(AvaTheme.blushTerracotta)
                .frame(width: 120, height: 120)
                .overlay(orbFace)
                .shadow(color: AvaTheme.terracotta.opacity(0.35), radius: 24, x: 0, y: 14)
                .padding(.bottom, 36)

            // Personalised headline
            VStack(spacing: 12) {
                Text("Okay, \(data.name.isEmpty ? "you" : data.name).")
                    .font(AvaTheme.font(38, weight: .heavy))
                    .foregroundStyle(AvaTheme.ink)
                    .tracking(-1)

                Text("I know about your \(data.familySummary), your week, and what matters most.\nI'm ready.")
                    .font(AvaTheme.font(17, weight: .medium))
                    .foregroundStyle(AvaTheme.inkMute)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 30)
            }

            Spacer()

            // Trust promises
            VStack(spacing: 10) {
                promiseRow(emoji: "🔒", title: "Everything stays on your phone",
                           detail: "End-to-end encrypted. Ava runs on-device.")
                promiseRow(emoji: "🚫", title: "Nothing shared without you",
                           detail: "No ads. No selling your data. Ever.")
                promiseRow(emoji: "🗑️", title: "Delete anytime",
                           detail: "Your data is yours. Export or wipe in one tap.")
            }
            .padding(.horizontal, 22)

            Spacer()

            Button(action: onNext) {
                Text("Let's do this →")
                    .font(AvaTheme.font(16, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Capsule().fill(AvaTheme.blushTerracotta))
                    .shadow(color: AvaTheme.terracotta.opacity(0.35), radius: 10, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 28)
            .padding(.bottom, 50)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Sub-views

    private func promiseRow(emoji: String, title: String, detail: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(AvaTheme.bgDeep)
                    .frame(width: 44, height: 44)
                Text(emoji).font(.system(size: 20))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AvaTheme.font(14, weight: .bold))
                    .foregroundStyle(AvaTheme.ink)
                Text(detail)
                    .font(AvaTheme.font(12, weight: .medium))
                    .foregroundStyle(AvaTheme.inkMute)
            }
            Spacer()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18).fill(AvaTheme.cream))
    }

    private var orbFace: some View {
        VStack(spacing: 10) {
            HStack(spacing: 14) {
                Circle().fill(.white).frame(width: 9, height: 9)
                Circle().fill(.white).frame(width: 9, height: 9)
            }
            Canvas { ctx, size in
                var path = Path()
                path.move(to: CGPoint(x: 0, y: 0))
                path.addQuadCurve(
                    to: CGPoint(x: size.width, y: 0),
                    control: CGPoint(x: size.width / 2, y: size.height)
                )
                ctx.stroke(path, with: .color(.white),
                           style: StrokeStyle(lineWidth: 3, lineCap: .round))
            }
            .frame(width: 38, height: 14)
        }
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
    let d = OnboardingData()
    d.name = "Claire"; d.hasPartner = true; d.kids = [.init()]
    d.mentalLoadAreas = [.meals, .school]
    return OnboardingPrivacyView(data: d, onNext: {}, onBack: {})
}
