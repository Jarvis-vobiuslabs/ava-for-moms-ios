import SwiftUI
import Supabase

struct MemoriesView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(\.dismiss) private var dismiss
    @State private var memories: [AvaMemory] = []
    @State private var isLoading = true
    @State private var deleteError: String?

    struct AvaMemory: Identifiable, Decodable {
        let id: UUID
        let key: String
        let value: String
        let category: String
    }

    private var grouped: [(title: String, emoji: String, items: [AvaMemory])] {
        let order: [(String, String, String)] = [
            ("family",     "👨‍👩‍👧‍👦", "Family"),
            ("routine",    "🔄",  "Routines"),
            ("preference", "💛",  "Preferences"),
            ("health",     "🌿",  "Health"),
            ("general",    "📝",  "General"),
        ]
        return order.compactMap { key, emoji, title in
            let items = memories.filter { $0.category == key }
            guard !items.isEmpty else { return nil }
            return (title, emoji, items)
        }
    }

    var body: some View {
        ZStack {
            AvaTheme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("What Ava knows")
                            .font(AvaTheme.font(24, weight: .heavy))
                            .foregroundStyle(AvaTheme.ink)
                        Text("\(memories.count) memories")
                            .font(AvaTheme.font(13, weight: .medium))
                            .foregroundStyle(AvaTheme.inkMute)
                    }
                    Spacer()
                    Button { dismiss() } label: {
                        Circle().fill(AvaTheme.cream).frame(width: 36, height: 36)
                            .overlay(Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(AvaTheme.inkMute))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24).padding(.top, 60).padding(.bottom, 8)

                Text("Ava learns about you from your conversations. Swipe left to delete any memory.")
                    .font(AvaTheme.font(13, weight: .medium))
                    .foregroundStyle(AvaTheme.inkSoft)
                    .padding(.horizontal, 24).padding(.bottom, 20)

                if isLoading {
                    Spacer()
                    ProgressView().tint(AvaTheme.terracotta)
                    Spacer()
                } else if memories.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(grouped, id: \.title) { section in
                            Section {
                                ForEach(section.items) { memory in
                                    memoryRow(memory)
                                        .listRowBackground(AvaTheme.cream)
                                        .listRowSeparatorTint(AvaTheme.line)
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                _Concurrency.Task { await delete(memory) }
                                            } label: {
                                                Label("Forget", systemImage: "trash")
                                            }
                                        }
                                }
                            } header: {
                                HStack(spacing: 6) {
                                    Text(section.emoji)
                                    Text(section.title.uppercased())
                                        .font(AvaTheme.font(11, weight: .heavy))
                                        .foregroundStyle(AvaTheme.inkSoft)
                                        .tracking(0.8)
                                }
                                .padding(.top, 8)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .task { await loadMemories() }
    }

    // MARK: - Row

    private func memoryRow(_ memory: AvaMemory) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(memory.value)
                .font(AvaTheme.font(14, weight: .semibold))
                .foregroundStyle(AvaTheme.ink)
            Text(memory.key)
                .font(AvaTheme.font(12, weight: .medium))
                .foregroundStyle(AvaTheme.inkSoft)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Circle().fill(AvaTheme.bgDeep).frame(width: 72, height: 72)
                .overlay(Text("🧠").font(.system(size: 32)))
            Text("No memories yet")
                .font(AvaTheme.font(18, weight: .heavy)).foregroundStyle(AvaTheme.ink)
            Text("Chat with Ava and she'll start\nremembering things about your life.")
                .font(AvaTheme.font(14, weight: .medium)).foregroundStyle(AvaTheme.inkMute)
                .multilineTextAlignment(.center).lineSpacing(3)
            Spacer()
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Data

    private func loadMemories() async {
        guard let userId = auth.currentUserId else { return }
        isLoading = true
        if let loaded = try? await supabase
            .from("ava_memories")
            .select("id, key, value, category")
            .eq("user_id", value: userId.uuidString)
            .order("updated_at", ascending: false)
            .execute()
            .value as [AvaMemory] {
            memories = loaded
        }
        isLoading = false
    }

    private func delete(_ memory: AvaMemory) async {
        memories.removeAll { $0.id == memory.id }
        _ = try? await supabase.from("ava_memories").delete(returning: .minimal)
            .eq("id", value: memory.id.uuidString).execute()
    }
}

#Preview {
    MemoriesView().environment(AuthManager())
}
