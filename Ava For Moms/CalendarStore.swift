import EventKit
import SwiftUI
import Supabase

// MARK: - Merged calendar event model

struct AvaCalendarEvent: Identifiable {
    let id: UUID
    let title: String
    let detail: String?
    let startsAt: Date
    let endsAt: Date?
    let color: Color
    let source: Source
    var ekEventID: String?  // EventKit identifier if from native calendar

    enum Source { case ava, eventKit }

    var timeString: String {
        startsAt.formatted(.dateTime.hour().minute())
    }
}

// MARK: - CalendarStore

@Observable
final class CalendarStore {

    var events: [AvaCalendarEvent] = []
    var isLoading = false
    var calendarAccessGranted = false

    @ObservationIgnored private let ekStore = EKEventStore()

    // MARK: - Request calendar access

    func requestAccess() async {
        do {
            let granted = try await ekStore.requestFullAccessToEvents()
            calendarAccessGranted = granted
        } catch {
            calendarAccessGranted = false
        }
    }

    // MARK: - Load events for a given week

    func load(userId: UUID, weekStart: Date) async {
        isLoading = true
        defer { isLoading = false }

        let weekEnd = Calendar.current.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
        var merged: [AvaCalendarEvent] = []

        // 1. EventKit events
        if calendarAccessGranted {
            let predicate = ekStore.predicateForEvents(withStart: weekStart, end: weekEnd, calendars: nil)
            let ekEvents = ekStore.events(matching: predicate)
            for ek in ekEvents {
                merged.append(AvaCalendarEvent(
                    id: UUID(),
                    title: ek.title ?? "Event",
                    detail: ek.location,
                    startsAt: ek.startDate,
                    endsAt: ek.endDate,
                    color: Color(cgColor: ek.calendar.cgColor),
                    source: .eventKit,
                    ekEventID: ek.eventIdentifier
                ))
            }
        }

        // 2. Supabase events (Ava-created)
        struct EventRow: Decodable {
            let id: UUID
            let title: String
            let detail: String?
            let startsAt: Date
            let endsAt: Date?
            let colorHex: String?
            enum CodingKeys: String, CodingKey {
                case id, title, detail
                case startsAt  = "starts_at"
                case endsAt    = "ends_at"
                case colorHex  = "color_hex"
            }
        }

        let formatter = ISO8601DateFormatter()
        if let rows = try? await supabase
            .from("calendar_events")
            .select("id, title, detail, starts_at, ends_at, color_hex")
            .eq("user_id", value: userId.uuidString)
            .gte("starts_at", value: formatter.string(from: weekStart))
            .lte("starts_at", value: formatter.string(from: weekEnd))
            .order("starts_at", ascending: true)
            .execute()
            .value as [EventRow] {

            for row in rows {
                let color = row.colorHex.map { Color(hex: $0) } ?? AvaTheme.terracotta
                merged.append(AvaCalendarEvent(
                    id: row.id,
                    title: row.title,
                    detail: row.detail,
                    startsAt: row.startsAt,
                    endsAt: row.endsAt,
                    color: color,
                    source: .ava
                ))
            }
        }

        // Sort by start time
        events = merged.sorted { $0.startsAt < $1.startsAt }
    }

    // MARK: - Events for a specific day

    func events(on date: Date) -> [AvaCalendarEvent] {
        events.filter { Calendar.current.isDate($0.startsAt, inSameDayAs: date) }
    }

    // MARK: - Create event

    func createEvent(
        title: String,
        detail: String?,
        startsAt: Date,
        endsAt: Date,
        addToNativeCalendar: Bool,
        userId: UUID
    ) async {
        let newId = UUID()

        // Optimistic local add
        let newEvent = AvaCalendarEvent(
            id: newId,
            title: title,
            detail: detail,
            startsAt: startsAt,
            endsAt: endsAt,
            color: AvaTheme.terracotta,
            source: .ava
        )
        events.append(newEvent)
        events.sort { $0.startsAt < $1.startsAt }

        // Save to Supabase
        let formatter = ISO8601DateFormatter()
        var row: [String: AnyJSON] = [
            "id":        .string(newId.uuidString),
            "user_id":   .string(userId.uuidString),
            "title":     .string(title),
            "starts_at": .string(formatter.string(from: startsAt)),
            "ends_at":   .string(formatter.string(from: endsAt)),
            "source":    .string("manual"),
            "color_hex": .string("#D46A47"),
        ]
        if let detail, !detail.isEmpty { row["detail"] = .string(detail) }
        _ = try? await (try? supabase.from("calendar_events").insert(row, returning: .minimal))?.execute()

        // Optionally add to native iOS Calendar
        if addToNativeCalendar && calendarAccessGranted {
            let ek = EKEvent(eventStore: ekStore)
            ek.title = title
            ek.notes = detail
            ek.startDate = startsAt
            ek.endDate = endsAt
            ek.calendar = ekStore.defaultCalendarForNewEvents
            _ = try? ekStore.save(ek, span: .thisEvent)
        }
    }

    // MARK: - Delete event

    func delete(_ event: AvaCalendarEvent, userId: UUID) async {
        events.removeAll { $0.id == event.id }

        if event.source == .ava {
            _ = try? await supabase.from("calendar_events").delete(returning: .minimal)
                .eq("id", value: event.id.uuidString).execute()
        }

        // Remove from native calendar if it has an EventKit ID
        if let ekId = event.ekEventID,
           let ek = ekStore.event(withIdentifier: ekId) {
            _ = try? ekStore.remove(ek, span: .thisEvent)
        }
    }
}

// MARK: - Helpers

extension Date {
    var startOfWeek: Date {
        Calendar.current.dateInterval(of: .weekOfYear, for: self)?.start ?? self
    }
}
