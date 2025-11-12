//
//  ProfileVM.swift
//  DriveBuddy
//
//  Created by Student on 05/11/25.
//

import Foundation
import CoreData
import Combine
import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var user: User?
    @Published var addToCalendar: Bool = false
    @Published var isDarkMode: Bool = false
    @Published var username: String = ""
    @Published var email: String = ""
    @Published var successMessage: String?
    @Published var errorMessage: String?

    private let viewContext: NSManagedObjectContext

    // MARK: - Init
    init(context: NSManagedObjectContext, user: User? = nil) {
        self.viewContext = context
        self.user = user
        loadProfile()
    }

    // MARK: - Load Profile
    func loadProfile() {
        // Jika user belum diatur, coba ambil dari Core Data
        if user == nil {
            let request: NSFetchRequest<User> = User.fetchRequest()
            request.fetchLimit = 1
            if let fetched = try? viewContext.fetch(request).first {
                self.user = fetched
            } else {
                // Buat user baru kalau belum ada sama sekali
                let newUser = User(context: viewContext)
                newUser.add_to_calendar = false
                saveContext()
                self.user = newUser
            }
        }

        // Ambil nilai dari Core Data
        guard let user = user else { return }
        self.email = user.email ?? ""
        self.addToCalendar = user.add_to_calendar
        self.isDarkMode = user.is_dark_mode
    }

    // MARK: - Update Profile Fields
    func updateProfile() {
        guard let user = user else { return }
        user.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        user.add_to_calendar = addToCalendar
        user.is_dark_mode = isDarkMode
        saveContext()

        successMessage = "✅ Profile updated successfully!"
    }

    // MARK: - Toggle Calendar Option
    func toggleAddToCalendar(_ newValue: Bool) {
        addToCalendar = newValue
        user?.add_to_calendar = newValue
        saveContext()
    }

    // MARK: - Toggle Dark Mode
    func toggleDarkMode(_ newValue: Bool) {
        isDarkMode = newValue
        user?.is_dark_mode = newValue
        saveContext()
    }

    // MARK: - Save Context
    private func saveContext() {
        do {
            try viewContext.save()
            print("✅ Profile changes saved.")
        } catch {
            errorMessage = "❌ Failed to save profile: \(error.localizedDescription)"
            print(errorMessage ?? "")
        }
    }
}
