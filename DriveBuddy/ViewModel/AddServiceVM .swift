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
        successMessage = nil
        errorMessage = nil

        // validation
        guard !serviceName.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter the service name."
            return
        }
        guard let odometerValue = Double(odometer) else {
            errorMessage = "Please enter a valid odometer value."
            return
        }

        // 1) create ServiceHistory
        let history = ServiceHistory(context: viewContext)
        history.history_id = UUID()
        history.service_name = serviceName.trimmingCharacters(in: .whitespacesAndNewlines)
        history.service_date = selectedDate
        history.odometer = odometerValue
        history.created_at = Date()

        // relate
        history.vehicle = vehicle

        // 2) calculate next service (ONLY ON VEHICLE)
        if let next = Calendar.current.date(byAdding: .month, value: 5, to: selectedDate) {
            vehicle.next_service_date = next
        }

        // 3) store reminder offset
        switch reminder {
        case "One week before": vehicle.service_reminder_offset = 7
        case "Two weeks before": vehicle.service_reminder_offset = 14
        case "One month before": vehicle.service_reminder_offset = 30
        default: vehicle.service_reminder_offset = 7
        }

        // 4) update vehicle summary
        vehicle.last_service_date = selectedDate
        vehicle.service_name = history.service_name
        vehicle.last_odometer = odometerValue

        // 5) save context
        do {
            try viewContext.save()
            viewContext.refresh(vehicle, mergeChanges: true)

            successMessage = "Service added successfully!"

            // send UI update
            NotificationCenter.default.post(name: .init("DriveBuddyServiceAdded"), object: nil)

            clearFields()

        } catch {
            errorMessage = "Failed to save service: \(error.localizedDescription)"
        }
    }


    
    // ✅ FIXED: Auto-create upcoming service if the added service is in the past
    private func autoCreateUpcomingServiceIfNeeded() {
        print("\n🔄 AUTO-CREATE: Starting...")
        
        // Only auto-create if the service we just added is in the past
        guard selectedDate < Date() else {
            print("ℹ️ Service is in the future, not auto-creating next service")
            return
        }
        
        // ✅ FIXED: Fetch fresh data to check for existing future services
        let futureRequest: NSFetchRequest<ServiceHistory> = ServiceHistory.fetchRequest()
        futureRequest.predicate = NSPredicate(format: "vehicle == %@ AND service_date > %@", vehicle, Date() as NSDate)
        
        do {
            let existingFutureServices = try viewContext.fetch(futureRequest)
            print("🔍 Found \(existingFutureServices.count) existing future services")
            
            if !existingFutureServices.isEmpty {
                print("ℹ️ Future service already exists:")
                for service in existingFutureServices {
                    print("   - \(service.service_name ?? "nil") on \(service.service_date?.description ?? "nil")")
                }
                return
            }
        } catch {
            print("❌ Failed to check for future services: \(error)")
            return
        }
        
        // Create upcoming service 6 months from the service we just added
        guard let nextDate = Calendar.current.date(byAdding: .month, value: 6, to: selectedDate) else {
            print("❌ Failed to calculate next service date")
            return
        }
        
        print("📝 Creating new upcoming service for \(nextDate)")
        
        // ✅ Create in the SAME context
        let upcomingService = ServiceHistory(context: viewContext)
        upcomingService.history_id = UUID()
        upcomingService.service_name = "Scheduled Maintenance"
        upcomingService.service_date = nextDate
        upcomingService.odometer = 0
        upcomingService.created_at = Date()
        upcomingService.vehicle = vehicle
        
        print("   Service ID: \(upcomingService.history_id?.uuidString ?? "nil")")
        print("   Name: \(upcomingService.service_name ?? "nil")")
        print("   Date: \(upcomingService.service_date?.description ?? "nil")")
        
        do {
            try viewContext.save()
            viewContext.processPendingChanges()
            
            // ✅ Verify it was saved
            let verifyRequest: NSFetchRequest<ServiceHistory> = ServiceHistory.fetchRequest()
            verifyRequest.predicate = NSPredicate(format: "vehicle == %@", vehicle)
            let allServices = try viewContext.fetch(verifyRequest)
            
            print("✅ Auto-created upcoming service successfully")
            print("📊 Total services now: \(allServices.count)")
            for (index, service) in allServices.enumerated() {
                print("   \(index + 1). \(service.service_name ?? "nil") - \(service.service_date?.description ?? "nil")")
            }
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
