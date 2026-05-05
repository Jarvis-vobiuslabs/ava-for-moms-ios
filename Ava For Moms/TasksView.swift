import SwiftUI

struct TasksView: View {
    let onChatTap: () -> Void
    @State private var doneCount = 3
    private let totalCount = 7

    var progress: Double { Double(doneCount) / Double(totalCount) }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            AvaTheme.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // ── Header ────────────────────────────────────────────
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tuesday · Apr 22")
                            .font(AvaTheme.font(13, weight: .bold))
                            .foregroundStyle(AvaTheme.inkMute)
                        Text("To-do 🌸")
                            .font(AvaTheme.font(28, weight: .heavy))
                            .foregroundStyle(AvaTheme.ink)
                            .tracking(-0.6)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 60)
                    .padding(.bottom, 14)

                    // ── Progress bar ──────────────────────────────────────
                    VStack(spacing: 8) {
                        HStack {
                            Text("\(doneCount) of \(totalCount) done")
                                .font(AvaTheme.font(12.5, weight: .bold))
                                .foregroundStyle(AvaTheme.inkMute)
                            Spacer()
                            Text("\(Int(progress * 100))%")
                                .font(AvaTheme.font(12.5, weight: .heavy))
                                .foregroundStyle(AvaTheme.terracotta)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(AvaTheme.bgDeep)
                                    .frame(height: 8)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(AvaTheme.blushTerracotta)
                                    .frame(width: geo.size.width * progress, height: 8)
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 20).fill(AvaTheme.cream))
                    .padding(.horizontal, 18)
                    .padding(.bottom, 16)

                    // ── Next Hour ─────────────────────────────────────────
                    sectionHeader("🔴 NEXT HOUR", color: AvaTheme.terracotta)

                    VStack(spacing: 8) {
                        urgentTask(title: "Pack Mia's dentist paperwork",
                                   note: "Insurance card in kitchen drawer")
                        urgentTask(title: "Confirm soccer carpool with Jess",
                                   note: nil)
                    }
                    .padding(.horizontal, 18)

                    // ── Sometime Today ────────────────────────────────────
                    sectionHeader("🌿 SOMETIME TODAY", color: AvaTheme.sageDeep)

                    VStack(spacing: 8) {
                        normalTask("Call pediatrician re: Mia's referral")
                        normalTask("RSVP — Theo's birthday party Sunday")
                    }
                    .padding(.horizontal, 18)

                    // ── Done ──────────────────────────────────────────────
                    sectionHeader("✓ DONE — \(doneCount)", color: AvaTheme.inkSoft)

                    VStack(spacing: 0) {
                        doneTask("Pack Theo's lunch")
                        doneTask("School drop at 8")
                        doneTask("Start the laundry")
                    }
                    .padding(.horizontal, 18)

                    // ── Add prompt ────────────────────────────────────────
                    Button(action: onChatTap) {
                        HStack(spacing: 10) {
                            Circle()
                                .fill(AvaTheme.blushTerracotta)
                                .frame(width: 26, height: 26)
                            Text("Tell Ava what's on your mind…")
                                .font(AvaTheme.font(13.5, weight: .semibold))
                                .foregroundStyle(AvaTheme.inkMute)
                            Spacer()
                        }
                        .padding(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(AvaTheme.line, style: StrokeStyle(lineWidth: 2, dash: [6]))
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 18)
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

    // ── Helpers ──────────────────────────────────────────────────────────

    private func sectionHeader(_ text: String, color: Color) -> some View {
        Text(text)
            .font(AvaTheme.font(12, weight: .heavy))
            .foregroundStyle(color)
            .tracking(0.3)
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 10)
    }

    private func urgentTask(title: String, note: String?) -> some View {
        HStack(spacing: 12) {
            Circle()
                .stroke(AvaTheme.terracotta, lineWidth: 2)
                .frame(width: 22, height: 22)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(AvaTheme.font(14.5, weight: .bold))
                    .foregroundStyle(AvaTheme.ink)
                if let note {
                    Text(note)
                        .font(AvaTheme.font(12, weight: .medium))
                        .foregroundStyle(AvaTheme.inkMute)
                }
            }
            Spacer()
        }
        .padding(16)
        .background(AvaTheme.cream)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .fill(AvaTheme.terracotta)
                .frame(width: 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 18, bottomLeadingRadius: 18,
                        bottomTrailingRadius: 0, topTrailingRadius: 0
                    )
                )
        )
    }

    private func normalTask(_ title: String) -> some View {
        HStack(spacing: 12) {
            Circle()
                .stroke(AvaTheme.inkSoft, lineWidth: 2)
                .frame(width: 22, height: 22)
            Text(title)
                .font(AvaTheme.font(14.5, weight: .bold))
                .foregroundStyle(AvaTheme.ink)
            Spacer()
        }
        .padding(16)
        .background(AvaTheme.cream)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.bottom, 8)
    }

    private func doneTask(_ title: String) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(AvaTheme.sage)
                .frame(width: 22, height: 22)
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                )
            Text(title)
                .font(AvaTheme.font(14.5, weight: .semibold))
                .foregroundStyle(AvaTheme.inkMute)
                .strikethrough(true, color: AvaTheme.inkSoft)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .opacity(0.55)
    }
}

#Preview {
    TasksView(onChatTap: {})
}
