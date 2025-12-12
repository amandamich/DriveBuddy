import Foundation
import CoreData
import Combine
import SwiftUI

@MainActor
class AddServiceViewModel: ObservableObject {

    @Published var serviceName: String = ""
    @Published var selectedDate: Date = Date()
    @Published var odometer: String = ""
    @Published var reminder: String = "One month before"
    @Published var addToReminder: Bool = true

    @Published var successMessage: String?
    @Published var errorMessage: String?

    let reminderOptions = ["One week before", "Two weeks before", "One month before"]

    private let viewContext: NSManagedObjectContext
    private let vehicle: Vehicles
    private let profileVM: ProfileViewModel

    init(context: NSManagedObjectContext, vehicle: Vehicles, profileVM: ProfileViewModel) {
        print("[AddServiceVM] init")
        self.viewContext = context
        // prefer store trump to avoid unexpected merge conflicts when background changes happen
        self.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        self.vehicle = vehicle
        self.profileVM = profileVM
    }

    func addService() {
        print("[AddServiceVM] addService called")

        // reset messages
        successMessage = nil
        errorMessage = nil

        // Validation
        let trimmedName = serviceName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Please enter the service name."
            print("[AddServiceVM] validation failed: empty service name")
            return
        }

        guard !odometer.trimmingCharacters(in: .whitespaces).isEmpty,
              let odometerValue = Double(odometer) else {
            errorMessage = "Please enter a valid odometer value."
            print("[AddServiceVM] validation failed: invalid odometer '\(odometer)'")
            return
        }

        // create history object
        let history = ServiceHistory(context: viewContext)
        history.history_id = UUID()
        history.service_name = trimmedName
        history.service_date = selectedDate
        history.odometer = odometerValue
        history.created_at = Date()

        // If your model includes reminder_days_before in ServiceHistory, set it safely
        if history.responds(to: Selector(("setReminder_days_before:"))) {
            history.setValue(Int16(daysBeforeReminder), forKey: "reminder_days_before")
        }

        // If your model includes next_service_date in ServiceHistory, set it safely
        if history.responds(to: Selector(("setNext_service_date:"))) {
            if let nextDate = Calendar.current.date(byAdding: .month, value: 5, to: selectedDate) {
                history.setValue(nextDate, forKey: "next_service_date")
            }
        }

        // relate to vehicle
        history.vehicle = vehicle

        // update vehicle summary fields (defensive: check attributes exist)
        vehicle.last_service_date = selectedDate
        vehicle.last_odometer = odometerValue
        vehicle.service_name = trimmedName

        // set vehicle.next_service_date if attribute exists
        if vehicle.responds(to: Selector(("setNext_service_date:"))) {
            if let next = Calendar.current.date(byAdding: .month, value: 5, to: selectedDate) {
                vehicle.setValue(next, forKey: "next_service_date")
            }
        }

        // store reminder offset on vehicle if that attribute exists
        let offset = Int16(daysBeforeReminder)
        if vehicle.responds(to: Selector(("setService_reminder_offset:"))) {
            vehicle.setValue(offset, forKey: "service_reminder_offset")
        }

        // Save context
        do {
            try viewContext.save()
            viewContext.processPendingChanges()
            print("[AddServiceVM] saved service for vehicle: \(vehicle.make_model ?? "unknown")")

            // schedule local reminder / calendar in background; swallow errors to avoid crashes
            if addToReminder {
                Task {
                    await scheduleReminderSafely(for: history, daysBefore: daysBeforeReminder)
                }
            }

            // if added service is in past, optionally auto-create an upcoming service (non-blocking)
            if selectedDate < Date() {
                Task.detached { [weak self] in
                    guard let self = self else { return }
                    await MainActor.run {
                        self.autoCreateUpcomingServiceIfNeeded()
                    }
                }
            }

            successMessage = "Service added successfully!"
            clearFields()

            // notify UI observers (optional)
            NotificationCenter.default.post(name: .init("DriveBuddyServiceAdded"), object: vehicle)

        } catch {
            errorMessage = "Failed to save service: \(error.localizedDescription)"
            print("[AddServiceVM] save error:", error)
        }
    }

    // MARK: - schedule helper (defensive)
    private func scheduleReminderSafely(for history: ServiceHistory, daysBefore: Int) async {
        do {
            // scheduleServiceReminder may throw or return; guard with try? or do-catch dependent on implementation
            await profileVM.scheduleServiceReminder(
                serviceId: history.history_id ?? UUID(),
                serviceName: history.service_name ?? "Service",
                vehicleName: vehicle.make_model ?? "Vehicle",
                serviceDate: history.service_date ?? Date(),
                daysBeforeReminder: daysBefore
            )
            // optional calendar integration
            if profileVM.user?.add_to_calendar == true {
                try? await profileVM.addCalendarEvent(
                    title: "🔧 Service: \(history.service_name ?? "Service")",
                    notes: "Service for \(vehicle.make_model ?? "Vehicle")",
                    startDate: history.service_date ?? Date(),
                    alarmOffsetDays: daysBefore
                )
            }
            print("[AddServiceVM] reminder scheduled")
        } catch {
            print("[AddServiceVM] reminder scheduling failed:", error)
            // do not propagate to UI; it's non-critical
        }
    }

    // MARK: - Auto-create upcoming service (defensive)
    private func autoCreateUpcomingServiceIfNeeded() {
        print("\n🔄 AUTO-CREATE: Starting...")
        
        guard selectedDate < Date() else {
            print("ℹ️ Service is in the future, not auto-creating next service")
            return
        }
        
        let futureRequest: NSFetchRequest<ServiceHistory> = ServiceHistory.fetchRequest()
        futureRequest.predicate = NSPredicate(format: "vehicle == %@ AND service_date > %@", vehicle, Date() as NSDate)
        
        do {
            let existingFutureServices = try viewContext.fetch(futureRequest)
            
            if !existingFutureServices.isEmpty {
                print("ℹ️ Future service already exists, skipping auto-create")
                return
            }
        } catch {
            print("❌ Failed to check for future services: \(error)")
            return
        }
        
        guard let nextDate = Calendar.current.date(byAdding: .month, value: 6, to: selectedDate) else {
            return
        }
        
        let upcomingService = ServiceHistory(context: viewContext)
        upcomingService.history_id = UUID()
        upcomingService.service_name = serviceName // ✅ FIXED: Use the SAME service name
        upcomingService.service_date = nextDate
        upcomingService.odometer = 0
        upcomingService.created_at = Date()
        upcomingService.vehicle = vehicle
        upcomingService.reminder_days_before = Int16(daysBeforeReminder)
        
        print("📝 Auto-creating upcoming '\(serviceName)' for \(nextDate)")
        
        do {
            try viewContext.save()
            viewContext.processPendingChanges()
            print("✅ Auto-created upcoming service successfully")
        } catch {
            print("❌ Failed to auto-create upcoming service: \(error)")
        }
    }

    var daysBeforeReminder: Int {
        switch reminder {
        case "One week before": return 7
        case "Two weeks before": return 14
        case "One month before": return 30
        default: return 7
        }
    }

    private func clearFields() {
        serviceName = ""
        selectedDate = Date()
        odometer = ""
        reminder = "One month before"
        addToReminder = true
    }
}
