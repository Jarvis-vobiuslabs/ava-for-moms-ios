import UserNotifications
import UIKit
import Supabase

// Requests permission, registers with APNs, and saves the device
// token to Supabase so the morning-brief edge function can reach this device.

enum PushNotificationManager {

    // Call once after the user authenticates — e.g. from MainTabView.onAppear
    static func setup(userId: UUID) {
        _Concurrency.Task { await requestAndRegister(userId: userId) }
    }

    // ── Permission + registration ─────────────────────────────────────────

    private static func requestAndRegister(userId: UUID) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        // Already determined — respect user's choice
        if settings.authorizationStatus == .denied { return }

        if settings.authorizationStatus == .notDetermined {
            let granted = (try? await center.requestAuthorization(
                options: [.alert, .badge, .sound]
            )) ?? false
            guard granted else { return }
        }

        // Register with APNs on main thread
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }

        // Listen for token once
        await listenForToken(userId: userId)
    }

    // ── Token listener ────────────────────────────────────────────────────

    private static func listenForToken(userId: UUID) async {
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            var observer: NSObjectProtocol?
            observer = NotificationCenter.default.addObserver(
                forName: .apnsTokenReceived,
                object: nil,
                queue: .main
            ) { notification in
                guard let token = notification.object as? String else { return }
                if let obs = observer { NotificationCenter.default.removeObserver(obs) }
                _Concurrency.Task { await saveToken(token, userId: userId) }
                cont.resume()
            }
        }
    }

    // ── Save token to Supabase ────────────────────────────────────────────

    static func saveToken(_ token: String, userId: UUID) async {
        let row: [String: AnyJSON] = [
            "user_id":    .string(userId.uuidString),
            "token":      .string(token),
            "updated_at": .string(ISO8601DateFormatter().string(from: Date())),
        ]
        // Upsert — one token per user, updates if already exists
        _ = try? await (try? supabase
            .from("device_tokens")
            .upsert(row, onConflict: "user_id", ignoreDuplicates: false)
        )?.execute()
    }

    // ── Local notification helper (for in-app nudges) ─────────────────────

    static func scheduleLocal(title: String, body: String, inSeconds: TimeInterval = 1) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body  = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, inSeconds), repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }
}
