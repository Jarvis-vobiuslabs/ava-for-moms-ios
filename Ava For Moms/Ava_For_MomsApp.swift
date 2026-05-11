import SwiftUI
import CoreData

@main
struct Ava_For_MomsApp: App {
    let persistenceController = PersistenceController.shared
    @State private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environment(authManager)
        }
    }
}
