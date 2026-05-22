import SwiftUI
import CoreData

@main
struct Ava_For_MomsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let persistenceController = PersistenceController.shared
    @State private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environment(authManager)
                .onChange(of: authManager.state) { _, newState in
                    // Register for push notifications once authenticated
                    if newState == .authenticated, let userId = authManager.currentUserId {
                        PushNotificationManager.setup(userId: userId)
                    }
                }
        }
    }
}
