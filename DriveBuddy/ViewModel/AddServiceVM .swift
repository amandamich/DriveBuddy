//  AddServiceVM.swift
//  DriveBuddy
//
//  Created by Student on 05/11/25.
//

import Foundation
import CoreData
import Combine
import SwiftUI
import EventKit
import UserNotifications

@MainActor
class AddServiceViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var serviceName: String = ""
    @Published var selectedDate: Date = Date()
    @Published var odometer: String = ""
    @Published var reminder: String = "One month before"
    @Published var addToReminder: Bool = true
    @Published var successMessage: String?
    @Published var errorMessage: String?

    // Reminder options
    let reminderOptions = ["One week before", "Two weeks before", "One month before"]

    // MARK: - Core Data
    private let viewContext: NSManagedObjectContext
    private let vehicle: Vehicles

    // MARK: - Init
    init(context: NSManagedObjectContext, vehicle: Vehicles) {
        self.viewContext = context
        self.vehicle = vehicle
    }

    // MARK: - Add Service
    func addService() {
        // Reset messages
        successMessage = nil
        errorMessage = nil

        // Validate inputs
        guard !serviceName.isEmpty else {
            errorMessage = "Please enter the service name."
            return
        }

        guard !odometer.isEmpty, let odometerValue = Double(odometer) else {
            errorMessage = "Please enter a valid odometer value."
            return
        }

        let newService = ServiceHistory(context: viewContext)
        newService.history_id = UUID()
        newService.service_name = serviceName
        newService.service_date = selectedDate
        newService.odometer = odometerValue
        newService.created_at = Date()
        newService.vehicle = vehicle

        do {
            try viewContext.save()
            successMessage = "Service added successfully!"

            if addToReminder {
                // Calendar event (existing behavior)
                addCalendarReminder(for: newService)
                // Local notification (new behavior)
                Task {
                    await requestNotificationPermissionIfNeeded()
                    await scheduleLocalNotification(for: newService)
                }
            }

            clearFields()
        } catch {
            errorMessage = "Failed to save service: \(error.localizedDescription)"
        }
    }

    // MARK: - Add Calendar Reminder (EventKit)
    private func addCalendarReminder(for service: ServiceHistory) {
        let eventStore = EKEventStore()
        eventStore.requestAccess(to: .event) { [weak self] granted, error in
            guard let self = self else { return }

            if granted && error == nil {
                Task { @MainActor in
                    let event = EKEvent(eventStore: eventStore)
                    event.title = "Service Reminder: \(service.service_name ?? "Vehicle Service")"
                    event.notes = """
                    Vehicle: \(self.vehicle.make_model ?? "Unknown")
                    Odometer: \(service.odometer) km
                    """

                    let reminderOffset = self.daysBeforeReminder()
                    let baseDate = service.service_date ?? Date()
                    let reminderDate = Calendar.current.date(byAdding: .day, value: -reminderOffset, to: baseDate) ?? Date()

                    var comps = Calendar.current.dateComponents([.year, .month, .day], from: reminderDate)
                    comps.hour = 9
                    comps.minute = 0
                    let start = Calendar.current.date(from: comps) ?? reminderDate

                    event.startDate = start
                    event.endDate = start.addingTimeInterval(3600)
                    event.calendar = eventStore.defaultCalendarForNewEvents

                    do {
                        try eventStore.save(event, span: .thisEvent)
                        print("✅ Calendar reminder added successfully for \(service.service_name ?? "")")
                    } catch {
                        print("❌ Failed to save calendar event: \(error.localizedDescription)")
                    }
                }
            } else {
                print("⚠️ Calendar permission denied or error: \(error?.localizedDescription ?? "unknown")")
            }
        }
    }

    // MARK: - Local Notifications (UserNotifications)
    private func daysBeforeReminder() -> Int {
        switch reminder {
        case "One week before": return 7
        case "Two weeks before": return 14
        case "One month before": return 30
        default: return 7
        }
    }

    private func notificationIdentifier(for service: ServiceHistory) -> String {
        if let id = service.history_id?.uuidString { return "service.notify." + id }
        return "service.notify." + UUID().uuidString
    }

    private func humanServiceName(_ service: ServiceHistory) -> String {
        let name = service.service_name?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (name?.isEmpty == false) ? name! : "Vehicle Service"
    }

    private func requestNotificationPermissionIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            print("🔔 Local Notification permission granted: \(granted)")
        } catch {
            print("❌ Permission request error: \(error.localizedDescription)")
        }
    }

    /// Schedule a repeating local notification N days before the service date (repeats yearly)
    private func scheduleLocalNotification(for service: ServiceHistory) async {
        let center = UNUserNotificationCenter.current()

        let offsetDays = daysBeforeReminder()
        let base = service.service_date ?? Date()
        let preDate = Calendar.current.date(byAdding: .day, value: -offsetDays, to: base) ?? Date()

        var comps = Calendar.current.dateComponents([.month, .day], from: preDate)
        comps.hour = 9
        comps.minute = 0

        // Create a repeating trigger yearly on same month/day
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)

        let content = UNMutableNotificationContent()
        content.title = "Annual Service Reminder"
        content.body = "Your \(humanServiceName(service)) for \(vehicle.make_model ?? "your vehicle") is coming up again this year."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: notificationIdentifier(for: service),
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            print("✅ Repeating yearly notification scheduled")
        } catch {
            print("❌ Failed to schedule repeating notification: \(error.localizedDescription)")
        }
    }

    // MARK: - Cancel notification helper
    func cancelNotification(for service: ServiceHistory) async {
        let id = notificationIdentifier(for: service)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    // MARK: - Clear Fields
    private func clearFields() {
        serviceName = ""
        selectedDate = Date()
        odometer = ""
        reminder = "One month before"
        addToReminder = true
    }
}
