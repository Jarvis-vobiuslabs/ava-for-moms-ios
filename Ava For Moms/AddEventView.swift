import SwiftUI

struct AddEventView: View {
    let onDismiss: () -> Void
    @State private var title = ""
    @State private var date = Date()
    @State private var notes = ""
    @FocusState private var titleFocused: Bool

    var body: some View {
        ZStack {
            AvaTheme.bg.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") { onDismiss() }
                        .font(AvaTheme.font(16, weight: .semibold))
                        .foregroundStyle(AvaTheme.terracotta)
                        .buttonStyle(.plain)
                    Spacer()
                    Text("New Event")
                        .font(AvaTheme.font(17, weight: .heavy))
                        .foregroundStyle(AvaTheme.ink)
                    Spacer()
                    Button("Add") { onDismiss() }
                        .font(AvaTheme.font(16, weight: .heavy))
                        .foregroundStyle(title.isEmpty ? AvaTheme.inkSoft : AvaTheme.terracotta)
                        .buttonStyle(.plain)
                        .disabled(title.isEmpty)
                }
                .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 24)

                VStack(spacing: 12) {
                    // Title
                    HStack(spacing: 12) {
                        Image(systemName: "calendar")
                            .font(.system(size: 16)).foregroundStyle(AvaTheme.inkSoft).frame(width: 20)
                        TextField("Event title", text: $title)
                            .font(AvaTheme.font(16, weight: .semibold))
                            .foregroundStyle(AvaTheme.ink)
                            .focused($titleFocused)
                    }
                    .padding(16).background(RoundedRectangle(cornerRadius: 14).fill(AvaTheme.cream))

                    // Date
                    HStack(spacing: 12) {
                        Image(systemName: "clock")
                            .font(.system(size: 16)).foregroundStyle(AvaTheme.inkSoft).frame(width: 20)
                        DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden().tint(AvaTheme.terracotta)
                    }
                    .padding(16).background(RoundedRectangle(cornerRadius: 14).fill(AvaTheme.cream))

                    // Notes
                    HStack(spacing: 12) {
                        Image(systemName: "note.text")
                            .font(.system(size: 16)).foregroundStyle(AvaTheme.inkSoft).frame(width: 20)
                        TextField("Add notes…", text: $notes, axis: .vertical)
                            .font(AvaTheme.font(15)).foregroundStyle(AvaTheme.ink).lineLimit(3...5)
                    }
                    .padding(16).background(RoundedRectangle(cornerRadius: 14).fill(AvaTheme.cream))
                }
                .padding(.horizontal, 18)

                Spacer()
            }
        }
        .onAppear { titleFocused = true }
    }
}
