import Foundation
import CoreData
import SwiftUI
import Combine

@MainActor
class MyServiceViewModel: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {

    private let context: NSManagedObjectContext
    private let vehicle: Vehicles
    
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
    
    // ✅ NEW: Public refresh method
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

        // ✅ FIXED: Use current moment for accurate comparison
        let now = Date()
        
        // ✅ IMPROVED: Strictly future services only
        upcomingServices = fetchedObjects.filter { service in
            guard let date = service.service_date else { return false }
            return date > now // Only future services
        }.sorted {
            ($0.service_date ?? .distantFuture) < ($1.service_date ?? .distantFuture)
        }

        // ✅ IMPROVED: Past and current services
        completedServices = fetchedObjects.filter { service in
            guard let date = service.service_date else { return false }
            return date <= now // Past or now
        }.sorted {
            ($0.service_date ?? .distantPast) > ($1.service_date ?? .distantPast)
        }

        print("\n🔍 SERVICE CLASSIFICATION (Now: \(now)):")
        print("   📅 Upcoming: \(upcomingServices.count)")
        for service in upcomingServices {
            print("      - \(service.service_name ?? "Unknown") on \(service.service_date?.description ?? "N/A")")
        }
        print("   ✅ Completed: \(completedServices.count)")
        for service in completedServices {
            print("      - \(service.service_name ?? "Unknown") on \(service.service_date?.description ?? "N/A")")
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
    // ✅ NEW: Delete all services with empty names
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
}
