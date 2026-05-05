import SwiftUI

struct HomeView: View {
    let onChatTap: () -> Void

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            AvaTheme.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // ── Header ──────────────────────────────────────────
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Hey Claire 👋")
                                .font(AvaTheme.font(30, weight: .heavy))
                                .foregroundStyle(AvaTheme.ink)
                                .tracking(-0.8)
                            Text("Tuesday, April 22")
                                .font(AvaTheme.font(14, weight: .medium))
                                .foregroundStyle(AvaTheme.inkMute)
                        }
                        Spacer()
                        Circle()
                            .fill(AvaTheme.blushSage)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text("C")
                                    .font(AvaTheme.font(15, weight: .heavy))
                                    .foregroundStyle(.white)
                            )
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 60)
                    .padding(.bottom, 16)

                    // ── Ava's Take card ──────────────────────────────────
                    ZStack(alignment: .topTrailing) {
                        Circle()
                            .fill(.white.opacity(0.12))
                            .frame(width: 140, height: 140)
                            .offset(x: 20, y: -30)
                        Circle()
                            .fill(.white.opacity(0.08))
                            .frame(width: 90, height: 90)
                            .offset(x: -10, y: 70)

                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                ZStack {
                                    Circle().fill(.white.opacity(0.25)).frame(width: 24, height: 24)
                                    Circle().fill(.white).frame(width: 10, height: 10)
                                }
                                Text("AVA'S TAKE")
                                    .font(AvaTheme.font(12, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.9))
                                    .tracking(0.3)
                            }
                            Text("You've got a full morning — Mia's dentist at 10:30 and soccer pickup at 4. Want me to handle dinner prep?")
                                .font(AvaTheme.font(17, weight: .semibold))
                                .foregroundStyle(.white)
                                .lineSpacing(3)
                            HStack(spacing: 8) {
                                Button(action: onChatTap) {
                                    Text("Yes please")
                                        .font(AvaTheme.font(13, weight: .bold))
                                        .foregroundStyle(AvaTheme.terracottaDeep)
                                        .padding(.horizontal, 16).padding(.vertical, 9)
                                        .background(.white)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                                Button(action: {}) {
                                    Text("Later")
                                        .font(AvaTheme.font(13, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 16).padding(.vertical, 9)
                                        .overlay(Capsule().stroke(.white.opacity(0.6), lineWidth: 1.5))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(22)
                    }
                    .background(AvaTheme.blushTerracotta)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .padding(.horizontal, 18)

                    // ── Quick tiles ──────────────────────────────────────
                    HStack(spacing: 10) {
                        quickTile(
                            color: AvaTheme.sage,
                            symbol: "checkmark",
                            label: "TASKS",
                            bigText: "3",
                            subText: " / 7",
                            caption: "checked off"
                        )
                        nextUpTile
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 10)

                    // ── Today timeline ───────────────────────────────────
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text("Today")
                                .font(AvaTheme.font(17, weight: .heavy))
                                .foregroundStyle(AvaTheme.ink)
                            Spacer()
                            Text("5 things")
                                .font(AvaTheme.font(12, weight: .bold))
                                .foregroundStyle(AvaTheme.terracotta)
                        }
                        .padding(.bottom, 12)

                        ForEach(todayEvents) { event in
                            HStack(spacing: 12) {
                                Text(event.time)
                                    .font(AvaTheme.font(13, weight: .bold))
                                    .foregroundStyle(event.done ? AvaTheme.inkSoft : AvaTheme.inkMute)
                                    .strikethrough(event.done, color: AvaTheme.inkSoft)
                                    .frame(width: 48, alignment: .leading)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(event.color)
                                    .frame(width: 4, height: 30)
                                    .opacity(event.done ? 0.35 : 1)
                                Text(event.title)
                                    .font(AvaTheme.font(14.5, weight: .semibold))
                                    .foregroundStyle(event.done ? AvaTheme.inkSoft : AvaTheme.ink)
                                    .strikethrough(event.done, color: AvaTheme.inkSoft)
                            }
                            .padding(.vertical, 10)
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 22)

                    Spacer().frame(height: 130)
                }
            }

            // ── Ava FAB ────────────────────────────────────────────────
            Button(action: onChatTap) {
                Circle()
                    .fill(AvaTheme.blushTerracotta)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: "face.smiling")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                    )
                    .shadow(color: AvaTheme.terracotta.opacity(0.4), radius: 12, x: 0, y: 8)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 18)
            .padding(.bottom, 100)
        }
    }

    // ── Sub-views ────────────────────────────────────────────────────────

    private func quickTile(color: Color, symbol: String, label: String,
                           bigText: String, subText: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle().fill(color).frame(width: 28, height: 28)
                    .overlay(Image(systemName: symbol)
                        .font(.system(size: 12, weight: .bold)).foregroundStyle(.white))
                Text(label)
                    .font(AvaTheme.font(11, weight: .bold))
                    .foregroundStyle(AvaTheme.inkMute)
                    .tracking(0.2)
            }
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(bigText).font(AvaTheme.font(26, weight: .heavy)).foregroundStyle(AvaTheme.ink)
                Text(subText).font(AvaTheme.font(15, weight: .semibold)).foregroundStyle(AvaTheme.inkSoft)
            }
            Text(caption).font(AvaTheme.font(11.5, weight: .semibold)).foregroundStyle(AvaTheme.inkMute)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 22).fill(AvaTheme.cream))
    }

    private var nextUpTile: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle().fill(AvaTheme.blush).frame(width: 28, height: 28)
                    .overlay(Image(systemName: "calendar")
                        .font(.system(size: 12, weight: .bold)).foregroundStyle(.white))
                Text("NEXT UP")
                    .font(AvaTheme.font(11, weight: .bold))
                    .foregroundStyle(AvaTheme.inkMute)
                    .tracking(0.2)
            }
            Text("Mia — dentist")
                .font(AvaTheme.font(18, weight: .heavy))
                .foregroundStyle(AvaTheme.ink)
                .lineLimit(2)
            Text("10:30 · in 2 hrs")
                .font(AvaTheme.font(11.5, weight: .semibold))
                .foregroundStyle(AvaTheme.inkMute)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 22).fill(AvaTheme.cream))
    }

    // ── Data ────────────────────────────────────────────────────────────

    private struct TodayEvent: Identifiable {
        let id = UUID()
        let time: String
        let title: String
        let color: Color
        let done: Bool
    }

    private let todayEvents: [TodayEvent] = [
        TodayEvent(time: "8:00",  title: "School drop · Theo",  color: Color(hex: "A5C09A"), done: true),
        TodayEvent(time: "10:30", title: "Mia · Dentist",        color: Color(hex: "D46A47"), done: false),
        TodayEvent(time: "2:00",  title: "Grocery pickup",       color: Color(hex: "7A9A6E"), done: false),
        TodayEvent(time: "4:00",  title: "Theo · Soccer",        color: Color(hex: "E88D74"), done: false),
        TodayEvent(time: "6:30",  title: "Family dinner",        color: Color(hex: "B04A2A"), done: false),
    ]
}

#Preview {
    HomeView(onChatTap: {})
}
