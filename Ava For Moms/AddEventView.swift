import SwiftUI

struct AddEventView: View {
    let initialDate: Date
    let onSave: (String, String?, Date, Date, Bool) -> Void
    let onDismiss: () -> Void

    @State private var title = ""
    @State private var detail = ""
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var addToCalendar = true
    @FocusState private var titleFocused: Bool

    init(initialDate: Date, onSave: @escaping (String, String?, Date, Date, Bool) -> Void, onDismiss: @escaping () -> Void) {
        self.initialDate = initialDate
        self.onSave = onSave
        self.onDismiss = onDismiss
        // Default: starts at the nearest upcoming hour, lasts 1 hour
        let now = initialDate
        let rounded = Calendar.current.date(bySetting: .minute, value: 0, of: now) ?? now
        let start = Calendar.current.date(byAdding: .hour, value: 1, to: rounded) ?? rounded
        _startDate = State(initialValue: start)
        _endDate   = State(initialValue: Calendar.current.date(byAdding: .hour, value: 1, to: start) ?? start)
    }

    var canSave: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        ZStack {
            AvaTheme.bg.ignoresSafeArea()
            VStack(spacing: 0) {

                // Header
                HStack {
                    Button("Cancel") { onDismiss() }
                        .font(AvaTheme.font(16, weight: .semibold))
                        .foregroundStyle(AvaTheme.terracotta).buttonStyle(.plain)
                    Spacer()
                    Text("New Event")
                        .font(AvaTheme.font(17, weight: .heavy)).foregroundStyle(AvaTheme.ink)
                    Spacer()
                    Button("Add") {
                        onSave(
                            title.trimmingCharacters(in: .whitespaces),
                            detail.isEmpty ? nil : detail,
                            startDate, endDate, addToCalendar
                        )
                        onDismiss()
                    }
                    .font(AvaTheme.font(16, weight: .heavy))
                    .foregroundStyle(canSave ? AvaTheme.terracotta : AvaTheme.inkSoft)
                    .buttonStyle(.plain).disabled(!canSave)
                }
                .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 24)

                ScrollView {
                    VStack(spacing: 12) {

                        // Title
                        fieldRow(icon: "calendar", placeholder: "Event title", text: $title, focused: true)

                        // Notes
                        fieldRow(icon: "note.text", placeholder: "Add notes (optional)", text: $detail, focused: false)

                        // Start
                        HStack(spacing: 12) {
                            Image(systemName: "clock")
                                .font(.system(size: 15)).foregroundStyle(AvaTheme.inkSoft).frame(width: 20)
                            Text("Starts")
                                .font(AvaTheme.font(14, weight: .medium)).foregroundStyle(AvaTheme.inkMute)
                            Spacer()
                            DatePicker("", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                                .labelsHidden().tint(AvaTheme.terracotta)
                                .onChange(of: startDate) { _, val in
                                    if endDate <= val {
                                        endDate = Calendar.current.date(byAdding: .hour, value: 1, to: val) ?? val
                                    }
                                }
                        }
                        .padding(16).background(RoundedRectangle(cornerRadius: 14).fill(AvaTheme.cream))

                        // End
                        HStack(spacing: 12) {
                            Image(systemName: "clock.badge.checkmark")
                                .font(.system(size: 15)).foregroundStyle(AvaTheme.inkSoft).frame(width: 20)
                            Text("Ends")
                                .font(AvaTheme.font(14, weight: .medium)).foregroundStyle(AvaTheme.inkMute)
                            Spacer()
                            DatePicker("", selection: $endDate,
                                       in: startDate...,
                                       displayedComponents: [.date, .hourAndMinute])
                                .labelsHidden().tint(AvaTheme.terracotta)
                        }
                        .padding(16).background(RoundedRectangle(cornerRadius: 14).fill(AvaTheme.cream))

                        // Add to native calendar toggle
                        HStack(spacing: 12) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 15)).foregroundStyle(AvaTheme.inkSoft).frame(width: 20)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Add to Apple Calendar")
                                    .font(AvaTheme.font(14, weight: .bold)).foregroundStyle(AvaTheme.ink)
                                Text("Also appears in your native Calendar app")
                                    .font(AvaTheme.font(12, weight: .medium)).foregroundStyle(AvaTheme.inkMute)
                            }
                            Spacer()
                            Toggle("", isOn: $addToCalendar).labelsHidden().tint(AvaTheme.terracotta)
                        }
                        .padding(16).background(RoundedRectangle(cornerRadius: 14).fill(AvaTheme.cream))
                    }
                    .padding(.horizontal, 18)
                    Spacer().frame(height: 40)
                }
            }
        }
        .onAppear { titleFocused = true }
    }

    private func fieldRow(icon: String, placeholder: String, text: Binding<String>, focused: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15)).foregroundStyle(AvaTheme.inkSoft).frame(width: 20)
            TextField(placeholder, text: text)
                .font(AvaTheme.font(15, weight: .medium)).foregroundStyle(AvaTheme.ink)
                .focused($titleFocused)
        }
        .padding(16).background(RoundedRectangle(cornerRadius: 14).fill(AvaTheme.cream))
    }
}
