import SwiftUI
import CoreData

@main
struct Ava_For_MomsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let persistenceController = PersistenceController.shared
    @State private var authManager = AuthManager()
    @State private var subscriptionManager = SubscriptionManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environment(authManager)
                .environment(subscriptionManager)
                .preferredColorScheme(.light)
                .onChange(of: authManager.state) { _, newState in
                    if newState == .authenticated {
                        // Set up push notifications
                        if let userId = authManager.currentUserId {
                            PushNotificationManager.setup(userId: userId)
                        }
                        // Check subscription entitlements
                        _Concurrency.Task { await subscriptionManager.refreshEntitlements() }
                    }
                }
        }
    }
}
