//
//  DriveBuddyApp.swift
//  DriveBuddy
//

import SwiftUI
import CoreData

@main
struct DriveBuddyApp: App {
    let persistenceController = PersistenceController.shared
    
    @StateObject private var authVM = AuthenticationViewModel(
            context: PersistenceController.shared.container.viewContext
        )
    init() {
            // Set up notification delegate
            UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
            print("✅ Notification delegate registered")
        }
    var body: some Scene {
        WindowGroup {
            ContentView(authVM: authVM)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

