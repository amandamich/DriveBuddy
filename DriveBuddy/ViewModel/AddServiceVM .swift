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
    
    // ✅ NEW: Auto-create next service settings
    @Published var autoCreateNext: Bool = true
    @Published var nextServiceInterval: Int = 5000 // km
    @Published var nextServiceMonths: Int = 6 // months

    @Published var successMessage: String?
    @Published var errorMessage: String?

    let reminderOptions = ["One week before", "Two weeks before", "One month before"]

    private let viewContext: NSManagedObjectContext
    private let vehicle: Vehicles
    private let profileVM: ProfileViewModel

    init(context: NSManagedObjectContext, vehicle: Vehicles, profileVM: ProfileViewModel) {
        print("[AddServiceVM] init")
        self.viewContext = context
        self.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        self.vehicle = vehicle
        self.profileVM = profileVM
    }

    func addService() {
        print("[AddServiceVM] addService called")

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

        // Create history object
        let history = ServiceHistory(context: viewContext)
        history.history_id = UUID()
        history.service_name = trimmedName
        history.service_date = selectedDate
        history.odometer = odometerValue
        history.created_at = Date()

        if history.responds(to: Selector(("setReminder_days_before:"))) {
            history.setValue(Int16(daysBeforeReminder), forKey: "reminder_days_before")
        }

        // Relate to vehicle
        history.vehicle = vehicle

        // Update vehicle summary fields
        vehicle.last_service_date = selectedDate
        vehicle.last_odometer = odometerValue
        vehicle.service_name = trimmedName

        // Save context
        do {
            try viewContext.save()
            viewContext.processPendingChanges()
            print("[AddServiceVM] saved service for vehicle: \(vehicle.make_model ?? "unknown")")

            // Schedule reminder if enabled
            if addToReminder {
                Task {
                    await scheduleReminderSafely(for: history, daysBefore: daysBeforeReminder)
                }
            }

            // ✅ ALWAYS auto-create next service if enabled
            if autoCreateNext {
                createNextService(serviceName: trimmedName, fromDate: selectedDate, fromOdometer: odometerValue)
            }

            successMessage = "Service added successfully!"
            clearFields()

            NotificationCenter.default.post(name: .init("DriveBuddyServiceAdded"), object: vehicle)

        } catch {
            errorMessage = "Failed to save service: \(error.localizedDescription)"
            print("[AddServiceVM] save error:", error)
        }
    }

    // ✅ SMART DUPLICATE PREVENTION: Create next service
    private func createNextService(serviceName: String, fromDate: Date, fromOdometer: Double) {
        print("\n🔄 AUTO-CREATE NEXT SERVICE:")
        print("   Service: '\(serviceName)'")
        print("   From date: \(fromDate)")
        print("   From odometer: \(fromOdometer)")
        
        // ✅ CRITICAL: Validate service name is not empty
        guard !serviceName.trimmingCharacters(in: .whitespaces).isEmpty else {
            print("❌ Cannot create service with empty name")
            return
        }
        
        // ✅ Check for existing future service with SAME NAME
        let futureRequest: NSFetchRequest<ServiceHistory> = ServiceHistory.fetchRequest()
        futureRequest.predicate = NSPredicate(
            format: "vehicle == %@ AND service_name ==[c] %@ AND service_date > %@",
            vehicle,
            serviceName as CVarArg,
            fromDate as NSDate
        )
        
        do {
            let existingFutureServices = try viewContext.fetch(futureRequest)
            
            print("   Found \(existingFutureServices.count) existing future '\(serviceName)' service(s)")
            
            if !existingFutureServices.isEmpty {
                print("ℹ️ Future '\(serviceName)' already exists, skipping auto-create")
                for existing in existingFutureServices {
                    print("      - Existing: '\(existing.service_name ?? "NO NAME")' on \(existing.service_date?.description ?? "N/A")")
                }
                return
            }
        } catch {
            print("❌ Failed to check for future services: \(error)")
            return
        }
        
        // Calculate next service date
        guard let nextDate = Calendar.current.date(byAdding: .month, value: nextServiceMonths, to: fromDate) else {
            print("❌ Failed to calculate next date")
            return
        }
        
        // Calculate next odometer
        let nextOdometer = fromOdometer + Double(nextServiceInterval)
        
        // ✅ Create the next service with SAME NAME
        let upcomingService = ServiceHistory(context: viewContext)
        upcomingService.history_id = UUID()
        upcomingService.service_name = serviceName // ✅ CRITICAL: Use exact same name
        upcomingService.service_date = nextDate
        upcomingService.odometer = nextOdometer // ✅ FIXED: Use calculated odometer
        upcomingService.created_at = Date()
        upcomingService.vehicle = vehicle
        
        if upcomingService.responds(to: Selector(("setReminder_days_before:"))) {
            upcomingService.setValue(Int16(daysBeforeReminder), forKey: "reminder_days_before")
        }
        
        print("📝 Creating next '\(serviceName)':")
        print("   ID: \(upcomingService.history_id?.uuidString ?? "N/A")")
        print("   Name: '\(serviceName)'")
        print("   Date: \(nextDate)")
        print("   Odometer: \(Int(nextOdometer)) km")
        print("   Interval: +\(nextServiceInterval) km / +\(nextServiceMonths) months")
        
        do {
            try viewContext.save()
            viewContext.processPendingChanges()
            print("✅ Auto-created next '\(serviceName)' successfully\n")
            
            // Schedule reminder for next service too
            if addToReminder {
                Task {
                    await scheduleReminderSafely(for: upcomingService, daysBefore: daysBeforeReminder)
                }
            }
        } catch {
            print("❌ Failed to auto-create next service: \(error)")
        }
    }

    // MARK: - Schedule helper
    private func scheduleReminderSafely(for history: ServiceHistory, daysBefore: Int) async {
        do {
            await profileVM.scheduleServiceReminder(
                serviceId: history.history_id ?? UUID(),
                serviceName: history.service_name ?? "Service",
                vehicleName: vehicle.make_model ?? "Vehicle",
                serviceDate: history.service_date ?? Date(),
                daysBeforeReminder: daysBefore
            )
            
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
        autoCreateNext = true
        nextServiceInterval = 5000
        nextServiceMonths = 6
    }
}
