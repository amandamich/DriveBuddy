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
    private var currentUserId: String {
        return user?.user_id?.uuidString ?? "default"
    }
    private let defaults = UserDefaults.standard
    // Helper function to get user-specific keys
    private func key(_ baseKey: String) -> String {
        return "\(currentUserId).\(baseKey)"
    }
    private enum DefaultsKey {
        static let fullName   = "profile.fullName"
        static let phone      = "profile.phoneNumber"
        static let gender     = "profile.gender"
        static let dob        = "profile.dateOfBirth"
        static let city       = "profile.city"
        static let avatarData = "profile.avatarData"
        static let taxReminder = "profile.taxReminderEnabled"
        static let serviceReminder = "profile.serviceReminderEnabled"
        static let isGoogleUser = "profile.isGoogleUser"
    }

    // MARK: - Init
    init(context: NSManagedObjectContext, user: User? = nil) {
        self.viewContext = context
        self.user = user
        loadProfile()
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

        // ✅ MODIFIED: Load username from UserDefaults (never from Core Data)
        self.username = defaults.string(forKey: key(DefaultsKey.fullName)) ?? ""
        self.gender = defaults.string(forKey: key(DefaultsKey.gender)) ?? ""
        self.city = defaults.string(forKey: key(DefaultsKey.city)) ?? ""
        self.taxReminderEnabled = defaults.bool(forKey: key(DefaultsKey.taxReminder))
        self.serviceReminderEnabled = defaults.bool(forKey: key(DefaultsKey.serviceReminder))

        if let dob = defaults.object(forKey: key(DefaultsKey.dob)) as? Date {
            self.dateOfBirth = dob
        }
        if let data = defaults.data(forKey: key(DefaultsKey.avatarData)) {
            self.avatarData = data
        }
        let isGoogleUser = defaults.bool(forKey: key(DefaultsKey.isGoogleUser))
        let savedPhone = defaults.string(forKey: key(DefaultsKey.phone))
        if isGoogleUser {
            // Google users: Always start with empty phone unless they saved one
            self.phoneNumber = savedPhone ?? ""
        } else {
            // Email sign-up users: Use saved phone or fallback to Core Data
            if let savedPhone = savedPhone, !savedPhone.isEmpty {
                self.phoneNumber = savedPhone
            } else if let phoneFromCoreData = user.phone_number, !phoneFromCoreData.isEmpty {
                self.phoneNumber = phoneFromCoreData
                defaults.set(phoneFromCoreData, forKey: DefaultsKey.phone)
            } else {
                self.phoneNumber = ""
            }
        }
                print("📱 Loaded profile for user: \(currentUserId)")
                print("   - Name: \(username)")
                print("   - Phone: \(phoneNumber)")
                print("   - isGoogleUser: \(isGoogleUser)")
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
        defaults.set(data, forKey: key(DefaultsKey.avatarData))
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
            user.phone_number = phone.trimmingCharacters(in: .whitespacesAndNewlines)
            saveContext()
        }

        defaults.set(name.trimmingCharacters(in: .whitespacesAndNewlines), forKey: key(DefaultsKey.fullName))
        defaults.set(phone.trimmingCharacters(in: .whitespacesAndNewlines), forKey: key(DefaultsKey.phone))
        defaults.set(gender, forKey: key(DefaultsKey.gender))
        defaults.set(city.trimmingCharacters(in: .whitespacesAndNewlines), forKey: key(DefaultsKey.city))
        defaults.set(dateOfBirth, forKey: key(DefaultsKey.dob))

        self.username    = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.phoneNumber = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        self.email       = email.trimmingCharacters(in: .whitespacesAndNewlines)
        self.gender      = gender
        self.dateOfBirth = dateOfBirth
        self.city        = city.trimmingCharacters(in: .whitespacesAndNewlines)

        NotificationCenter.default.post(name: NSNotification.Name("ProfileUpdated"), object: nil)
        
        successMessage = "✅ Profile updated successfully!"
        print("💾 Saved profile for user: \(currentUserId)")
        print("   - Name: \(name)")
    }
    
    // ✅ NEW: Mark user as Google sign-in user
    func markAsGoogleUser() {
        defaults.set(true, forKey: key(DefaultsKey.isGoogleUser))
        defaults.removeObject(forKey: key(DefaultsKey.phone))
        self.phoneNumber = ""
        print("📱 Marked as Google user - phone cleared")
    }
    
    // ✅ NEW: Mark user as email sign-up user
    func markAsEmailUser() {
        defaults.set(false, forKey: key(DefaultsKey.isGoogleUser))
        print("📧 Marked as email sign-up user")
    }

    // MARK: - 🆕 Permission Management
    
    func checkPermissionStatuses() async {
        successMessage = nil
        errorMessage = nil
        
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        
        await MainActor.run {
            self.notificationStatus = settings.authorizationStatus
            print("📱 Notification Status: \(settings.authorizationStatus.rawValue) (\(statusName(settings.authorizationStatus)))")
        }
        
        if #available(iOS 17.0, *) {
            let calStatus = EKEventStore.authorizationStatus(for: .event)
            await MainActor.run {
                self.calendarStatus = calStatus
                print("📅 Calendar Status: \(calStatus.rawValue) (\(ekStatusName(calStatus)))")
            }
        } else {
            let calStatus = EKEventStore.authorizationStatus(for: .event)
            await MainActor.run {
                self.calendarStatus = calStatus
                print("📅 Calendar Status: \(calStatus.rawValue) (\(ekStatusName(calStatus)))")
            }
        }
    }
    
    private func statusName(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "Not Determined"
        case .denied: return "Denied"
        case .authorized: return "Authorized"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        @unknown default: return "Unknown"
        }
    }

    private func ekStatusName(_ status: EKAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorized: return "Authorized (Deprecated)"
        case .fullAccess: return "Full Access"
        case .writeOnly: return "Write Only"
        @unknown default: return "Unknown"
        }
    }
    
    func requestNotificationPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await checkPermissionStatuses()
            
            if granted {
                print("✅ Notification permission granted")
            } else {
                print("❌ Notification permission denied by user")
                await MainActor.run {
                    self.errorMessage = "Notification permission denied"
                }
            }
            return granted
        } catch {
            print("❌ Notification permission error: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = "Failed to request notification permission"
            }
            return false
        }
    }
    
    func requestCalendarPermission() async -> Bool {
        if #available(iOS 17.0, *) {
            do {
                let granted = try await eventStore.requestFullAccessToEvents()
                await checkPermissionStatuses()
                
                if granted {
                    print("✅ Calendar FULL ACCESS granted")
                    await MainActor.run {
                        self.successMessage = "Calendar access granted"
                    }
                } else {
                    print("❌ Calendar permission denied by user")
                    await MainActor.run {
                        self.errorMessage = "Calendar permission denied"
                    }
                }
                return granted
            } catch {
                print("❌ Calendar permission error: \(error.localizedDescription)")
                await MainActor.run {
                    self.errorMessage = "Failed to request calendar permission: \(error.localizedDescription)"
                }
                return false
            }
        } else {
            do {
                let granted = try await eventStore.requestAccess(to: .event)
                await checkPermissionStatuses()
                
                if granted {
                    print("✅ Calendar permission granted")
                } else {
                    print("❌ Calendar permission denied by user")
                    await MainActor.run {
                        self.errorMessage = "Calendar permission denied"
                    }
                }
                return granted
            } catch {
                print("❌ Calendar permission error: \(error.localizedDescription)")
                await MainActor.run {
                    self.errorMessage = "Failed to request calendar permission"
                }
                return false
            }
        }
    }
    
    func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - 🆕 Notification Settings Toggle
    
    func toggleTaxReminder(_ enabled: Bool) async {
        successMessage = nil
        errorMessage = nil
        
        if enabled {
            if notificationStatus != .authorized {
                let granted = await requestNotificationPermission()
                if !granted {
                    await MainActor.run {
                        self.taxReminderEnabled = false
                        self.errorMessage = "Please enable notifications in Settings"
                    }
                    return
                }
            }
            
            if user?.add_to_calendar == true && calendarStatus != .authorized {
                let granted = await requestCalendarPermission()
                if !granted {
                    await MainActor.run {
                        self.errorMessage = "Calendar permission needed to add events"
                    }
                }
            }
        }
        
        await MainActor.run {
            self.taxReminderEnabled = enabled
            self.defaults.set(enabled, forKey: key(DefaultsKey.taxReminder))
        }
        
        if enabled {
            await scheduleTaxRemindersWithCalendar()
        } else {
            await cancelTaxReminders()
        }
    }
    
    func toggleServiceReminder(_ enabled: Bool) async {
        successMessage = nil
        errorMessage = nil
        
        if enabled && notificationStatus != .authorized {
            let granted = await requestNotificationPermission()
            if !granted {
                await MainActor.run {
                    self.serviceReminderEnabled = false
                    self.errorMessage = "Please enable notifications in Settings"
                }
                return
            }
        }
        
        await MainActor.run {
            self.serviceReminderEnabled = enabled
            self.defaults.set(enabled, forKey: key(DefaultsKey.serviceReminder))
            self.successMessage = enabled ? "Service reminders enabled" : "Service reminders disabled"
        }
    }
    
    // MARK: - 🆕 Calendar Management
    func getDriveBuddyCalendar() async throws -> EKCalendar {
        let currentStatus: EKAuthorizationStatus
        if #available(iOS 17.0, *) {
            currentStatus = EKEventStore.authorizationStatus(for: .event)
            if currentStatus != .fullAccess {
                print("❌ Calendar access not granted. Status: \(ekStatusName(currentStatus))")
                throw NSError(
                    domain: "DriveBuddy",
                    code: 3,
                    userInfo: [NSLocalizedDescriptionKey: "Calendar access not granted"]
                )
            }
        } else {
            currentStatus = EKEventStore.authorizationStatus(for: .event)
            if currentStatus != .authorized {
                print("❌ Calendar access not granted. Status: \(ekStatusName(currentStatus))")
                throw NSError(
                    domain: "DriveBuddy",
                    code: 3,
                    userInfo: [NSLocalizedDescriptionKey: "Calendar access not granted"]
                )
            }
        }
        
        if let existing = eventStore.calendars(for: .event).first(where: { $0.title == "DriveBuddy" }) {
            print("✅ Found existing DriveBuddy calendar")
            return existing
        }
        
        let sources = eventStore.sources
        print("📋 Available calendar sources: \(sources.map { "\($0.title) (\($0.sourceType.rawValue))" })")
        
        guard let source = sources.first(where: { $0.sourceType == .local })
               ?? sources.first(where: { $0.sourceType == .calDAV })
               ?? sources.first else {
            print("❌ No writable calendar source found")
            throw NSError(
                domain: "DriveBuddy",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "No writable calendar source found"]
            )
        }
        
        print("📝 Creating calendar with source: \(source.title)")
        
        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        calendar.title = "DriveBuddy"
        calendar.source = source
        
        if #available(iOS 14.0, *) {
            calendar.cgColor = UIColor.systemCyan.cgColor
        } else {
            calendar.cgColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0).cgColor
        }
        
        do {
            try eventStore.saveCalendar(calendar, commit: true)
            print("✅ Created DriveBuddy calendar successfully")
            return calendar
        } catch {
            print("❌ Failed to create calendar: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Tax & Service Reminders (remaining methods unchanged)
    
    private func scheduleTaxRemindersWithCalendar() async {
        await scheduleTaxReminders()
        
        if user?.add_to_calendar == true && calendarStatus == .authorized {
            do {
                guard let userId = user?.user_id else { return }
                
                let request: NSFetchRequest<Vehicles> = Vehicles.fetchRequest()
                request.predicate = NSPredicate(format: "user.user_id == %@", userId as CVarArg)
                
                let vehicles = try viewContext.fetch(request)
                
                for vehicle in vehicles {
                    guard let taxDate = vehicle.tax_due_date,
                          let vehicleName = vehicle.make_model else { continue }
                    
                    try await addCalendarEvent(
                        title: "🚗 Tax Due: \(vehicleName)",
                        notes: "Vehicle tax renewal due for \(vehicleName)",
                        startDate: taxDate,
                        alarmOffsetDays: 7
                    )
                }
                
                await MainActor.run {
                    self.successMessage = "Tax reminders enabled and added to calendar"
                }
            } catch {
                print("❌ Failed to add tax events to calendar: \(error.localizedDescription)")
                await MainActor.run {
                    self.errorMessage = "Failed to add some events to calendar"
                }
            }
        }
    }
    
    private func scheduleTaxReminders() async {
        let center = UNUserNotificationCenter.current()
        
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
        } catch {
            print("❌ Failed to schedule tax reminder: \(error.localizedDescription)")
        }
    }
    
    private func cancelTaxReminders() async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["tax.reminder.yearly"])
        print("✅ Tax reminder cancelled")
        await MainActor.run {
            self.successMessage = "Tax reminders disabled"
        }
    }
    
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
        
        var components = Calendar.current.dateComponents([.year, .month, .day], from: preDate)
        components.hour = 9
        components.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
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
            print("✅ Service reminder notification scheduled for \(serviceName)")
            
            if user?.add_to_calendar == true && calendarStatus == .authorized {
                try await addCalendarEvent(
                    title: "🔧 Service: \(serviceName)",
                    notes: "Scheduled service for \(vehicleName): \(serviceName)",
                    startDate: serviceDate,
                    alarmOffsetDays: daysBeforeReminder
                )
                print("✅ Service event added to calendar")
            }
        } catch {
            print("❌ Failed to schedule service reminder: \(error.localizedDescription)")
        }
    }
    
    func cancelServiceReminder(serviceId: UUID) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(
            withIdentifiers: ["service.reminder.\(serviceId.uuidString)"]
        )
        print("✅ Service reminder cancelled")
    }
    
    func syncAllVehiclesToCalendar() async {
        guard user?.add_to_calendar == true else {
            await MainActor.run {
                self.errorMessage = "Enable 'Add to Calendar' in settings first"
            }
            return
        }

        if calendarStatus != .authorized && calendarStatus != .fullAccess {
            let granted = await requestCalendarPermission()
            guard granted else {
                await MainActor.run {
                    self.errorMessage = "Calendar permission denied"
                }
                return
            }
        }

        do {
            guard let userId = user?.user_id else { return }
            var addedCount = 0
            var skippedCount = 0

            await MainActor.run {
                viewContext.refreshAllObjects()
            }

            let vehicleRequest: NSFetchRequest<Vehicles> = Vehicles.fetchRequest()
            vehicleRequest.predicate = NSPredicate(format: "user.user_id == %@", userId as CVarArg)
            let vehicles = try viewContext.fetch(vehicleRequest)

            for vehicle in vehicles {
                if let taxDate = vehicle.tax_due_date,
                   taxDate > Date(),
                   let vehicleName = vehicle.make_model {
                    
                    let title = "🚗 Tax Due: \(vehicleName)"
                    
                    if await eventExists(title: title, startDate: taxDate) {
                        print("⚠️ Skipping duplicate: \(title)")
                        skippedCount += 1
                        continue
                    }
                    
                    try await addCalendarEvent(
                        title: title,
                        notes: "Vehicle tax renewal due for \(vehicleName)",
                        startDate: taxDate,
                        alarmOffsetDays: 7
                    )
                    addedCount += 1
                }
            }

            let serviceRequest: NSFetchRequest<ServiceHistory> = ServiceHistory.fetchRequest()
            serviceRequest.predicate = NSPredicate(
                format: "vehicle.user.user_id == %@ AND service_date > %@",
                userId as CVarArg,
                Date() as CVarArg
            )
            serviceRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ServiceHistory.service_date, ascending: true)]
            
            let upcomingServices = try viewContext.fetch(serviceRequest)

            print("\n📋 Found \(upcomingServices.count) upcoming services:")
            for service in upcomingServices {
                guard let serviceDate = service.service_date,
                      let vehicleName = service.vehicle?.make_model,
                      let serviceName = service.service_name else {
                    continue
                }

                let reminderDays = Int(service.reminder_days_before > 0 ? service.reminder_days_before : 7)
                let title = "🔧 \(serviceName): \(vehicleName)"
                
                print("   - \(serviceName) for \(vehicleName)")
                print("     Date: \(serviceDate)")
                print("     Reminder: \(reminderDays) days before")

                if await eventExists(title: title, startDate: serviceDate) {
                    print("     ⚠️ Already in calendar, skipping")
                    skippedCount += 1
                    continue
                }

                try await addCalendarEvent(
                    title: title,
                    notes: "Scheduled \(serviceName) for \(vehicleName)\nOdometer: \(Int(service.odometer)) km",
                    startDate: serviceDate,
                    alarmOffsetDays: reminderDays
                )
                addedCount += 1
                print("     ✅ Added to calendar with \(reminderDays) day reminder")
            }

            await MainActor.run {
                if addedCount > 0 && skippedCount > 0 {
                    self.successMessage = "✅ Added \(addedCount) new event(s), \(skippedCount) already existed"
                } else if addedCount > 0 {
                    self.successMessage = "✅ Added \(addedCount) event(s) to calendar"
                } else if skippedCount > 0 {
                    self.successMessage = "ℹ️ All \(skippedCount) event(s) already in calendar"
                } else {
                    self.successMessage = "ℹ️ No upcoming events to add"
                }
            }
            
        } catch {
            print("❌ Failed to sync to calendar: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = "Failed to sync to calendar"
            }
        }
    }
    
    func addCalendarEvent(
        title: String,
        notes: String,
        startDate: Date,
        alarmOffsetDays: Int
    ) async throws {
        let currentStatus: EKAuthorizationStatus
        if #available(iOS 17.0, *) {
            currentStatus = EKEventStore.authorizationStatus(for: .event)
            if currentStatus != .fullAccess {
                let granted = await requestCalendarPermission()
                guard granted else {
                    throw NSError(
                        domain: "DriveBuddy",
                        code: 2,
                        userInfo: [NSLocalizedDescriptionKey: "Calendar permission denied"]
                    )
                }
            }
        } else {
            currentStatus = EKEventStore.authorizationStatus(for: .event)
            if currentStatus != .authorized {
                let granted = await requestCalendarPermission()
                guard granted else {
                    throw NSError(
                        domain: "DriveBuddy",
                        code: 2,
                        userInfo: [NSLocalizedDescriptionKey: "Calendar permission denied"]
                    )
                }
            }
        }
        
        if await eventExists(title: title, startDate: startDate) {
            print("⚠️ Event already exists: \(title)")
            return
        }
        
        let calendar = try await getDriveBuddyCalendar()
        
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.notes = notes
        event.startDate = startDate
        event.endDate = startDate.addingTimeInterval(60 * 60)
        event.calendar = calendar
        
        let secondsBefore = TimeInterval(alarmOffsetDays * 24 * 60 * 60) * -1
        event.alarms = [EKAlarm(relativeOffset: secondsBefore)]
        
        do {
            try eventStore.save(event, span: .thisEvent, commit: true)
            print("✅ Calendar event saved: \(title)")
        } catch {
            print("❌ Failed to save event '\(title)': \(error.localizedDescription)")
            throw error
        }
    }
    
    func sendTestNotification() async {
        successMessage = nil
        errorMessage = nil
        
        if notificationStatus != .authorized {
            let granted = await requestNotificationPermission()
            if !granted {
                await MainActor.run {
                    self.errorMessage = "Please enable notifications first"
                }
                return
            }
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "This is a test notification from DriveBuddy 🚗"
        content.sound = .default
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        let center = UNUserNotificationCenter.current()
        do {
            try await center.add(request)
            print("✅ Test notification scheduled in 1 second")
            await MainActor.run {
                self.successMessage = "Test notification scheduled! It will appear even if app is open."
            }
        } catch {
            print("❌ Failed to schedule test notification: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = "Failed to send test notification: \(error.localizedDescription)"
            }
        }
    }
    
    func removeAllCalendarEvents() async {
        guard calendarStatus == .authorized || calendarStatus == .fullAccess else {
            print("⚠️ No calendar access to remove events")
            return
        }
        
        do {
            let calendar = try await getDriveBuddyCalendar()
            
            let now = Date()
            let oneYearFromNow = Calendar.current.date(byAdding: .year, value: 1, to: now)!
            let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: now)!
            
            let predicate = eventStore.predicateForEvents(
                withStart: oneYearAgo,
                end: oneYearFromNow,
                calendars: [calendar]
            )
            
            let events = eventStore.events(matching: predicate)
            
            for event in events {
                try eventStore.remove(event, span: .thisEvent, commit: false)
            }
            
            try eventStore.commit()
            
            await MainActor.run {
                self.successMessage = "✅ Removed \(events.count) event(s) from calendar"
            }
            print("✅ Removed \(events.count) calendar events")
            
        } catch {
            print("❌ Failed to remove calendar events: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = "Failed to remove some calendar events"
            }
        }
    }
  
    private func eventExists(title: String, startDate: Date) async -> Bool {
        let currentStatus: EKAuthorizationStatus
        if #available(iOS 17.0, *) {
            currentStatus = EKEventStore.authorizationStatus(for: .event)
            if currentStatus != .fullAccess {
                return false
            }
        } else {
            currentStatus = EKEventStore.authorizationStatus(for: .event)
            if currentStatus != .authorized {
                return false
            }
        }
        
        do {
            let calendar = try await getDriveBuddyCalendar()
            
            let dayBefore = Calendar.current.date(byAdding: .day, value: -1, to: startDate)!
            let dayAfter = Calendar.current.date(byAdding: .day, value: 1, to: startDate)!
            
            let predicate = eventStore.predicateForEvents(
                withStart: dayBefore,
                end: dayAfter,
                calendars: [calendar]
            )
            
            let events = eventStore.events(matching: predicate)
            
            return events.contains { $0.title == title }
            
        } catch {
            print("❌ Failed to check for existing event: \(error.localizedDescription)")
            return false
        }
    }
    
    func toggleAddToCalendar(_ newValue: Bool) {
        addToCalendar = newValue
        user?.add_to_calendar = newValue
        saveContext()
        
        if !newValue {
            Task {
                await removeAllCalendarEvents()
            }
        }
    }

    func toggleDarkMode(_ newValue: Bool) {
        isDarkMode = newValue
        saveContext()
    }
    
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
