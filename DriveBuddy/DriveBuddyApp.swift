//
//  DriveBuddyApp.swift
//  DriveBuddy
//

import SwiftUI
import CoreData

@main
struct DriveBuddyApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

