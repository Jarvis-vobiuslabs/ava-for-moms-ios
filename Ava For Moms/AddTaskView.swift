import SwiftUI

struct AddTaskView: View {
    let onAdd: (String, String?, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var note = ""
    @State private var priority = "normal"
    @FocusState private var titleFocused: Bool

    var body: some View {
        ZStack {
            AvaTheme.bg.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Button("Cancel") { dismiss() }
                        .font(AvaTheme.font(16, weight: .semibold))
                        .foregroundStyle(AvaTheme.terracotta).contentShape(Rectangle()).buttonStyle(.plain)
                    Spacer()
                    Text("New Task")
                        .font(AvaTheme.font(17, weight: .heavy)).foregroundStyle(AvaTheme.ink)
                    Spacer()
                    Button("Add") {
                        onAdd(title, note.isEmpty ? nil : note, priority)
                        dismiss()
                    }
                    .font(AvaTheme.font(16, weight: .heavy))
                    .foregroundStyle(title.isEmpty ? AvaTheme.inkSoft : AvaTheme.terracotta)
                    .contentShape(Rectangle())
                    .buttonStyle(.plain).disabled(title.isEmpty)
                }
                .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 24)

                VStack(spacing: 12) {
                    fieldRow(icon: "checkmark.circle", placeholder: "Task title", text: $title, focused: true)
                    fieldRow(icon: "note.text", placeholder: "Add a note (optional)", text: $note, focused: false)

                    // Priority picker
                    HStack(spacing: 8) {
                        ForEach(["normal", "urgent"], id: \.self) { p in
                            Button { priority = p } label: {
                                HStack(spacing: 6) {
                                    Circle().fill(p == "urgent" ? AvaTheme.terracotta : AvaTheme.sage)
                                        .frame(width: 8, height: 8)
                                    Text(p == "urgent" ? "Urgent" : "Normal")
                                        .font(AvaTheme.font(14, weight: .bold))
                                        .foregroundStyle(priority == p ? .white : AvaTheme.ink)
                                }
                                .padding(.horizontal, 16).padding(.vertical, 10)
                                .background(Capsule().fill(priority == p
                                    ? (p == "urgent" ? AvaTheme.terracotta : AvaTheme.sage)
                                    : AvaTheme.cream))
                            }
                            .contentShape(Rectangle())
                            .buttonStyle(.plain)
                            .animation(.easeInOut(duration: 0.15), value: priority)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 14).fill(AvaTheme.cream))
                }
                .padding(.horizontal, 18)
                Spacer()
            }
        }
        .onAppear { titleFocused = true }
    }

    @ViewBuilder
    private func fieldRow(icon: String, placeholder: String, text: Binding<String>, focused: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 16)).foregroundStyle(AvaTheme.inkSoft).frame(width: 20)
            TextField(placeholder, text: text)
                .font(AvaTheme.font(15, weight: .medium)).foregroundStyle(AvaTheme.ink)
                .focused($titleFocused)
        }
        .padding(16).background(RoundedRectangle(cornerRadius: 14).fill(AvaTheme.cream))
    }
}
