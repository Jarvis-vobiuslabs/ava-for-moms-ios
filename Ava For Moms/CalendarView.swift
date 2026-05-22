import SwiftUI

struct CalendarView: View {
    let onChatTap: () -> Void
    @Environment(AuthManager.self) private var auth
    @Environment(CalendarStore.self) private var store

    @State private var selectedDate = Date()
    @State private var weekStart = Date().startOfWeek
    @State private var showAddEvent = false

    private var weekDays: [Date] {
        (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: weekStart) }
    }

    private var selectedEvents: [AvaCalendarEvent] {
        store.events(on: selectedDate)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            AvaTheme.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // ── Header ────────────────────────────────────────────
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(selectedDate.formatted(.dateTime.month(.wide).year()))
                                .font(AvaTheme.font(13, weight: .bold)).foregroundStyle(AvaTheme.inkMute)
                            Text("This week")
                                .font(AvaTheme.font(28, weight: .heavy)).foregroundStyle(AvaTheme.ink).tracking(-0.6)
                        }
                        Spacer()
                        Button { showAddEvent = true } label: {
                            Circle().fill(AvaTheme.blushTerracotta).frame(width: 44, height: 44)
                                .overlay(Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .bold)).foregroundStyle(.white))
                                .shadow(color: AvaTheme.terracotta.opacity(0.4), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 22).padding(.top, 60).padding(.bottom, 18)

                    // ── Week navigation ───────────────────────────────────
                    HStack(spacing: 4) {
                        // Prev week
                        Button {
                            weekStart = Calendar.current.date(byAdding: .day, value: -7, to: weekStart) ?? weekStart
                            selectedDate = weekStart
                            loadEvents()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold)).foregroundStyle(AvaTheme.inkMute)
                                .frame(width: 32, height: 44)
                        }
                        .buttonStyle(.plain)

                        // Day pills
                        ForEach(weekDays, id: \.self) { day in
                            Button { selectedDate = day } label: {
                                VStack(spacing: 2) {
                                    Text(day.formatted(.dateTime.weekday(.narrow)))
                                        .font(AvaTheme.font(10, weight: .bold)).opacity(0.8)
                                    Text(day.formatted(.dateTime.day()))
                                        .font(AvaTheme.font(16, weight: .heavy))
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 8)
                                .foregroundStyle(isSelected(day) ? .white : AvaTheme.ink)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(isSelected(day) ? AvaTheme.terracotta : Color.clear)
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        // Next week
                        Button {
                            weekStart = Calendar.current.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
                            selectedDate = weekStart
                            loadEvents()
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold)).foregroundStyle(AvaTheme.inkMute)
                                .frame(width: 32, height: 44)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(6).background(RoundedRectangle(cornerRadius: 22).fill(AvaTheme.cream))
                    .padding(.horizontal, 22)

                    // ── Calendar access prompt ────────────────────────────
                    if !store.calendarAccessGranted {
                        Button {
                            _Concurrency.Task {
                                await store.requestAccess()
                                loadEvents()
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "calendar.badge.plus")
                                    .font(.system(size: 18)).foregroundStyle(AvaTheme.terracotta)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Connect your calendar")
                                        .font(AvaTheme.font(14, weight: .bold)).foregroundStyle(AvaTheme.ink)
                                    Text("Ava can see your existing events and help you plan")
                                        .font(AvaTheme.font(12, weight: .medium)).foregroundStyle(AvaTheme.inkMute)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12)).foregroundStyle(AvaTheme.inkSoft)
                            }
                            .padding(16)
                            .background(RoundedRectangle(cornerRadius: 18).fill(AvaTheme.cream))
                        }
                        .buttonStyle(.plain).padding(.horizontal, 22).padding(.top, 16)
                    }

                    // ── Events for selected day ───────────────────────────
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(selectedDate.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                                .font(AvaTheme.font(15, weight: .heavy)).foregroundStyle(AvaTheme.ink)
                            Spacer()
                            if !selectedEvents.isEmpty {
                                Text("\(selectedEvents.count) event\(selectedEvents.count == 1 ? "" : "s")")
                                    .font(AvaTheme.font(12, weight: .bold)).foregroundStyle(AvaTheme.terracotta)
                            }
                        }
                        .padding(.top, 20)

                        if store.isLoading {
                            HStack { Spacer(); ProgressView().tint(AvaTheme.terracotta); Spacer() }
                                .padding(.vertical, 30)
                        } else if selectedEvents.isEmpty {
                            VStack(spacing: 8) {
                                Text("No events").font(AvaTheme.font(15, weight: .heavy)).foregroundStyle(AvaTheme.ink)
                                Text("Tap + to add one or ask Ava to schedule something")
                                    .font(AvaTheme.font(13, weight: .medium)).foregroundStyle(AvaTheme.inkMute)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 30)
                        } else {
                            ForEach(selectedEvents) { event in
                                eventRow(event)
                            }
                        }
                    }
                    .padding(.horizontal, 22)

                    Spacer().frame(height: 130)
                }
            }

            // Ava FAB
            Button(action: onChatTap) {
                Circle().fill(AvaTheme.blushTerracotta).frame(width: 56, height: 56)
                    .overlay(Image(systemName: "face.smiling")
                        .font(.system(size: 22, weight: .bold)).foregroundStyle(.white))
                    .shadow(color: AvaTheme.terracotta.opacity(0.4), radius: 12, x: 0, y: 8)
            }
            .buttonStyle(.plain).padding(.trailing, 18).padding(.bottom, 100)
        }
        .sheet(isPresented: $showAddEvent) {
            AddEventView(
                initialDate: selectedDate,
                onSave: { title, detail, start, end, addNative in
                    guard let userId = auth.currentUserId else { return }
                    _Concurrency.Task {
                        await store.createEvent(
                            title: title, detail: detail, startsAt: start, endsAt: end,
                            addToNativeCalendar: addNative, userId: userId
                        )
                    }
                },
                onDismiss: { showAddEvent = false }
            )
        }
        .task {
            await store.requestAccess()
            loadEvents()
        }
    }

    // MARK: - Helpers

    private func loadEvents() {
        guard let userId = auth.currentUserId else { return }
        _Concurrency.Task { await store.load(userId: userId, weekStart: weekStart) }
    }

    private func isSelected(_ date: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: selectedDate)
    }

    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }

    private func eventRow(_ event: AvaCalendarEvent) -> some View {
        HStack(spacing: 14) {
            // Time
            VStack(alignment: .trailing, spacing: 2) {
                Text(event.timeString)
                    .font(AvaTheme.font(12, weight: .bold)).foregroundStyle(AvaTheme.inkMute)
                if event.source == .eventKit {
                    Image(systemName: "calendar").font(.system(size: 9)).foregroundStyle(AvaTheme.inkSoft)
                } else {
                    Image(systemName: "face.smiling").font(.system(size: 9)).foregroundStyle(AvaTheme.terracotta)
                }
            }
            .frame(width: 52, alignment: .trailing)

            // Colour bar + content
            HStack(spacing: 0) {
                Rectangle().fill(event.color).frame(width: 4)
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: 4, bottomLeadingRadius: 4,
                                                      bottomTrailingRadius: 0, topTrailingRadius: 0))

                VStack(alignment: .leading, spacing: 3) {
                    Text(event.title)
                        .font(AvaTheme.font(14.5, weight: .heavy)).foregroundStyle(AvaTheme.ink)
                    if let detail = event.detail, !detail.isEmpty {
                        Text(detail)
                            .font(AvaTheme.font(12, weight: .medium)).foregroundStyle(AvaTheme.inkMute)
                    }
                }
                .padding(.horizontal, 14).padding(.vertical, 12)
                Spacer()
            }
            .background(RoundedRectangle(cornerRadius: 16).fill(AvaTheme.cream))
        }
        .swipeActions(edge: .trailing) {
            if event.source == .ava {
                Button(role: .destructive) {
                    guard let userId = auth.currentUserId else { return }
                    _Concurrency.Task { await store.delete(event, userId: userId) }
                } label: { Label("Delete", systemImage: "trash") }
            }
        }
    }
}

#Preview {
    CalendarView(onChatTap: {}).environment(AuthManager()).environment(CalendarStore())
}
