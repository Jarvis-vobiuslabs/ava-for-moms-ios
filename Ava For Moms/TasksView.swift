import SwiftUI

struct TasksView: View {
    let onChatTap: () -> Void
    @Environment(AuthManager.self) private var auth
    @Environment(TaskStore.self) private var store
    @State private var showAddTask = false

    var progress: Double {
        let total = store.urgent.count + store.normal.count + store.done.count
        guard total > 0 else { return 0 }
        return Double(store.done.count) / Double(total)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            AvaTheme.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // ── Header ────────────────────────────────────────────
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(Date().formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                                .font(AvaTheme.font(13, weight: .bold)).foregroundStyle(AvaTheme.inkMute)
                            Text("To-do 🌸")
                                .font(AvaTheme.font(28, weight: .heavy)).foregroundStyle(AvaTheme.ink).tracking(-0.6)
                        }
                        Spacer()
                        Button { showAddTask = true } label: {
                            Circle().fill(AvaTheme.blushTerracotta).frame(width: 40, height: 40)
                                .overlay(Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .bold)).foregroundStyle(.white))
                                .shadow(color: AvaTheme.terracotta.opacity(0.35), radius: 6, x: 0, y: 3)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 22).padding(.top, 60).padding(.bottom, 14)

                    // ── Progress ──────────────────────────────────────────
                    let total = store.urgent.count + store.normal.count + store.done.count
                    if total > 0 {
                        VStack(spacing: 8) {
                            HStack {
                                Text("\(store.done.count) of \(total) done")
                                    .font(AvaTheme.font(12.5, weight: .bold)).foregroundStyle(AvaTheme.inkMute)
                                Spacer()
                                Text("\(Int(progress * 100))%")
                                    .font(AvaTheme.font(12.5, weight: .heavy)).foregroundStyle(AvaTheme.terracotta)
                            }
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4).fill(AvaTheme.bgDeep).frame(height: 8)
                                    RoundedRectangle(cornerRadius: 4).fill(AvaTheme.blushTerracotta)
                                        .frame(width: geo.size.width * progress, height: 8)
                                        .animation(.spring(duration: 0.4), value: progress)
                                }
                            }
                            .frame(height: 8)
                        }
                        .padding(16).background(RoundedRectangle(cornerRadius: 20).fill(AvaTheme.cream))
                        .padding(.horizontal, 18).padding(.bottom, 16)
                    }

                    // ── Urgent tasks ──────────────────────────────────────
                    if !store.urgent.isEmpty {
                        sectionHeader("🔴 NEXT HOUR", color: AvaTheme.terracotta)
                        VStack(spacing: 8) {
                            ForEach(store.urgent) { task in
                                taskRow(task, isUrgent: true)
                            }
                        }
                        .padding(.horizontal, 18)
                    }

                    // ── Normal tasks ──────────────────────────────────────
                    if !store.normal.isEmpty {
                        sectionHeader("🌿 SOMETIME TODAY", color: AvaTheme.sageDeep)
                        VStack(spacing: 8) {
                            ForEach(store.normal) { task in
                                taskRow(task, isUrgent: false)
                            }
                        }
                        .padding(.horizontal, 18)
                    }

                    // ── Empty state ───────────────────────────────────────
                    if store.urgent.isEmpty && store.normal.isEmpty && !store.isLoading {
                        VStack(spacing: 12) {
                            Text("🎉").font(.system(size: 36))
                            Text("All clear!")
                                .font(AvaTheme.font(18, weight: .heavy)).foregroundStyle(AvaTheme.ink)
                            Text("No tasks yet. Tap + or tell Ava what's on your mind.")
                                .font(AvaTheme.font(14, weight: .medium)).foregroundStyle(AvaTheme.inkMute)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 40).padding(.horizontal, 40)
                    }

                    // ── Done ──────────────────────────────────────────────
                    if !store.done.isEmpty {
                        sectionHeader("✓ DONE — \(store.done.count)", color: AvaTheme.inkSoft)
                        VStack(spacing: 0) {
                            ForEach(store.done) { task in
                                doneRow(task)
                            }
                        }
                        .padding(.horizontal, 18)
                    }

                    // ── Add prompt ────────────────────────────────────────
                    Button { onChatTap() } label: {
                        HStack(spacing: 10) {
                            Circle().fill(AvaTheme.blushTerracotta).frame(width: 26, height: 26)
                            Text("Tell Ava what's on your mind…")
                                .font(AvaTheme.font(13.5, weight: .semibold)).foregroundStyle(AvaTheme.inkMute)
                            Spacer()
                        }
                        .padding(14)
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(AvaTheme.line, style: StrokeStyle(lineWidth: 2, dash: [6])))
                    }
                    .buttonStyle(.plain).padding(.horizontal, 18).padding(.top, 14)

                    Spacer().frame(height: 130)
                }
            }

            // FAB
            Button(action: onChatTap) {
                Circle().fill(AvaTheme.blushTerracotta).frame(width: 56, height: 56)
                    .overlay(Image(systemName: "face.smiling").font(.system(size: 22, weight: .bold)).foregroundStyle(.white))
                    .shadow(color: AvaTheme.terracotta.opacity(0.4), radius: 12, x: 0, y: 8)
            }
            .buttonStyle(.plain).padding(.trailing, 18).padding(.bottom, 100)
        }
        .sheet(isPresented: $showAddTask) {
            AddTaskView { title, note, priority in
                if let userId = auth.currentUserId {
                    _Concurrency.Task { await store.add(title: title, note: note, priority: priority, userId: userId) }
                }
            }
        }
        .task {
            if let userId = auth.currentUserId { await store.load(userId: userId) }
        }
    }

    // MARK: - Row builders

    private func taskRow(_ task: AvaTask, isUrgent: Bool) -> some View {
        HStack(spacing: 12) {
            Button {
                _Concurrency.Task { await store.complete(task) }
            } label: {
                Circle().stroke(isUrgent ? AvaTheme.terracotta : AvaTheme.inkSoft, lineWidth: 2)
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title).font(AvaTheme.font(14.5, weight: .bold)).foregroundStyle(AvaTheme.ink)
                if let note = task.note {
                    Text(note).font(AvaTheme.font(12, weight: .medium)).foregroundStyle(AvaTheme.inkMute)
                }
            }
            Spacer()
        }
        .padding(16)
        .background(AvaTheme.cream)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18).fill(isUrgent ? AvaTheme.terracotta : AvaTheme.sage)
                .frame(width: 4).frame(maxWidth: .infinity, alignment: .leading)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 18, bottomLeadingRadius: 18,
                                                   bottomTrailingRadius: 0, topTrailingRadius: 0))
        )
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { _Concurrency.Task { await store.delete(task) } }
                label: { Label("Delete", systemImage: "trash") }
        }
    }

    private func doneRow(_ task: AvaTask) -> some View {
        HStack(spacing: 12) {
            Button { _Concurrency.Task { await store.uncomplete(task) } } label: {
                Circle().fill(AvaTheme.sage).frame(width: 22, height: 22)
                    .overlay(Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundStyle(.white))
            }
            .buttonStyle(.plain)

            Text(task.title).font(AvaTheme.font(14.5, weight: .semibold))
                .foregroundStyle(AvaTheme.inkMute).strikethrough(true, color: AvaTheme.inkSoft)
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 12).opacity(0.55)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { _Concurrency.Task { await store.delete(task) } }
                label: { Label("Delete", systemImage: "trash") }
        }
    }

    private func sectionHeader(_ text: String, color: Color) -> some View {
        Text(text).font(AvaTheme.font(12, weight: .heavy)).foregroundStyle(color).tracking(0.3)
            .padding(.horizontal, 24).padding(.top, 20).padding(.bottom, 10)
    }
}

#Preview {
    TasksView(onChatTap: {}).environment(AuthManager()).environment(TaskStore())
}
