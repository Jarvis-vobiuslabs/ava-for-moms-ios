import SwiftUI

struct SettingsView: View {

    var body: some View {
        ZStack {
            AvaTheme.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // ── Header ────────────────────────────────────────────
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Settings")
                            .font(AvaTheme.font(13, weight: .bold))
                            .foregroundStyle(AvaTheme.inkMute)
                        Text("You & Ava")
                            .font(AvaTheme.font(28, weight: .heavy))
                            .foregroundStyle(AvaTheme.ink)
                            .tracking(-0.6)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 60)
                    .padding(.bottom, 14)

                    // ── Profile hero ──────────────────────────────────────
                    HStack(spacing: 14) {
                        Circle()
                            .fill(.white.opacity(0.25))
                            .frame(width: 58, height: 58)
                            .overlay(
                                Text("C")
                                    .font(AvaTheme.font(24, weight: .heavy))
                                    .foregroundStyle(.white)
                            )
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Claire Harding")
                                .font(AvaTheme.font(18, weight: .heavy))
                                .foregroundStyle(.white)
                            Text("Ava has learned you for 47 days 💛")
                                .font(AvaTheme.font(12.5, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        Spacer()
                    }
                    .padding(20)
                    .background(AvaTheme.blushTerracotta)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .padding(.horizontal, 18)
                    .padding(.bottom, 20)

                    // ── Your Ava ──────────────────────────────────────────
                    settingsSectionHeader("YOUR AVA")

                    settingsGroup([
                        SettingsRow(emoji: "💛", title: "Personality",
                                    detail: "Warm · playful · honest"),
                        SettingsRow(emoji: "🧠", title: "Memory",
                                    detail: "142 things Ava remembers"),
                        SettingsRow(emoji: "☀️", title: "Check-ins",
                                    detail: "Morning 7 · Evening 9"),
                        SettingsRow(emoji: "👨‍👩‍👧‍👦", title: "Family",
                                    detail: "3 people connected"),
                    ])

                    // ── Private & Safe ────────────────────────────────────
                    settingsSectionHeader("PRIVATE & SAFE")

                    settingsGroup([
                        SettingsRow(emoji: "🔒", title: "On-device encryption",
                                    detail: "Nothing shared without permission"),
                        SettingsRow(emoji: "🫧", title: "Forget something",
                                    detail: "Tell Ava what to drop"),
                        SettingsRow(emoji: "📦", title: "Export your data",
                                    detail: nil),
                    ])

                    // ── Privacy note ──────────────────────────────────────
                    HStack(spacing: 6) {
                        Text("🌿 **Private by design.** Your Ava lives on your phone.")
                            .font(AvaTheme.font(13.5, weight: .medium))
                            .foregroundStyle(AvaTheme.ink)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 20).fill(AvaTheme.sage.opacity(0.2)))
                    .padding(.horizontal, 18)
                    .padding(.top, 18)

                    Spacer().frame(height: 130)
                }
            }
        }
    }

    // ── Helpers ──────────────────────────────────────────────────────────

    private func settingsSectionHeader(_ text: String) -> some View {
        Text(text)
            .font(AvaTheme.font(12, weight: .heavy))
            .foregroundStyle(AvaTheme.inkMute)
            .tracking(0.3)
            .padding(.horizontal, 24)
            .padding(.top, 4)
            .padding(.bottom, 8)
    }

    private func settingsGroup(_ rows: [SettingsRow]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { idx, row in
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(AvaTheme.bgDeep)
                            .frame(width: 36, height: 36)
                        Text(row.emoji).font(.system(size: 16))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.title)
                            .font(AvaTheme.font(14.5, weight: .bold))
                            .foregroundStyle(AvaTheme.ink)
                        if let detail = row.detail {
                            Text(detail)
                                .font(AvaTheme.font(12, weight: .medium))
                                .foregroundStyle(AvaTheme.inkMute)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AvaTheme.inkSoft)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(AvaTheme.cream)

                if idx < rows.count - 1 {
                    Divider().padding(.leading, 64).tint(AvaTheme.line)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .padding(.horizontal, 18)
        .padding(.bottom, 8)
    }

    private struct SettingsRow {
        let emoji: String
        let title: String
        let detail: String?
    }
}

#Preview {
    SettingsView()
}
