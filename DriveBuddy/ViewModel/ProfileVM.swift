//
//  ProfileVM.swift
//  DriveBuddy
//
//  Created by Student on 05/11/25.
//

import Foundation
import CoreData
import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var addToCalendar: Bool = false
    @Published var isDarkMode: Bool = false

    private let viewContext: NSManagedObjectContext

    init(context: NSManagedObjectContext, user: User?) {
        self.viewContext = context
        self.user = user
        loadProfile()
    }

    // MARK: - Load User Settings
    func loadProfile() {
        guard let user = user else { return }
        addToCalendar = user.add_to_calendar
    }

    // MARK: - Toggle Calendar Option
    func toggleAddToCalendar(_ newValue: Bool) {
        guard let user = user else { return }
        user.add_to_calendar = newValue
        saveContext()
    }

    // MARK: - Save Context
    private func saveContext() {
        do {
            try viewContext.save()
            print("✅ Profile updated successfully.")
        } catch {
            print("❌ Failed to save profile: \(error.localizedDescription)")
        }
    }
}
