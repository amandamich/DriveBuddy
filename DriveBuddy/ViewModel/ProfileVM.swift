//
//  ProfileVM.swift
//  DriveBuddy
//
//  Created by Student on 05/11/25.
//

import Foundation
import CoreData
import SwiftUI
import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var user: User?
    @Published var addToCalendar: Bool = false
    @Published var isDarkMode: Bool = true
    @Published var username: String = ""
    @Published var email: String = ""
    @Published var successMessage: String?
    @Published var errorMessage: String?

    private let viewContext: NSManagedObjectContext
    var onLogout: (() -> Void)?

    // MARK: - Init
    init(context: NSManagedObjectContext, user: User? = nil) {
        self.viewContext = context
        self.user = user
        loadProfile()
    }

    // MARK: - Load Profile
    func loadProfile() {
        // Fetch user if nil
        if user == nil {
            let request: NSFetchRequest<User> = User.fetchRequest()
            request.fetchLimit = 1

            if let fetched = try? viewContext.fetch(request).first {
                self.user = fetched
            } else {
                // If no user found, create one
                let newUser = User(context: viewContext)
                newUser.add_to_calendar = false
                newUser.is_dark_mode = true
                saveContext()
                self.user = newUser
            }
        }

        guard let user = user else { return }

        // Load values to ViewModel
        self.email = user.email ?? ""
        self.addToCalendar = user.add_to_calendar
        self.isDarkMode = user.is_dark_mode
    }

    // MARK: - Update Profile
    func updateProfile() {
        guard let user = user else { return }

        user.email = email.trimmingCharacters(in: .whitespaces)
        user.add_to_calendar = addToCalendar
        user.is_dark_mode = isDarkMode

        saveContext()
        successMessage = "Profile updated successfully!"
    }

    // MARK: - Toggle Dark Mode
    func toggleDarkMode(_ newValue: Bool) {
        isDarkMode = newValue
        user?.is_dark_mode = newValue
        saveContext()
    }
    // Logout
    func logout() {
        print("🔥 ProfileViewModel.logout() called")
        onLogout?()   // Call AuthenticationViewModel.logout()
    }

    // MARK: - Save Context Helper
    private func saveContext() {
        do {
            try viewContext.save()
            print("✅ Profile saved")
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
            print("❌ Save error: \(error.localizedDescription)")
        }
    }
}
