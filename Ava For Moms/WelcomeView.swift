import SwiftUI

// One-time "how to use Ava" screen, shown right after onboarding completes.

struct WelcomeView: View {
    @Environment(AuthManager.self) private var auth
    let onStartChat: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            AvaTheme.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // ── Header ─────────────────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        Circle()
                            .fill(AvaTheme.blushTerracotta)
                            .frame(width: 64, height: 64)
                            .overlay(
                                Image(systemName: "face.smiling")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(.white)
                            )
                        Text("You're all set, \(auth.firstName)!")
                            .font(AvaTheme.font(28, weight: .heavy))
                            .foregroundStyle(AvaTheme.ink)
                            .tracking(-0.6)
                        Text("Ava works best when you just talk to her like a friend. Here's what she can do from day one:")
                            .font(AvaTheme.font(15, weight: .medium))
                            .foregroundStyle(AvaTheme.inkMute)
                            .lineSpacing(3)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 70)
                    .padding(.bottom, 24)

                    // ── Tips ───────────────────────────────────────────
                    VStack(spacing: 12) {
                        tip("🎂", "Never miss a birthday",
                            "Tell her all the birthdays you need to remember this year — she'll add them to your calendar and remind you when they're coming up.")
                        tip("⏰", "Reminders, your way",
                            "\"Remind me about school pickup at 3\" — or no time at all, she'll figure it out.")
                        tip("🛒", "Grocery list by chat",
                            "\"Add milk, eggs and snacks for Mia\" goes straight onto your list.")
                        tip("🔑", "A safe place for the little things",
                            "WiFi passwords, locker codes, where you hid the presents — she'll note it and never forget.")
                    }
                    .padding(.horizontal, 18)

                    // ── CTAs ───────────────────────────────────────────
                    VStack(spacing: 12) {
                        Button(action: onStartChat) {
                            Text("Say hi to Ava")
                                .font(AvaTheme.font(16, weight: .heavy))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Capsule().fill(AvaTheme.blushTerracotta))
                        }
                        .contentShape(Rectangle())
                        .buttonStyle(.plain)

                        Button(action: onDismiss) {
                            Text("I'll explore first")
                                .font(AvaTheme.font(14, weight: .semibold))
                                .foregroundStyle(AvaTheme.inkMute)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        }
                        .contentShape(Rectangle())
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 26)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    private func tip(_ emoji: String, _ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AvaTheme.bgDeep)
                    .frame(width: 44, height: 44)
                Text(emoji).font(.system(size: 20))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(AvaTheme.font(15, weight: .heavy))
                    .foregroundStyle(AvaTheme.ink)
                Text(body)
                    .font(AvaTheme.font(13, weight: .medium))
                    .foregroundStyle(AvaTheme.inkMute)
                    .lineSpacing(2)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20).fill(AvaTheme.cream))
    }
}

#Preview {
    WelcomeView(onStartChat: {}, onDismiss: {})
        .environment(AuthManager())
}
