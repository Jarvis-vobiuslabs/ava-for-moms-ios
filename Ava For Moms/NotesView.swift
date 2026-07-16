import SwiftUI

struct NotesView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(NotesStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var showAddNote = false
    @State private var editingNote: AvaNote?

    var body: some View {
        ZStack {
            AvaTheme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Header ──────────────────────────────────────────────
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Notes")
                            .font(AvaTheme.font(28, weight: .heavy))
                            .foregroundStyle(AvaTheme.ink)
                            .tracking(-0.6)
                        Text("Things to remember")
                            .font(AvaTheme.font(13, weight: .medium))
                            .foregroundStyle(AvaTheme.inkMute)
                    }
                    Spacer()
                    HStack(spacing: 10) {
                        Button { showAddNote = true } label: {
                            Circle().fill(AvaTheme.blushTerracotta).frame(width: 40, height: 40)
                                .overlay(Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .bold)).foregroundStyle(.white))
                                .shadow(color: AvaTheme.terracotta.opacity(0.35), radius: 6, x: 0, y: 3)
                        }
                        .contentShape(Rectangle())
                        .buttonStyle(.plain)

                        Button { dismiss() } label: {
                            Circle().fill(AvaTheme.cream).frame(width: 40, height: 40)
                                .overlay(Image(systemName: "xmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(AvaTheme.inkMute))
                        }
                        .contentShape(Rectangle())
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24).padding(.top, 60).padding(.bottom, 20)

                // ── List ────────────────────────────────────────────────
                if store.isLoading {
                    Spacer()
                    ProgressView().tint(AvaTheme.terracotta)
                    Spacer()
                } else if store.notes.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(store.notes) { note in
                            NoteCard(note: note, onTap: { editingNote = note }) {
                                _Concurrency.Task { await store.delete(note) }
                            }
                            .listRowInsets(EdgeInsets(top: 6, leading: 18, bottom: 6, trailing: 18))
                            .listRowBackground(AvaTheme.bg)
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .sheet(isPresented: $showAddNote) {
            NoteEditView(note: nil) { title, content in
                guard let userId = auth.currentUserId else { return }
                _Concurrency.Task { await store.add(title: title, content: content, userId: userId) }
            }
        }
        .sheet(item: $editingNote) { note in
            NoteEditView(note: note) { title, content in
                var updated = note
                updated.title = title
                updated.content = content
                _Concurrency.Task { await store.update(updated) }
            }
        }
        .task {
            guard let userId = auth.currentUserId else { return }
            await store.load(userId: userId)
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Circle().fill(AvaTheme.blushTerracotta.opacity(0.15)).frame(width: 72, height: 72)
                .overlay(Image(systemName: "note.text")
                    .font(.system(size: 28)).foregroundStyle(AvaTheme.terracotta))
            Text("No notes yet")
                .font(AvaTheme.font(18, weight: .heavy)).foregroundStyle(AvaTheme.ink)
            Text("Tell Ava to note something down, or tap + to add one yourself")
                .font(AvaTheme.font(14, weight: .medium)).foregroundStyle(AvaTheme.inkMute)
                .multilineTextAlignment(.center).lineSpacing(3)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

}

// MARK: - Note card

private struct NoteCard: View {
    let note: AvaNote
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 14) {
                noteIcon
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(note.title)
                            .font(AvaTheme.font(14.5, weight: .heavy))
                            .foregroundStyle(AvaTheme.ink)
                            .lineLimit(1)
                        Spacer()
                        Text(note.createdAt.formatted(.dateTime.month(.abbreviated).day()))
                            .font(AvaTheme.font(11, weight: .medium))
                            .foregroundStyle(AvaTheme.inkSoft)
                    }
                    if !note.content.isEmpty {
                        Text(note.content)
                            .font(AvaTheme.font(13, weight: .medium))
                            .foregroundStyle(AvaTheme.inkMute)
                            .lineLimit(2)
                            .lineSpacing(2)
                    }
                    if note.isAva {
                        Text("Saved by Ava")
                            .font(AvaTheme.font(10, weight: .bold))
                            .foregroundStyle(AvaTheme.terracotta)
                            .padding(.top, 2)
                    }
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 18).fill(AvaTheme.cream))
        }
        .contentShape(Rectangle())
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    @ViewBuilder
    private var noteIcon: some View {
        ZStack {
            if note.isAva {
                RoundedRectangle(cornerRadius: 10).fill(AvaTheme.blushTerracotta.opacity(0.15)).frame(width: 36, height: 36)
                Image(systemName: "face.smiling").font(.system(size: 15, weight: .medium)).foregroundStyle(AvaTheme.terracotta)
            } else {
                RoundedRectangle(cornerRadius: 10).fill(AvaTheme.bgDeep).frame(width: 36, height: 36)
                Image(systemName: "note.text").font(.system(size: 15, weight: .medium)).foregroundStyle(AvaTheme.inkMute)
            }
        }
    }
}

// MARK: - Add / Edit sheet

struct NoteEditView: View {
    let note: AvaNote?
    let onSave: (String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var content = ""
    @FocusState private var titleFocused: Bool

    init(note: AvaNote?, onSave: @escaping (String, String) -> Void) {
        self.note = note
        self.onSave = onSave
        _title   = State(initialValue: note?.title   ?? "")
        _content = State(initialValue: note?.content ?? "")
    }

    private var canSave: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        ZStack {
            AvaTheme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") { dismiss() }
                        .font(AvaTheme.font(16, weight: .semibold))
                        .foregroundStyle(AvaTheme.terracotta).contentShape(Rectangle()).buttonStyle(.plain)
                    Spacer()
                    Text(note == nil ? "New Note" : "Edit Note")
                        .font(AvaTheme.font(17, weight: .heavy)).foregroundStyle(AvaTheme.ink)
                    Spacer()
                    Button("Save") {
                        onSave(title.trimmingCharacters(in: .whitespaces), content)
                        dismiss()
                    }
                    .font(AvaTheme.font(16, weight: .heavy))
                    .foregroundStyle(canSave ? AvaTheme.terracotta : AvaTheme.inkSoft)
                    .contentShape(Rectangle())
                    .buttonStyle(.plain).disabled(!canSave)
                }
                .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 24)

                ScrollView {
                    VStack(spacing: 12) {
                        // Title
                        HStack(spacing: 12) {
                            Image(systemName: "text.cursor")
                                .font(.system(size: 15)).foregroundStyle(AvaTheme.inkSoft).frame(width: 20)
                            TextField("Title", text: $title)
                                .font(AvaTheme.font(15, weight: .bold)).foregroundStyle(AvaTheme.ink)
                                .focused($titleFocused)
                        }
                        .padding(16).background(RoundedRectangle(cornerRadius: 14).fill(AvaTheme.cream))

                        // Content
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "note.text")
                                .font(.system(size: 15)).foregroundStyle(AvaTheme.inkSoft)
                                .frame(width: 20).padding(.top, 2)
                            TextField("Note content…", text: $content, axis: .vertical)
                                .font(AvaTheme.font(14, weight: .medium)).foregroundStyle(AvaTheme.ink)
                                .lineLimit(5...20)
                        }
                        .padding(16).background(RoundedRectangle(cornerRadius: 14).fill(AvaTheme.cream))
                    }
                    .padding(.horizontal, 18)
                }
            }
        }
        .onAppear { titleFocused = true }
    }
}
