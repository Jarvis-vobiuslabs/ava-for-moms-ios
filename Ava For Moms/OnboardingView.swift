import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            AvaTheme.bg.ignoresSafeArea()

            // Background blobs
            GeometryReader { geo in
                Circle()
                    .fill(AvaTheme.blush.opacity(0.3))
                    .frame(width: 220, height: 220)
                    .offset(x: geo.size.width - 80, y: -60)
                Circle()
                    .fill(AvaTheme.sage.opacity(0.25))
                    .frame(width: 200, height: 200)
                    .offset(x: -60, y: geo.size.height * 0.75)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Orb
                ZStack {
                    Circle()
                        .fill(AvaTheme.sage.opacity(0.4))
                        .frame(width: 40, height: 40)
                        .offset(x: -85, y: 20)
                    Circle()
                        .fill(AvaTheme.blush.opacity(0.7))
                        .frame(width: 24, height: 24)
                        .offset(x: 90, y: 65)

                    Circle()
                        .fill(AvaTheme.blushTerracotta)
                        .frame(width: 170, height: 170)
                        .shadow(color: AvaTheme.terracotta.opacity(0.4), radius: 30, x: 0, y: 20)
                        .overlay(orbFace)
                }
                .frame(height: 200)

                Spacer().frame(height: 50)

                Text("Meet Ava")
                    .font(AvaTheme.font(38, weight: .heavy))
                    .foregroundStyle(AvaTheme.ink)
                    .tracking(-1)

                Spacer().frame(height: 16)

                Text("Your own AI mom-friend.\nHolds the mental load so you don't have to.")
                    .font(AvaTheme.font(16, weight: .medium))
                    .foregroundStyle(AvaTheme.inkMute)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)

                Spacer()

                // Feature chips
                VStack(spacing: 10) {
                    featureChip(emoji: "🧠", text: "Learns your family & routines")
                    featureChip(emoji: "🔒", text: "Stays on your phone — private")
                    featureChip(emoji: "💛", text: "Nudges, never nags")
                }
                .padding(.horizontal, 30)

                Spacer().frame(height: 20)

                // Get started
                Button(action: onComplete) {
                    Text("Get started →")
                        .font(AvaTheme.font(16, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(AvaTheme.blushTerracotta)
                        .clipShape(Capsule())
                        .shadow(color: AvaTheme.terracotta.opacity(0.4), radius: 12, x: 0, y: 8)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 30)

                Button(action: {}) {
                    Text("Sign in")
                        .font(AvaTheme.font(13, weight: .bold))
                        .foregroundStyle(AvaTheme.inkMute)
                }
                .padding(.top, 12)
                .padding(.bottom, 50)
            }
        }
    }

    private func featureChip(emoji: String, text: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(AvaTheme.bgDeep)
                    .frame(width: 36, height: 36)
                Text(emoji).font(.system(size: 18))
            }
            Text(text)
                .font(AvaTheme.font(14, weight: .bold))
                .foregroundStyle(AvaTheme.ink)
            Spacer()
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18).fill(AvaTheme.cream))
    }

    private var orbFace: some View {
        VStack(spacing: 14) {
            HStack(spacing: 20) {
                Circle().fill(.white).frame(width: 12, height: 12)
                Circle().fill(.white).frame(width: 12, height: 12)
            }
            Canvas { ctx, size in
                var path = Path()
                path.move(to: CGPoint(x: 0, y: 0))
                path.addQuadCurve(
                    to: CGPoint(x: size.width, y: 0),
                    control: CGPoint(x: size.width / 2, y: size.height)
                )
                ctx.stroke(path, with: .color(.white),
                           style: StrokeStyle(lineWidth: 4, lineCap: .round))
            }
            .frame(width: 52, height: 18)
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
