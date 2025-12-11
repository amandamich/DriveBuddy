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
        if let phoneFromCoreData = user.phone_number, !phoneFromCoreData.isEmpty {
            self.phoneNumber = phoneFromCoreData
            defaults.set(phoneFromCoreData, forKey: DefaultsKey.phone)
        } else {
            self.phoneNumber = defaults.string(forKey: DefaultsKey.phone) ?? ""
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
    
    // Check current authorization statuses
    func checkPermissionStatuses() async {
        successMessage = nil
        errorMessage = nil
        
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        
        await MainActor.run {
            self.notificationStatus = settings.authorizationStatus
            print("📱 Notification Status: \(settings.authorizationStatus.rawValue)")
        }
        
        let calStatus = EKEventStore.authorizationStatus(for: .event)
        await MainActor.run {
            self.calendarStatus = calStatus
            print("📅 Calendar Status: \(calStatus.rawValue)")
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
    
    func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - 🆕 Notification Settings Toggle (UPDATED)
    
    func toggleTaxReminder(_ enabled: Bool) async {
        successMessage = nil
        errorMessage = nil
        
        if enabled {
            // Check notification permission
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
            
            // Check calendar permission if user wants calendar events
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
            self.defaults.set(enabled, forKey: DefaultsKey.taxReminder)
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
            self.defaults.set(enabled, forKey: DefaultsKey.serviceReminder)
            self.successMessage = enabled ? "Service reminders enabled" : "Service reminders disabled"
        }
    }
    
    // MARK: - 🆕 Calendar Management
    
    func getDriveBuddyCalendar() async throws -> EKCalendar {
        if let existing = eventStore.calendars(for: .event).first(where: { $0.title == "DriveBuddy" }) {
            return existing
        }
        
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
    
    func addCalendarEvent(
        title: String,
        notes: String,
        startDate: Date,
        alarmOffsetDays: Int
    ) async throws {
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
        event.endDate = startDate.addingTimeInterval(60 * 60)
        event.calendar = calendar
        
        let secondsBefore = TimeInterval(alarmOffsetDays * 24 * 60 * 60) * -1
        event.alarms = [EKAlarm(relativeOffset: secondsBefore)]
        
        try eventStore.save(event, span: .thisEvent)
        print("✅ Calendar event saved: \(title)")
    }
    
    // MARK: - 🆕 Tax Reminder with Calendar (UPDATED)
    
    private func scheduleTaxRemindersWithCalendar() async {
        // 1. Schedule notification
        await scheduleTaxReminders()
        
        // 2. Add to calendar if enabled
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
    
    // MARK: - 🆕 Service Reminder with Calendar (UPDATED)
    
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
            
            // Add to calendar if enabled
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
    
    // MARK: - 🆕 Sync All Vehicles to Calendar
    
    func syncAllVehiclesToCalendar() async {
        guard user?.add_to_calendar == true else {
            await MainActor.run {
                self.errorMessage = "Enable 'Add to Calendar' in settings first"
            }
            return
        }

        if calendarStatus != .authorized {
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

            await MainActor.run {
                viewContext.refreshAllObjects()
            }

            // ✅ 1. SYNC TAX DUE DATES (always 7 days - this is fixed)
            let vehicleRequest: NSFetchRequest<Vehicles> = Vehicles.fetchRequest()
            vehicleRequest.predicate = NSPredicate(format: "user.user_id == %@", userId as CVarArg)
            let vehicles = try viewContext.fetch(vehicleRequest)

            for vehicle in vehicles {
                if let taxDate = vehicle.tax_due_date,
                   taxDate > Date(),
                   let vehicleName = vehicle.make_model {
                    
                    try await addCalendarEvent(
                        title: "🚗 Tax Due: \(vehicleName)",
                        notes: "Vehicle tax renewal due for \(vehicleName)",
                        startDate: taxDate,
                        alarmOffsetDays: 7 // Tax reminders are always 7 days
                    )
                    addedCount += 1
                }
            }

            // ✅ 2. SYNC UPCOMING SERVICES WITH USER'S REMINDER PREFERENCE
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

                // ✅ USE STORED REMINDER PREFERENCE (default to 7 if not set)
                let reminderDays = Int(service.reminder_days_before > 0 ? service.reminder_days_before : 7)
                
                print("   - \(serviceName) for \(vehicleName)")
                print("     Date: \(serviceDate)")
                print("     Reminder: \(reminderDays) days before")

                try await addCalendarEvent(
                    title: "🔧 \(serviceName): \(vehicleName)",
                    notes: "Scheduled \(serviceName) for \(vehicleName)\nOdometer: \(Int(service.odometer)) km",
                    startDate: serviceDate,
                    alarmOffsetDays: reminderDays // ✅ USE USER'S SAVED PREFERENCE
                )
                addedCount += 1
                print("     ✅ Added to calendar with \(reminderDays) day reminder")
            }

            await MainActor.run {
                if addedCount > 0 {
                    self.successMessage = "✅ Added \(addedCount) event(s) to calendar"
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
    // Add this to ProfileVM.swift for debugging
    func debugPrintAllServices() async {
        guard let userId = user?.user_id else { return }
        
        let request: NSFetchRequest<ServiceHistory> = ServiceHistory.fetchRequest()
        request.predicate = NSPredicate(format: "vehicle.user.user_id == %@", userId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ServiceHistory.service_date, ascending: false)]
        
        do {
            let services = try viewContext.fetch(request)
            print("\n" + String(repeating: "=", count: 60))
            print("📋 ALL SERVICES IN DATABASE (\(services.count) total):")
            print(String(repeating: "=", count: 60))
            
            for (index, service) in services.enumerated() {
                let isPast = (service.service_date ?? Date()) < Date()
                print("\n\(index + 1). \(service.service_name ?? "NO NAME")")
                print("   Vehicle: \(service.vehicle?.make_model ?? "Unknown")")
                print("   Date: \(service.service_date?.description ?? "nil")")
                print("   Status: [\(isPast ? "✅ PAST" : "🔮 FUTURE")]")
                print("   Odometer: \(service.odometer) km")
                print("   ID: \(service.history_id?.uuidString ?? "nil")")
            }
            print(String(repeating: "=", count: 60) + "\n")
        } catch {
            print("❌ Failed to fetch services: \(error)")
        }
    }
    
    // MARK: - 🆕 Test Notification
    
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
