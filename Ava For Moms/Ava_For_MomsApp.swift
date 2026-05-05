//
//  Ava_For_MomsApp.swift
//  Ava For Moms
//
//  Created by Jarvis Mac Vobius Labs on 2026-05-05.
//

import SwiftUI
import CoreData

@main
struct Ava_For_MomsApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
