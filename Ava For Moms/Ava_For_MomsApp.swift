import SwiftUI
import CoreData

@main
struct Ava_For_MomsApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(authManager)
        }
    }
}
