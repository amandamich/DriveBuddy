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
import UIKit
import EventKit
import UserNotifications

@MainActor
class ProfileViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var user: User?

    // Settings
    @Published var addToCalendar: Bool = false
    @Published var isDarkMode: Bool = true
    
    // 🆕 Notification Settings
    @Published var taxReminderEnabled: Bool = false
    @Published var serviceReminderEnabled: Bool = false
    @Published var notificationStatus: UNAuthorizationStatus = .notDetermined
    @Published var calendarStatus: EKAuthorizationStatus = .notDetermined

    // Profile data (disimpan via UserDefaults untuk sementara)
    @Published var username: String = ""
    @Published var email: String = ""
    @Published var phoneNumber: String = ""
    @Published var gender: String = ""
    @Published var dateOfBirth: Date? = nil
    @Published var city: String = ""

    // Avatar (foto profil)
    @Published var avatarData: Data? = nil

    // Messages
    @Published var successMessage: String?
    @Published var errorMessage: String?

    // Core Data context
    private let viewContext: NSManagedObjectContext
    
    // 🆕 EventKit Store
    private let eventStore = EKEventStore()

    // MARK: - Keys untuk UserDefaults
    private let defaults = UserDefaults.standard
    private enum DefaultsKey {
        static let fullName   = "profile.fullName"
        static let phone      = "profile.phoneNumber"
        static let gender     = "profile.gender"
        static let dob        = "profile.dateOfBirth"
        static let city       = "profile.city"
        static let avatarData = "profile.avatarData"
        static let taxReminder = "profile.taxReminderEnabled"
        static let serviceReminder = "profile.serviceReminderEnabled"
    }

    // MARK: - Init
    init(context: NSManagedObjectContext, user: User? = nil) {
        self.viewContext = context
        self.user = user
        loadProfile()
        Task {
            await checkPermissionStatuses()
        }
    }

    // MARK: - Load Profile
    func loadProfile() {
        if user == nil {
            let request: NSFetchRequest<User> = User.fetchRequest()
            request.fetchLimit = 1

            if let fetched = try? viewContext.fetch(request).first {
                self.user = fetched
            } else {
                let newUser = User(context: viewContext)
                newUser.add_to_calendar = false
                saveContext()
                self.user = newUser
            }
        }

        guard let user = user else { return }

        self.addToCalendar = user.add_to_calendar
        self.email         = user.email ?? ""

        self.username    = defaults.string(forKey: DefaultsKey.fullName) ?? ""
        self.phoneNumber = defaults.string(forKey: DefaultsKey.phone) ?? ""
        self.gender      = defaults.string(forKey: DefaultsKey.gender) ?? ""
        self.city        = defaults.string(forKey: DefaultsKey.city) ?? ""
        
        self.taxReminderEnabled = defaults.bool(forKey: DefaultsKey.taxReminder)
        self.serviceReminderEnabled = defaults.bool(forKey: DefaultsKey.serviceReminder)
        
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

    // MARK: - Update Profile Fields
    func saveProfileChanges(
        name: String,
        phone: String,
        email: String,
        gender: String,
        dateOfBirth: Date,
        city: String
    ) {
        if let user = user {
            user.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
            saveContext()
        }

        defaults.set(name.trimmingCharacters(in: .whitespacesAndNewlines), forKey: DefaultsKey.fullName)
        defaults.set(phone.trimmingCharacters(in: .whitespacesAndNewlines), forKey: DefaultsKey.phone)
        defaults.set(gender, forKey: DefaultsKey.gender)
        defaults.set(city.trimmingCharacters(in: .whitespacesAndNewlines), forKey: DefaultsKey.city)
        defaults.set(dateOfBirth, forKey: DefaultsKey.dob)

        self.username    = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.phoneNumber = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        self.email       = email.trimmingCharacters(in: .whitespacesAndNewlines)
        self.gender      = gender
        self.dateOfBirth = dateOfBirth
        self.city        = city.trimmingCharacters(in: .whitespacesAndNewlines)

        successMessage = "✅ Profile updated successfully!"
    }

    // MARK: - 🆕 Permission Management
    
    /// Check current authorization statuses
    func checkPermissionStatuses() async {
        // Check notification permission
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        notificationStatus = settings.authorizationStatus
        
        // Check calendar permission
        calendarStatus = EKEventStore.authorizationStatus(for: .event)
    }
    
    //Request notification permission
    func requestNotificationPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await checkPermissionStatuses()
            return granted
        } catch {
            print("❌ Notification permission error: \(error.localizedDescription)")
            errorMessage = "Failed to request notification permission"
            return false
        }
    }
    
    /// Request calendar permission
    func requestCalendarPermission() async -> Bool {
        do {
            let granted = try await eventStore.requestAccess(to: .event)
            await checkPermissionStatuses()
            return granted
        } catch {
            print("❌ Calendar permission error: \(error.localizedDescription)")
            errorMessage = "Failed to request calendar permission"
            return false
        }
    }
    
    /// Open app settings
    func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - 🆕 Notification Settings Toggle
    
    func toggleTaxReminder(_ enabled: Bool) async {
        // Check permission first
        if enabled && notificationStatus != .authorized {
            let granted = await requestNotificationPermission()
            if !granted {
                taxReminderEnabled = false
                errorMessage = "Please enable notifications in Settings"
                return
            }
        }
        
        taxReminderEnabled = enabled
        defaults.set(enabled, forKey: DefaultsKey.taxReminder)
        
        if enabled {
            await scheduleTaxReminders()
        } else {
            await cancelTaxReminders()
        }
    }
    
    func toggleServiceReminder(_ enabled: Bool) async {
        if enabled && notificationStatus != .authorized {
            let granted = await requestNotificationPermission()
            if !granted {
                serviceReminderEnabled = false
                errorMessage = "Please enable notifications in Settings"
                return
            }
        }
        
        serviceReminderEnabled = enabled
        defaults.set(enabled, forKey: DefaultsKey.serviceReminder)
        
        // Service reminders are handled per-service, so just save the preference
        successMessage = enabled ? "Service reminders enabled" : "Service reminders disabled"
    }
    
    // MARK: - 🆕 Calendar Management
    
    /// Get or create DriveBuddy calendar
    func getDriveBuddyCalendar() async throws -> EKCalendar {
        // Try to find existing calendar
        if let existing = eventStore.calendars(for: .event).first(where: { $0.title == "DriveBuddy" }) {
            return existing
        }
        
        // Create new calendar
        guard let source = eventStore.sources.first(where: { $0.sourceType == .local })
               ?? eventStore.sources.first(where: { $0.sourceType == .calDAV }) else {
            throw NSError(
                domain: "DriveBuddy",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "No writable calendar source found"]
            )
        }
        
        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        calendar.title = "DriveBuddy"
        calendar.source = source
        calendar.cgColor = UIColor.systemCyan.cgColor
        
        try eventStore.saveCalendar(calendar, commit: true)
        print("✅ Created DriveBuddy calendar")
        return calendar
    }
    
    /// Add event to calendar
    func addCalendarEvent(
        title: String,
        notes: String,
        startDate: Date,
        alarmOffsetDays: Int
    ) async throws {
        // Check permission
        if calendarStatus != .authorized {
            let granted = await requestCalendarPermission()
            guard granted else {
                throw NSError(
                    domain: "DriveBuddy",
                    code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "Calendar permission denied"]
                )
            }
        }
        
        let calendar = try await getDriveBuddyCalendar()
        
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.notes = notes
        event.startDate = startDate
        event.endDate = startDate.addingTimeInterval(60 * 60) // 1 hour
        event.calendar = calendar
        
        // Add alarm
        let secondsBefore = TimeInterval(alarmOffsetDays * 24 * 60 * 60) * -1
        event.alarms = [EKAlarm(relativeOffset: secondsBefore)]
        
        try eventStore.save(event, span: .thisEvent)
        print("✅ Calendar event saved: \(title)")
    }
    
    // MARK: - 🆕 Tax Reminder Notifications
    
    /// Schedule yearly tax reminders (every year on a specific date)
    private func scheduleTaxReminders() async {
        let center = UNUserNotificationCenter.current()
        
        // Example: Schedule tax reminder for March 1st every year at 9:00 AM
        var components = DateComponents()
        components.month = 3
        components.day = 1
        components.hour = 9
        components.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let content = UNMutableNotificationContent()
        content.title = "Vehicle Tax Reminder"
        content.body = "Don't forget to renew your vehicle tax this month!"
        content.sound = .default
        content.badge = 1
        
        let request = UNNotificationRequest(
            identifier: "tax.reminder.yearly",
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
            print("✅ Tax reminder notification scheduled")
            successMessage = "Tax reminders enabled"
        } catch {
            print("❌ Failed to schedule tax reminder: \(error.localizedDescription)")
            errorMessage = "Failed to schedule tax reminder"
        }
    }
    
    /// Cancel tax reminders
    private func cancelTaxReminders() async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["tax.reminder.yearly"])
        print("✅ Tax reminder cancelled")
        successMessage = "Tax reminders disabled"
    }
    
    // MARK: - 🆕 Service Reminder Helpers (to be used by AddServiceViewModel)
    
    /// Schedule a service reminder notification
    func scheduleServiceReminder(
        serviceId: UUID,
        serviceName: String,
        vehicleName: String,
        serviceDate: Date,
        daysBeforeReminder: Int
    ) async {
        guard serviceReminderEnabled else { return }
        
        let center = UNUserNotificationCenter.current()
        
        let preDate = Calendar.current.date(
            byAdding: .day,
            value: -daysBeforeReminder,
            to: serviceDate
        ) ?? Date()
        
        var components = Calendar.current.dateComponents([.month, .day], from: preDate)
        components.hour = 9
        components.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let content = UNMutableNotificationContent()
        content.title = "Service Reminder"
        content.body = "Your \(serviceName) for \(vehicleName) is coming up soon."
        content.sound = .default
        content.badge = 1
        
        let request = UNNotificationRequest(
            identifier: "service.reminder.\(serviceId.uuidString)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
            print("✅ Service reminder scheduled for \(serviceName)")
        } catch {
            print("❌ Failed to schedule service reminder: \(error.localizedDescription)")
        }
    }
    
    /// Cancel a service reminder
    func cancelServiceReminder(serviceId: UUID) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(
            withIdentifiers: ["service.reminder.\(serviceId.uuidString)"]
        )
        print("✅ Service reminder cancelled")
    }
    
    // MARK: - 🆕 Test Notification (for debugging)
    func sendTestNotification() async {
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "This is a test notification from DriveBuddy 🚗"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        let center = UNUserNotificationCenter.current()
        do {
            try await center.add(request)
            print("✅ Test notification scheduled in 5 seconds")
            successMessage = "Test notification will appear in 5 seconds"
        } catch {
            print("❌ Failed to schedule test notification: \(error.localizedDescription)")
            errorMessage = "Failed to send test notification"
        }
    }

    // MARK: - Toggle Settings
    func toggleAddToCalendar(_ newValue: Bool) {
        addToCalendar = newValue
        user?.add_to_calendar = newValue
        saveContext()
    }

    func toggleDarkMode(_ newValue: Bool) {
        isDarkMode = newValue
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
