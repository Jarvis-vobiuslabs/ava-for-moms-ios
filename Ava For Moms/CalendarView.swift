import SwiftUI

struct CalendarView: View {
    let onChatTap: () -> Void
    @State private var selectedDay = 22

    private let weekDays = ["M","T","W","T","F","S","S"]
    private let weekNums = [21,22,23,24,25,26,27]

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            AvaTheme.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // ── Header ────────────────────────────────────────────
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("April 2026")
                                .font(AvaTheme.font(13, weight: .bold))
                                .foregroundStyle(AvaTheme.inkMute)
                            Text("This week")
                                .font(AvaTheme.font(28, weight: .heavy))
                                .foregroundStyle(AvaTheme.ink)
                                .tracking(-0.6)
                        }
                        Spacer()
                        Button(action: {}) {
                            Circle()
                                .fill(AvaTheme.blushTerracotta)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Image(systemName: "plus")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(.white)
                                )
                                .shadow(color: AvaTheme.terracotta.opacity(0.4), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 60)
                    .padding(.bottom, 18)

                    // ── Week pill strip ───────────────────────────────────
                    HStack(spacing: 4) {
                        ForEach(0..<7) { i in
                            Button { selectedDay = weekNums[i] } label: {
                                VStack(spacing: 2) {
                                    Text(weekDays[i])
                                        .font(AvaTheme.font(10, weight: .bold))
                                        .opacity(0.8)
                                    Text("\(weekNums[i])")
                                        .font(AvaTheme.font(16, weight: .heavy))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .foregroundStyle(selectedDay == weekNums[i] ? .white : AvaTheme.ink)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(selectedDay == weekNums[i] ? AvaTheme.terracotta : Color.clear)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(6)
                    .background(RoundedRectangle(cornerRadius: 22).fill(AvaTheme.cream))
                    .padding(.horizontal, 22)

                    // ── People legend ─────────────────────────────────────
                    HStack(spacing: 6) {
                        ForEach(familyMembers, id: \.name) { p in
                            HStack(spacing: 6) {
                                Circle().fill(p.color).frame(width: 8, height: 8)
                                Text(p.name)
                                    .font(AvaTheme.font(11.5, weight: .bold))
                                    .foregroundStyle(AvaTheme.ink)
                            }
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(RoundedRectangle(cornerRadius: 14).fill(AvaTheme.cream))
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 14)

                    // ── Events ────────────────────────────────────────────
                    VStack(spacing: 10) {
                        ForEach(calEvents) { event in
                            HStack(spacing: 12) {
                                Text(event.time)
                                    .font(AvaTheme.font(12, weight: .bold))
                                    .foregroundStyle(AvaTheme.inkMute)
                                    .frame(width: 66, alignment: .leading)
                                    .padding(.top, 14)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(event.title)
                                        .font(AvaTheme.font(15, weight: .heavy))
                                        .foregroundStyle(AvaTheme.ink)
                                        .strikethrough(event.done, color: AvaTheme.inkSoft)
                                    Text(event.detail)
                                        .font(AvaTheme.font(12, weight: .semibold))
                                        .foregroundStyle(AvaTheme.inkMute)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(AvaTheme.cream)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(event.color)
                                        .frame(width: 5)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .clipShape(
                                            UnevenRoundedRectangle(
                                                topLeadingRadius: 18,
                                                bottomLeadingRadius: 18,
                                                bottomTrailingRadius: 0,
                                                topTrailingRadius: 0
                                            )
                                        )
                                )
                                .opacity(event.done ? 0.5 : 1)
                            }
                        }

                        // Ava nudge
                        HStack(spacing: 10) {
                            Circle()
                                .fill(AvaTheme.blushTerracotta)
                                .frame(width: 28, height: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Heads up —")
                                    .font(AvaTheme.font(13, weight: .heavy))
                                    .foregroundStyle(AvaTheme.ink)
                                    + Text(" if Mia's dentist runs long, you'll be tight for grocery pickup. Want me to move pickup to 3?")
                                    .font(AvaTheme.font(13, weight: .medium))
                                    .foregroundStyle(AvaTheme.ink)
                            }
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(AvaTheme.blush.opacity(0.2))
                        )
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 14)

                    Spacer().frame(height: 130)
                }
            }

            // Ava FAB
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

    // ── Data ────────────────────────────────────────────────────────────

    private struct FamilyMember {
        let name: String
        let color: Color
    }

    private let familyMembers: [FamilyMember] = [
        FamilyMember(name: "Me",   color: Color(hex: "D46A47")),
        FamilyMember(name: "Mia",  color: Color(hex: "E88D74")),
        FamilyMember(name: "Theo", color: Color(hex: "A5C09A")),
        FamilyMember(name: "Dan",  color: Color(hex: "B6A092")),
    ]

    private struct CalEvent: Identifiable {
        let id = UUID()
        let time: String
        let title: String
        let detail: String
        let color: Color
        let done: Bool
    }

    private let calEvents: [CalEvent] = [
        CalEvent(time: "8:00 AM",  title: "School drop · Theo",   detail: "with Dan",               color: Color(hex: "A5C09A"), done: true),
        CalEvent(time: "10:30 AM", title: "Mia · Dentist",        detail: "Dr. Chen · Valencia",    color: Color(hex: "E88D74"), done: false),
        CalEvent(time: "2:00 PM",  title: "Grocery pickup",       detail: "14 items · Bi-Rite",     color: Color(hex: "D46A47"), done: false),
        CalEvent(time: "4:00 PM",  title: "Theo's soccer",        detail: "Mission Park · field 3", color: Color(hex: "A5C09A"), done: false),
        CalEvent(time: "6:30 PM",  title: "Family dinner",        detail: "Sheet-pan lemon chicken",color: Color(hex: "B04A2A"), done: false),
    ]
}

#Preview {
    CalendarView(onChatTap: {})
}
