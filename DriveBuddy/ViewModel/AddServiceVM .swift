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
        print("🏁 AddServiceViewModel initialized")
        self.viewContext = context
        // ✅ Try NSMergeByPropertyStoreTrumpMergePolicy to keep store data
        self.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        self.vehicle = vehicle
        self.profileVM = profileVM
    }

    func addService() {
        print("\n🔴🔴🔴 addService() FUNCTION CALLED 🔴🔴🔴")
        
        successMessage = nil
        errorMessage = nil

        guard !serviceName.isEmpty else {
            errorMessage = "Please enter the service name."
            return
        }

        guard !odometer.isEmpty, let odometerValue = Double(odometer) else {
            errorMessage = "Please enter a valid odometer value."
            return
        }

        // ✅ Create NEW service
        let newService = ServiceHistory(context: viewContext)
        newService.history_id = UUID()
        newService.service_name = serviceName
        newService.service_date = selectedDate
        newService.odometer = odometerValue
        newService.created_at = Date()
        newService.vehicle = vehicle
        newService.reminder_days_before = Int16(daysBeforeReminder) // ✅ SAVE USER'S CHOICE

        let isPastService = selectedDate < Date()
        
        print("📝 CREATING NEW SERVICE:")
        print("   Reminder: \(daysBeforeReminder) days before")

        do {
            try viewContext.save()
            viewContext.processPendingChanges()
            
            // ✅ Auto-create upcoming service if past
            if isPastService {
                print("\n🔄 Service is in the past, attempting auto-create...")
                viewContext.refreshAllObjects()
                autoCreateUpcomingServiceIfNeeded()
                
                // ✅ Sync to calendar after auto-create
                if addToReminder && profileVM.user?.add_to_calendar == true {
                    Task {
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        await profileVM.syncAllVehiclesToCalendar()
                    }
                }
            }
            
            successMessage = "Service added successfully!"
            
            // ✅ Add reminders using USER'S CHOICE
            if addToReminder {
                Task {
                    await profileVM.scheduleServiceReminder(
                        serviceId: newService.history_id!,
                        serviceName: newService.service_name ?? "Vehicle Service",
                        vehicleName: vehicle.make_model ?? "Your Vehicle",
                        serviceDate: newService.service_date ?? Date(),
                        daysBeforeReminder: daysBeforeReminder // ✅ USER'S CHOICE
                    )

                    if profileVM.user?.add_to_calendar == true {
                        try? await profileVM.addCalendarEvent(
                            title: "🔧 Service: \(newService.service_name ?? "Service")",
                            notes: "Scheduled service for \(vehicle.make_model ?? "Vehicle")",
                            startDate: newService.service_date ?? Date(),
                            alarmOffsetDays: daysBeforeReminder // ✅ USER'S CHOICE
                        )
                    }
                }
            }

            clearFields()
        } catch {
            errorMessage = "Failed to save service: \(error.localizedDescription)"
        }
    }
    
    // ✅ FIXED: Auto-create upcoming service if the added service is in the past
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
        upcomingService.service_name = "Scheduled Maintenance"
        upcomingService.service_date = nextDate
        upcomingService.odometer = 0
        upcomingService.created_at = Date()
        upcomingService.vehicle = vehicle
        upcomingService.reminder_days_before = Int16(daysBeforeReminder) // ✅ INHERIT USER'S CHOICE
        
        print("📝 Auto-creating with \(daysBeforeReminder) days reminder")
        
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
