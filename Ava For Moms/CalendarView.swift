import SwiftUI

struct CalendarView: View {
    let onChatTap: () -> Void
    @Environment(AuthManager.self) private var auth
    @Environment(CalendarStore.self) private var store

    @State private var selectedDate = Date()
    @State private var weekStart = Date().startOfWeek
    @State private var showAddEvent = false
    @State private var showMonthGrid = false
    @State private var displayedMonth = Date()

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
                            // Tap the month to open the month grid
                            Button {
                                displayedMonth = selectedDate
                                withAnimation(.easeInOut(duration: 0.22)) { showMonthGrid.toggle() }
                            } label: {
                                HStack(spacing: 5) {
                                    Text(selectedDate.formatted(.dateTime.month(.wide).year()))
                                        .font(AvaTheme.font(13, weight: .bold)).foregroundStyle(AvaTheme.inkMute)
                                    Image(systemName: showMonthGrid ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 10, weight: .bold)).foregroundStyle(AvaTheme.terracotta)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            Text("This week")
                                .font(AvaTheme.font(28, weight: .heavy)).foregroundStyle(AvaTheme.ink).tracking(-0.6)
                        }
                        Spacer()
                        if !Calendar.current.isDateInToday(selectedDate) {
                            Button(action: goToToday) {
                                Text("Today")
                                    .font(AvaTheme.font(13, weight: .heavy))
                                    .foregroundStyle(AvaTheme.terracotta)
                                    .padding(.horizontal, 14).padding(.vertical, 9)
                                    .background(Capsule().stroke(AvaTheme.terracotta.opacity(0.5), lineWidth: 1.5))
                                    .contentShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                        Button { showAddEvent = true } label: {
                            Circle().fill(AvaTheme.blushTerracotta).frame(width: 44, height: 44)
                                .overlay(Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .bold)).foregroundStyle(.white))
                                .shadow(color: AvaTheme.terracotta.opacity(0.4), radius: 8, x: 0, y: 4)
                        }
                        .contentShape(Rectangle())
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 22).padding(.top, 60).padding(.bottom, 18)

                    // ── Month grid (expanded from the month button) ───────
                    if showMonthGrid {
                        monthGrid
                            .padding(.horizontal, 22)
                            .padding(.bottom, 14)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

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
                        .contentShape(Rectangle())
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
                            .contentShape(Rectangle())
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
                        .contentShape(Rectangle())
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
                        .contentShape(Rectangle())
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
                            Button { showAddEvent = true } label: {
                                VStack(spacing: 8) {
                                    Text("No events").font(AvaTheme.font(15, weight: .heavy)).foregroundStyle(AvaTheme.ink)
                                    Text("Tap to add one, or ask Ava to schedule something")
                                        .font(AvaTheme.font(13, weight: .medium)).foregroundStyle(AvaTheme.terracotta)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 30)
                            }
                            .contentShape(Rectangle())
                            .buttonStyle(.plain)
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
            .contentShape(Rectangle())
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

    // MARK: - Month grid

    private var monthGrid: some View {
        let cal = Calendar.current
        let interval = cal.dateInterval(of: .month, for: displayedMonth)
            ?? DateInterval(start: displayedMonth, duration: 0)
        let leadingBlanks = (cal.component(.weekday, from: interval.start) - cal.firstWeekday + 7) % 7
        let dayCount = cal.range(of: .day, in: .month, for: displayedMonth)?.count ?? 30
        let symbols = Array(cal.veryShortWeekdaySymbols[(cal.firstWeekday - 1)...]
                            + cal.veryShortWeekdaySymbols[..<(cal.firstWeekday - 1)])

        return VStack(spacing: 10) {
            // Month navigation
            HStack {
                Button { shiftMonth(-1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold)).foregroundStyle(AvaTheme.inkMute)
                        .frame(width: 38, height: 32).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Spacer()
                Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                    .font(AvaTheme.font(15, weight: .heavy)).foregroundStyle(AvaTheme.ink)
                Spacer()
                Button { shiftMonth(1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold)).foregroundStyle(AvaTheme.inkMute)
                        .frame(width: 38, height: 32).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            // Weekday symbols
            HStack {
                ForEach(Array(symbols.enumerated()), id: \.offset) { _, s in
                    Text(s)
                        .font(AvaTheme.font(10, weight: .bold))
                        .foregroundStyle(AvaTheme.inkSoft)
                        .frame(maxWidth: .infinity)
                }
            }

            // Day cells with event dots
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 6) {
                ForEach(0..<leadingBlanks, id: \.self) { _ in Color.clear.frame(height: 40) }
                ForEach(1...dayCount, id: \.self) { dayNum in
                    let day = cal.date(byAdding: .day, value: dayNum - 1, to: interval.start) ?? interval.start
                    let hasEvents = store.monthEventDays.contains(cal.startOfDay(for: day))
                    Button {
                        selectedDate = day
                        weekStart = day.startOfWeek
                        loadEvents()
                        withAnimation(.easeInOut(duration: 0.22)) { showMonthGrid = false }
                    } label: {
                        VStack(spacing: 3) {
                            Text("\(dayNum)")
                                .font(AvaTheme.font(14, weight: isSelected(day) ? .heavy : .semibold))
                            Circle()
                                .fill(hasEvents ? AvaTheme.terracotta : Color.clear)
                                .frame(width: 5, height: 5)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .foregroundStyle(isSelected(day) ? .white
                                         : (isToday(day) ? AvaTheme.terracotta : AvaTheme.ink))
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isSelected(day) ? AvaTheme.terracotta : Color.clear)
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 22).fill(AvaTheme.cream))
        .task(id: displayedMonth) {
            guard let userId = auth.currentUserId else { return }
            await store.loadMonthDays(userId: userId, month: displayedMonth)
        }
    }

    private func shiftMonth(_ delta: Int) {
        displayedMonth = Calendar.current.date(byAdding: .month, value: delta, to: displayedMonth) ?? displayedMonth
    }

    private func goToToday() {
        selectedDate = Date()
        weekStart = Date().startOfWeek
        displayedMonth = Date()
        loadEvents()
        withAnimation(.easeInOut(duration: 0.22)) { showMonthGrid = false }
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
