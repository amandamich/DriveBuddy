import Foundation
import CoreData
import SwiftUI
import Combine

@MainActor
class MyServiceViewModel: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {

    private let context: NSManagedObjectContext
    let vehicle: Vehicles  // ✅ Changed to public for access from view
    
    @Published var upcomingServices: [ServiceHistory] = []
    @Published var completedServices: [ServiceHistory] = []

    private var fetchedResultsController: NSFetchedResultsController<ServiceHistory>!
    private var timer: Timer?
    
    init(context: NSManagedObjectContext, vehicle: Vehicles) {
        self.context = context
        self.vehicle = vehicle
        super.init()
        setupFetchedResultsController()
        performFetch()
        startDailyUpdateTimer()
    }

    private func setupFetchedResultsController() {
        let request: NSFetchRequest<ServiceHistory> = ServiceHistory.fetchRequest()
        request.predicate = NSPredicate(format: "vehicle == %@", vehicle)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ServiceHistory.service_date, ascending: false)]

        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        fetchedResultsController.delegate = self
    }

    private func performFetch() {
        do {
            try fetchedResultsController.performFetch()
            updateServices()
        } catch {
            print("❌ Failed to fetch services: \(error.localizedDescription)")
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        updateServices()
    }
    
    // ✅ Public refresh method
    func refreshServices() {
        context.refreshAllObjects()
        performFetch()
        print("🔄 Services refreshed")
        print("   Upcoming: \(upcomingServices.count)")
        print("   Completed: \(completedServices.count)")
    }

    private func updateServices() {
        guard let fetchedObjects = fetchedResultsController.fetchedObjects else {
            upcomingServices = []
            completedServices = []
            return
        }

        let calendar = Calendar.current
        let now = Date()
        let todayStartOfDay = calendar.startOfDay(for: now)
        
        print("\n⏰ Current time: \(now)")
        print("⏰ Today start: \(todayStartOfDay)")
        
        // ✅ BEST OVERDUE LOGIC (No Core Data changes needed):
        //
        // Strategy: When user marks service as "done" in CompleteServiceView,
        // it auto-creates a NEXT service with same name but future date.
        //
        // So we can detect completed services by checking:
        // - If there's a NEWER service with the SAME name, the older one was completed
        // - If service is in PAST and NO newer service exists, it's OVERDUE
        // - If service is in FUTURE, it's UPCOMING
        
        var upcoming: [ServiceHistory] = []
        var completed: [ServiceHistory] = []
        
        // Group services by name to find related services
        let servicesByName = Dictionary(grouping: fetchedObjects) { service in
            (service.service_name ?? "").trimmingCharacters(in: .whitespaces).lowercased()
        }
        
        print("\n" + String(repeating: "=", count: 80))
        print("🔍 SERVICE CLASSIFICATION DEBUG")
        print(String(repeating: "=", count: 80))
        print("Today: \(todayStartOfDay)")
        print("\nAll services grouped by name:")
        for (name, services) in servicesByName {
            print("\n  '\(name)' (\(services.count) service(s)):")
            for service in services.sorted(by: { ($0.service_date ?? Date()) < ($1.service_date ?? Date()) }) {
                print("    - Date: \(service.service_date?.description ?? "nil")")
                print("      Odometer: \(service.odometer) km")
                print("      Created: \(service.created_at?.description ?? "nil")")
            }
        }
        print(String(repeating: "-", count: 80))
        
        for service in fetchedObjects {
            guard let serviceDate = service.service_date else {
                print("⚠️ Service with no date: \(service.service_name ?? "Unknown")")
                continue
            }
            
            let serviceDateStartOfDay = calendar.startOfDay(for: serviceDate)
            let isInPast = serviceDateStartOfDay < todayStartOfDay
            let isInFuture = serviceDateStartOfDay > todayStartOfDay
            let isToday = serviceDateStartOfDay == todayStartOfDay
            
            // ✅ Check if there's a NEWER service with same name (case-insensitive, trimmed)
            let serviceName = (service.service_name ?? "").trimmingCharacters(in: .whitespaces).lowercased()
            let relatedServices = servicesByName[serviceName] ?? []
            
            let newerServices = relatedServices.filter { otherService in
                guard let otherDate = otherService.service_date,
                      otherService.objectID != service.objectID else {
                    return false
                }
                return otherDate > serviceDate
            }
            
            let hasNewerService = !newerServices.isEmpty
            let hasOdometer = service.odometer > 0
            
            print("\n🔍 Analyzing: '\(service.service_name ?? "NO NAME")'")
            print("   Service Date: \(serviceDateStartOfDay)")
            print("   Odometer: \(service.odometer) km")
            print("   Has Odometer: \(hasOdometer)")
            print("   Created: \(service.created_at?.description ?? "nil")")
            print("   Related services: \(relatedServices.count)")
            print("   Newer services: \(newerServices.count)")
            if !newerServices.isEmpty {
                for newer in newerServices {
                    print("      → Newer: \(newer.service_date?.description ?? "nil")")
                }
            }
            print("   Is Past: \(isInPast), Is Future: \(isInFuture), Is Today: \(isToday)")
            
            // ✅ CRITICAL FIX: If service has newer service with same name, it's ALWAYS completed
            // regardless of date (this handles the case where user marks service as done today)
            if hasNewerService && hasOdometer {
                completed.append(service)
                let daysAgo = calendar.dateComponents([.day], from: serviceDateStartOfDay, to: todayStartOfDay).day ?? 0
                print("   ✅ → COMPLETED (\(daysAgo) days ago) [has newer service + has odometer]")
                continue
            }
            
            // ✅ DECISION LOGIC:
            if isInFuture || isToday {
                // Future or today services are always UPCOMING (if no newer service)
                upcoming.append(service)
                
                if isToday {
                    print("   📅 → UPCOMING (Today)")
                } else {
                    let daysUntil = calendar.dateComponents([.day], from: todayStartOfDay, to: serviceDateStartOfDay).day ?? 0
                    print("   🔮 → UPCOMING (in \(daysUntil) days)")
                }
                
            } else if isInPast {
                // Past services: check if completed or overdue
                
                if hasNewerService {
                    // Has newer service = was completed (next service was auto-created)
                    completed.append(service)
                    let daysAgo = calendar.dateComponents([.day], from: serviceDateStartOfDay, to: todayStartOfDay).day ?? 0
                    print("   ✅ → COMPLETED (\(daysAgo) days ago) [has newer service]")
                } else {
                    // No newer service = not done yet = OVERDUE
                    upcoming.append(service)
                    let daysOverdue = calendar.dateComponents([.day], from: serviceDateStartOfDay, to: todayStartOfDay).day ?? 0
                    print("   ⏰ → OVERDUE (\(daysOverdue) days overdue)")
                }
            }
        }
        
        print(String(repeating: "=", count: 80) + "\n")
        
        // Sort upcoming by date (oldest/most overdue first)
        upcomingServices = upcoming.sorted {
            ($0.service_date ?? .distantFuture) < ($1.service_date ?? .distantFuture)
        }
        
        // Sort completed by date (most recent first)
        completedServices = completed.sorted {
            ($0.service_date ?? .distantPast) > ($1.service_date ?? .distantPast)
        }

        print("\n📊 SUMMARY:")
        print("   Upcoming (including overdue): \(upcomingServices.count)")
        print("   Completed: \(completedServices.count)")
        
        // ✅ Show overdue count
        let overdueCount = upcomingServices.filter { isServiceOverdue($0) }.count
        if overdueCount > 0 {
            print("   ⚠️ OVERDUE: \(overdueCount)")
        }
    }

    func deleteService(_ service: ServiceHistory) {
        context.delete(service)
        do {
            try context.save()
            print("✅ Service deleted successfully")
        } catch {
            print("❌ Failed to delete service: \(error.localizedDescription)")
        }
    }

    private func startDailyUpdateTimer() {
        timer?.invalidate()
        // Update every hour to reclassify services
        timer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateServices()
            }
        }
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // ✅ Delete all services with empty names
    func deleteUnnamedServices() {
        let request: NSFetchRequest<ServiceHistory> = ServiceHistory.fetchRequest()
        request.predicate = NSPredicate(
            format: "vehicle == %@ AND (service_name == nil OR service_name == '')",
            vehicle
        )
        
        do {
            let unnamedServices = try context.fetch(request)
            
            print("\n🗑️ DELETING UNNAMED SERVICES:")
            print("   Found \(unnamedServices.count) unnamed service(s)")
            
            for service in unnamedServices {
                print("   - Deleting: '\(service.service_name ?? "nil")' on \(service.service_date?.description ?? "nil")")
                context.delete(service)
            }
            
            try context.save()
            context.processPendingChanges()
            print("✅ Deleted all unnamed services\n")
            
            refreshServices()
            
        } catch {
            print("❌ Failed to delete unnamed services: \(error)")
        }
    }
    
    // MARK: - ✅ NEW: Overdue Helper Methods
    
    /// Check if a service is overdue
    func isServiceOverdue(_ service: ServiceHistory) -> Bool {
        guard let serviceDate = service.service_date else { return false }
        let calendar = Calendar.current
        let todayStartOfDay = calendar.startOfDay(for: Date())
        let serviceDateStartOfDay = calendar.startOfDay(for: serviceDate)
        
        return serviceDateStartOfDay < todayStartOfDay
    }
    
    /// Get number of days a service is overdue (returns 0 if not overdue)
    func daysOverdue(for service: ServiceHistory) -> Int {
        guard let serviceDate = service.service_date else { return 0 }
        guard isServiceOverdue(service) else { return 0 }
        
        let calendar = Calendar.current
        let todayStartOfDay = calendar.startOfDay(for: Date())
        let serviceDateStartOfDay = calendar.startOfDay(for: serviceDate)
        
        let components = calendar.dateComponents([.day], from: serviceDateStartOfDay, to: todayStartOfDay)
        return components.day ?? 0
    }
    
    /// Get count of overdue services
    func overdueServicesCount() -> Int {
        return upcomingServices.filter { isServiceOverdue($0) }.count
    }
}
