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
import UIKit   // untuk UIImage di avatarImage

@MainActor
class ProfileViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var user: User?

    // Settings
    @Published var addToCalendar: Bool = false
    @Published var isDarkMode: Bool = false

    // Profile data (disimpan via UserDefaults untuk sementara)
    @Published var username: String = ""      // full name
    @Published var email: String = ""
    @Published var phoneNumber: String = ""
    @Published var gender: String = ""
    @Published var dateOfBirth: Date? = nil
    @Published var city: String = ""

    // Avatar (foto profil) – juga via UserDefaults
    @Published var avatarData: Data? = nil

    // Messages
    @Published var successMessage: String?
    @Published var errorMessage: String?

    // Core Data context
    private let viewContext: NSManagedObjectContext

    // MARK: - Keys untuk UserDefaults
    private let defaults = UserDefaults.standard
    private enum DefaultsKey {
        static let fullName   = "profile.fullName"
        static let phone      = "profile.phoneNumber"
        static let gender     = "profile.gender"
        static let dob        = "profile.dateOfBirth"
        static let city       = "profile.city"
        static let avatarData = "profile.avatarData"
    }

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
                // Buat user baru kalau belum ada sama sekali (minimal untuk settings)
                let newUser = User(context: viewContext)
                newUser.add_to_calendar = false
                newUser.is_dark_mode = false
                saveContext()
                self.user = newUser
            }
        }

        guard let user = user else { return }

        // Settings dari Core Data
        self.addToCalendar = user.add_to_calendar
        self.isDarkMode    = user.is_dark_mode
        self.email         = user.email ?? ""

        // Profile data dari UserDefaults (belum pakai Core Data supaya tidak error)
        self.username    = defaults.string(forKey: DefaultsKey.fullName) ?? ""
        self.phoneNumber = defaults.string(forKey: DefaultsKey.phone) ?? ""
        self.gender      = defaults.string(forKey: DefaultsKey.gender) ?? ""
        self.city        = defaults.string(forKey: DefaultsKey.city) ?? ""
        if let dob = defaults.object(forKey: DefaultsKey.dob) as? Date {
            self.dateOfBirth = dob
        }

        if let data = defaults.data(forKey: DefaultsKey.avatarData) {
            self.avatarData = data
        }
    }

    // MARK: - Avatar Helper
    var avatarImage: Image? {
        guard let avatarData,
              let uiImage = UIImage(data: avatarData) else {
            return nil
        }
        return Image(uiImage: uiImage)
    }

    func updateAvatar(with data: Data) {
        avatarData = data
        defaults.set(data, forKey: DefaultsKey.avatarData)
    }

    // MARK: - Update Profile Fields (dipakai dari EditProfileView)
    func saveProfileChanges(
        name: String,
        phone: String,
        email: String,
        gender: String,
        dateOfBirth: Date,
        city: String
    ) {
        // Simpan email ke Core Data
        if let user = user {
            user.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
            saveContext()
        }

        // Simpan ke UserDefaults
        defaults.set(name.trimmingCharacters(in: .whitespacesAndNewlines), forKey: DefaultsKey.fullName)
        defaults.set(phone.trimmingCharacters(in: .whitespacesAndNewlines), forKey: DefaultsKey.phone)
        defaults.set(gender, forKey: DefaultsKey.gender)
        defaults.set(city.trimmingCharacters(in: .whitespacesAndNewlines), forKey: DefaultsKey.city)
        defaults.set(dateOfBirth, forKey: DefaultsKey.dob)

        // Update @Published buat refresh UI
        self.username    = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.phoneNumber = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        self.email       = email.trimmingCharacters(in: .whitespacesAndNewlines)
        self.gender      = gender
        self.dateOfBirth = dateOfBirth
        self.city        = city.trimmingCharacters(in: .whitespacesAndNewlines)

        successMessage = "✅ Profile updated successfully!"
    }

    // MARK: - Versi lama (masih bisa dipakai kalau kamu mau call manual)
    func updateProfile() {
        guard let user = user else { return }
        user.email          = email.trimmingCharacters(in: .whitespacesAndNewlines)
        user.add_to_calendar = addToCalendar
        user.is_dark_mode    = isDarkMode
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
