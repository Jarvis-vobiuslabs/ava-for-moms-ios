import SwiftUI
import Supabase

// All-time chat history, read-only, grouped by day — for the user's own
// reference (the model's context is unaffected). Includes Clear History.

struct ChatHistoryView: View {
    var onCleared: () -> Void = {}

    @Environment(AuthManager.self) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var days: [(day: Date, messages: [HistoryMessage])] = []
    @State private var isLoading = true
    @State private var showClearConfirm = false
    @State private var isClearing = false

    struct HistoryMessage: Identifiable, Decodable {
        let id: UUID
        let role: String
        let content: String
        let createdAt: Date
        enum CodingKeys: String, CodingKey {
            case id, role, content
            case createdAt = "created_at"
        }
        var isAva: Bool { role == "assistant" }
    }

    var body: some View {
        ZStack {
            AvaTheme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Header ─────────────────────────────────────────────
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Chat History")
                            .font(AvaTheme.font(24, weight: .heavy))
                            .foregroundStyle(AvaTheme.ink)
                            .tracking(-0.5)
                        Text("Everything you and Ava have talked about")
                            .font(AvaTheme.font(12.5, weight: .medium))
                            .foregroundStyle(AvaTheme.inkMute)
                    }
                    Spacer()
                    Button { dismiss() } label: {
                        Circle().fill(AvaTheme.cream).frame(width: 36, height: 36)
                            .overlay(Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(AvaTheme.inkMute))
                    }
                    .contentShape(Rectangle())
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 22)
                .padding(.top, 26)
                .padding(.bottom, 14)

                // ── Transcript ─────────────────────────────────────────
                if isLoading {
                    Spacer()
                    ProgressView().tint(AvaTheme.terracotta)
                    Spacer()
                } else if days.isEmpty {
                    Spacer()
                    VStack(spacing: 10) {
                        Text("💬").font(.system(size: 40))
                        Text("No chats yet")
                            .font(AvaTheme.font(17, weight: .heavy))
                            .foregroundStyle(AvaTheme.ink)
                        Text("Your conversations with Ava will show up here.")
                            .font(AvaTheme.font(13.5, weight: .medium))
                            .foregroundStyle(AvaTheme.inkMute)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(days, id: \.day) { group in
                                Text(dayLabel(group.day))
                                    .font(AvaTheme.font(12, weight: .heavy))
                                    .foregroundStyle(AvaTheme.inkMute)
                                    .tracking(0.3)
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 14)
                                ForEach(group.messages) { msg in
                                    bubble(msg)
                                }
                            }
                            Spacer().frame(height: 20)
                        }
                        .padding(.horizontal, 18)
                    }

                    // ── Clear history ──────────────────────────────────
                    Button { showClearConfirm = true } label: {
                        HStack(spacing: 8) {
                            if isClearing {
                                ProgressView().tint(Color(hex: "C0392B")).scaleEffect(0.8)
                            } else {
                                Image(systemName: "trash")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            Text("Clear chat history")
                                .font(AvaTheme.font(14, weight: .bold))
                        }
                        .foregroundStyle(Color(hex: "C0392B"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: "FDEDED")))
                    }
                    .contentShape(Rectangle())
                    .buttonStyle(.plain)
                    .disabled(isClearing)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                }
            }
        }
        .task { await loadHistory() }
        .confirmationDialog("Clear all chat history?", isPresented: $showClearConfirm, titleVisibility: .visible) {
            Button("Clear Everything", role: .destructive) {
                _Concurrency.Task { await clearAll() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes every conversation with Ava. Her memories about you are kept.")
        }
    }

    // MARK: - Data

    private func loadHistory() async {
        guard let userId = auth.currentUserId else { isLoading = false; return }
        let rows: [HistoryMessage] = (try? await supabase
            .from("messages")
            .select("id, role, content, created_at")
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: true)
            .limit(1000)
            .execute()
            .value as [HistoryMessage]) ?? []

        let grouped = Dictionary(grouping: rows) { Calendar.current.startOfDay(for: $0.createdAt) }
        days = grouped.keys.sorted().map { (day: $0, messages: grouped[$0] ?? []) }
        isLoading = false
    }

    private func clearAll() async {
        guard let userId = auth.currentUserId else { return }
        isClearing = true
        // Deleting conversations cascades to their messages
        _ = try? await supabase.from("conversations")
            .delete(returning: .minimal)
            .eq("user_id", value: userId.uuidString)
            .execute()
        days = []
        isClearing = false
        onCleared()
        dismiss()
    }

    // MARK: - UI bits

    private func dayLabel(_ day: Date) -> String {
        if Calendar.current.isDateInToday(day) { return "TODAY" }
        if Calendar.current.isDateInYesterday(day) { return "YESTERDAY" }
        return day.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()).uppercased()
    }

    private func bubble(_ msg: HistoryMessage) -> some View {
        HStack {
            if !msg.isAva { Spacer(minLength: 60) }
            Text(msg.content)
                .font(AvaTheme.font(14, weight: .medium))
                .foregroundStyle(msg.isAva ? AvaTheme.ink : .white)
                .lineSpacing(2)
                .padding(.horizontal, 14).padding(.vertical, 11)
                .background(msg.isAva ? AvaTheme.cream : AvaTheme.terracotta)
                .clipShape(UnevenRoundedRectangle(
                    topLeadingRadius: 18,
                    bottomLeadingRadius: msg.isAva ? 5 : 18,
                    bottomTrailingRadius: msg.isAva ? 18 : 5,
                    topTrailingRadius: 18
                ))
            if msg.isAva { Spacer(minLength: 60) }
        }
        .frame(maxWidth: .infinity, alignment: msg.isAva ? .leading : .trailing)
    }
}

#Preview {
    ChatHistoryView().environment(AuthManager())
}
