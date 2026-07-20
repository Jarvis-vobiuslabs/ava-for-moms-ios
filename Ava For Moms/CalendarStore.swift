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
    @ObservationIgnored private var loadInFlight = false

    // MARK: - Request calendar access

    func requestAccess() async {
        do {
            let granted = try await ekStore.requestFullAccessToEvents()
            calendarAccessGranted = granted
        } catch {
            calendarAccessGranted = false
        }
    }

    // Sync the granted flag from the current authorization status without
    // triggering the system permission prompt (safe to call at launch).
    func refreshAccessStatus() {
        calendarAccessGranted = EKEventStore.authorizationStatus(for: .event) == .fullAccess
    }

    // MARK: - Load events for a given week

    func load(userId: UUID, weekStart: Date) async {
        // Home and Calendar can both trigger a load at launch — running two
        // sync passes concurrently is how duplicate native events get created.
        guard !loadInFlight else { return }
        loadInFlight = true
        isLoading = true
        defer { loadInFlight = false; isLoading = false }

        let weekEnd = Calendar.current.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
        var merged: [AvaCalendarEvent] = []

        // 1. Supabase events (Ava-created) — fetched first so the EventKit
        //    pass can dedupe against them.
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
        let rows: [EventRow] = (try? await supabase
            .from("calendar_events")
            .select("id, title, detail, starts_at, ends_at, color_hex")
            .eq("user_id", value: userId.uuidString)
            .gte("starts_at", value: formatter.string(from: weekStart))
            .lte("starts_at", value: formatter.string(from: weekEnd))
            .order("starts_at", ascending: true)
            .execute()
            .value as [EventRow]) ?? []

        // Fingerprints of Ava events, for deduping native copies that predate
        // the URL-marker scheme (e.g. synced before a reinstall wiped UserDefaults)
        let avaFingerprints = Set(rows.map { fingerprint(title: $0.title, start: $0.startsAt) })

        // 2. EventKit events — skip anything Ava herself put there
        var nativeEvents: [EKEvent] = []
        if calendarAccessGranted {
            let predicate = ekStore.predicateForEvents(withStart: weekStart, end: weekEnd, calendars: nil)
            nativeEvents = ekStore.events(matching: predicate)
            let ourEkIds = createdEkEventIds
            for ek in nativeEvents {
                guard let ekId = ek.eventIdentifier,
                      !ourEkIds.contains(ekId),               // legacy UserDefaults record
                      avaMarkedId(ek) == nil,                 // avaformoms:// URL marker
                      !avaFingerprints.contains(fingerprint(title: ek.title ?? "", start: ek.startDate))
                else { continue }
                merged.append(AvaCalendarEvent(
                    id: UUID(),
                    title: ek.title ?? "Event",
                    detail: ek.location,
                    startsAt: ek.startDate,
                    endsAt: ek.endDate,
                    color: Color(cgColor: ek.calendar.cgColor),
                    source: .eventKit,
                    ekEventID: ekId
                ))
            }
        }

        // 3. Sync Ava events into the native calendar — the URL marker on the
        //    native copy is the durable record, so this stays correct across
        //    reinstalls and devices (unlike the old UserDefaults-only check).
        if calendarAccessGranted, let defaultCal = ekStore.defaultCalendarForNewEvents {
            let alreadySynced = syncedAvaIds
            let markedIds = Set(nativeEvents.compactMap { avaMarkedId($0) })
            for row in rows {
                if markedIds.contains(row.id.uuidString) {
                    markSyncedNativeId(row.id)   // heal the local cache
                    continue
                }
                guard !alreadySynced.contains(row.id.uuidString) else { continue }
                let ek = EKEvent(eventStore: ekStore)
                ek.title = row.title
                ek.notes = row.detail
                ek.startDate = row.startsAt
                ek.endDate = row.endsAt ?? Calendar.current.date(byAdding: .hour, value: 1, to: row.startsAt)!
                ek.calendar = defaultCal
                ek.url = URL(string: "avaformoms://event/\(row.id.uuidString)")
                do {
                    try ekStore.save(ek, span: .thisEvent)
                    markSyncedNativeId(row.id)
                    if let ekId = ek.eventIdentifier, !ekId.isEmpty {
                        markCreatedEkEventId(ekId)
                    }
                } catch {}
            }
        }

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

        // Sort by start time
        events = merged.sorted { $0.startsAt < $1.startsAt }
    }

    // MARK: - Duplicate detection helpers

    // "title|minute-precision start" — used to catch native copies of Ava
    // events that predate the URL-marker scheme
    private func fingerprint(title: String, start: Date) -> String {
        let minute = Int(start.timeIntervalSince1970 / 60)
        return title.trimmingCharacters(in: .whitespaces).lowercased() + "|\(minute)"
    }

    // Returns the Ava event UUID string if this native event was created by
    // Ava (tagged with an avaformoms://event/<id> URL), else nil
    private func avaMarkedId(_ ek: EKEvent) -> String? {
        guard let url = ek.url, url.scheme == "avaformoms" else { return nil }
        return url.lastPathComponent
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
        if addToNativeCalendar && calendarAccessGranted,
           let defaultCal = ekStore.defaultCalendarForNewEvents {
            let ek = EKEvent(eventStore: ekStore)
            ek.title = title
            ek.notes = detail
            ek.startDate = startsAt
            ek.endDate = endsAt
            ek.calendar = defaultCal
            ek.url = URL(string: "avaformoms://event/\(newId.uuidString)")
            do {
                try ekStore.save(ek, span: .thisEvent)
                markSyncedNativeId(newId)
                if let ekId = ek.eventIdentifier, !ekId.isEmpty {
                    markCreatedEkEventId(ekId)
                }
            } catch {}
        }
    }

    // MARK: - Native calendar sync tracking

    private var syncedAvaIds: Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: "ava.syncedNativeIds") ?? [])
    }

    private func markSyncedNativeId(_ id: UUID) {
        var ids = syncedAvaIds
        ids.insert(id.uuidString)
        UserDefaults.standard.set(Array(ids), forKey: "ava.syncedNativeIds")
    }

    private var createdEkEventIds: Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: "ava.createdEkEventIds") ?? [])
    }

    private func markCreatedEkEventId(_ ekId: String) {
        var ids = createdEkEventIds
        ids.insert(ekId)
        UserDefaults.standard.set(Array(ids), forKey: "ava.createdEkEventIds")
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
