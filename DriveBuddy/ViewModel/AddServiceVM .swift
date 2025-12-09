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
        // ⚠️ CRITICAL DEBUG - This should ALWAYS print if function is called
        print("\n🔴🔴🔴 addService() FUNCTION CALLED 🔴🔴🔴")
        print("Service Name: \(serviceName)")
        print("Selected Date: \(selectedDate)")
        print("Odometer: \(odometer)")
        
        successMessage = nil
        errorMessage = nil

        guard !serviceName.isEmpty else {
            print("❌ Service name is empty")
            errorMessage = "Please enter the service name."
            return
        }

        guard !odometer.isEmpty, let odometerValue = Double(odometer) else {
            print("❌ Odometer is invalid")
            errorMessage = "Please enter a valid odometer value."
            return
        }

        print("\n" + String(repeating: "=", count: 60))
        print("🚀 STARTING ADD SERVICE PROCESS")
        print(String(repeating: "=", count: 60))

        // ✅ Check services for THIS vehicle BEFORE
        let beforeRequest: NSFetchRequest<ServiceHistory> = ServiceHistory.fetchRequest()
        beforeRequest.predicate = NSPredicate(format: "vehicle == %@", vehicle)
        let beforeCount = (try? viewContext.count(for: beforeRequest)) ?? 0
        print("🔍 BEFORE SAVE: \(beforeCount) services for THIS vehicle")
        print("   Vehicle ID: \(vehicle.vehicles_id?.uuidString ?? "nil")")
        print("   Vehicle Name: \(vehicle.make_model ?? "nil")")

        // ✅ Create NEW service (never update existing ones)
        let newService = ServiceHistory(context: viewContext)
        newService.history_id = UUID()
        newService.service_name = serviceName
        newService.service_date = selectedDate
        newService.odometer = odometerValue
        newService.created_at = Date()
        newService.vehicle = vehicle

        let isPastService = selectedDate < Date()
        
        print("\n📝 CREATING NEW SERVICE:")
        print("   Service ID: \(newService.history_id?.uuidString ?? "nil")")
        print("   Name: \(newService.service_name ?? "nil")")
        print("   Date: \(newService.service_date?.description ?? "nil")")
        print("   Is Past: \(isPastService)")
        print("   Odometer: \(odometerValue)")
        print("   Context has changes: \(viewContext.hasChanges)")
        print("   Context inserted objects: \(viewContext.insertedObjects.count)")

        // ✅ Check if service object is properly created
        guard newService.managedObjectContext != nil else {
            print("❌ CRITICAL: Service has no managed object context!")
            errorMessage = "Failed to create service: No context"
            return
        }

        do {
            print("\n💾 ATTEMPTING FIRST SAVE...")
            
            // ✅ Check what's in context BEFORE save
            let allObjectsRequest: NSFetchRequest<ServiceHistory> = ServiceHistory.fetchRequest()
            allObjectsRequest.predicate = NSPredicate(format: "vehicle == %@", vehicle)
            if let allBeforeSave = try? viewContext.fetch(allObjectsRequest) {
                print("\n📋 SERVICES IN CONTEXT BEFORE SAVE:")
                for service in allBeforeSave {
                    print("   - \(service.service_name ?? "nil") [\(service.isDeleted ? "DELETED" : "ACTIVE")]")
                }
            }
            
            // ✅ FIRST: Save the main service
            try viewContext.save()
            print("✅ Context save succeeded")
            
            viewContext.processPendingChanges()
            print("✅ Pending changes processed")
            
            // ✅ Verify the service still exists in context
            if newService.isDeleted {
                print("❌ CRITICAL: Service was deleted after save!")
            } else {
                print("✅ Service still exists in context")
            }
            
            // ✅ Check what's in the persistent store AFTER save
            viewContext.refreshAllObjects()
            if let allAfterSave = try? viewContext.fetch(allObjectsRequest) {
                print("\n📋 SERVICES IN PERSISTENT STORE AFTER SAVE:")
                for service in allAfterSave {
                    print("   - \(service.service_name ?? "nil") (ID: \(service.history_id?.uuidString ?? "nil"))")
                }
            }
            
            // ✅ Verify the service was saved
            let afterCount = (try? viewContext.count(for: beforeRequest)) ?? 0
            print("\n📊 AFTER FIRST SAVE: \(afterCount) services (was \(beforeCount))")
            
            if afterCount <= beforeCount {
                print("⚠️⚠️⚠️ WARNING: Service count didn't increase!")
                print("   Expected: \(beforeCount + 1), Got: \(afterCount)")
                print("   This suggests a unique constraint or merge policy issue")
            } else {
                print("✅ Service count increased correctly!")
            }
            
            // ✅ Try to fetch the specific service we just created
            let verifyRequest: NSFetchRequest<ServiceHistory> = ServiceHistory.fetchRequest()
            verifyRequest.predicate = NSPredicate(format: "history_id == %@", newService.history_id! as CVarArg)
            if let found = try? viewContext.fetch(verifyRequest), !found.isEmpty {
                print("✅ Service found in database: \(found[0].service_name ?? "nil")")
            } else {
                print("❌ Service NOT found in database by ID!")
            }
            
            // ✅ List all services after save
            if let allServices = try? viewContext.fetch(beforeRequest) {
                print("\n📋 ALL SERVICES AFTER MAIN SAVE:")
                for (index, service) in allServices.enumerated() {
                    let isPast = (service.service_date ?? Date()) < Date()
                    print("   \(index + 1). \(service.service_name ?? "nil")")
                    print("      Date: \(service.service_date?.description ?? "nil")")
                    print("      Past: \(isPast)")
                    print("      ID: \(service.history_id?.uuidString ?? "nil")")
                }
            }
            
            // ✅ SECOND: Auto-create upcoming service if needed
            if isPastService {
                print("\n🔄 Service is in the past, attempting auto-create...")
                // ✅ CRITICAL: Refresh context to ensure we have latest data
                viewContext.refreshAllObjects()
                autoCreateUpcomingServiceIfNeeded()
            } else {
                print("\n⏭️ Service is in the future, skipping auto-create")
            }
            
            // ✅ THIRD: Verify final count AFTER auto-create
            viewContext.refreshAllObjects()
            let finalRequest: NSFetchRequest<ServiceHistory> = ServiceHistory.fetchRequest()
            finalRequest.predicate = NSPredicate(format: "vehicle == %@", vehicle)
            if let finalServices = try? viewContext.fetch(finalRequest) {
                print("\n📊 FINAL SERVICE LIST (\(finalServices.count) total):")
                for (index, service) in finalServices.enumerated() {
                    let isPast = (service.service_date ?? Date()) < Date()
                    print("   \(index + 1). \(service.service_name ?? "nil")")
                    print("      Date: \(service.service_date?.description ?? "nil")")
                    print("      Past: \(isPast)")
                    print("      ID: \(service.history_id?.uuidString ?? "nil")")
                }
            }
            
            let finalCount = (try? viewContext.count(for: beforeRequest)) ?? 0
            print("\n📊 FINAL COUNT: \(finalCount) services")
            
            // ✅ Notify all contexts about the change
            print("📢 Posting context save notification...")
            NotificationCenter.default.post(
                name: NSNotification.Name.NSManagedObjectContextDidSave,
                object: viewContext
            )
            
            successMessage = "Service added successfully!"
            print("\n✅ ADD SERVICE COMPLETED SUCCESSFULLY")
            print(String(repeating: "=", count: 60) + "\n")

            // ✅ Add reminders and calendar events
            if addToReminder {
                Task {
                    await profileVM.scheduleServiceReminder(
                        serviceId: newService.history_id!,
                        serviceName: newService.service_name ?? "Vehicle Service",
                        vehicleName: vehicle.make_model ?? "Your Vehicle",
                        serviceDate: newService.service_date ?? Date(),
                        daysBeforeReminder: daysBeforeReminder
                    )

                    if profileVM.user?.add_to_calendar == true {
                        try? await profileVM.addCalendarEvent(
                            title: "🔧 Service: \(newService.service_name ?? "Service")",
                            notes: "Scheduled service for \(vehicle.make_model ?? "Vehicle")",
                            startDate: newService.service_date ?? Date(),
                            alarmOffsetDays: daysBeforeReminder
                        )
                    }
                }
            }

            clearFields()
        } catch {
            errorMessage = "Failed to save service: \(error.localizedDescription)"
            print("❌❌❌ SAVE ERROR: \(error)")
            print("Error details: \(error)")
            if let detailedError = error as NSError? {
                print("Error domain: \(detailedError.domain)")
                print("Error code: \(detailedError.code)")
                print("Error userInfo: \(detailedError.userInfo)")
            }
            print(String(repeating: "=", count: 60) + "\n")
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
