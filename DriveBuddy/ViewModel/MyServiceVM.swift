import Foundation
import CoreData
import SwiftUI
import Combine

@MainActor
class MyServiceViewModel: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {

    private let context: NSManagedObjectContext
    let vehicle: Vehicles
    
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
        // Sort utama berdasarkan tanggal
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
    
    func refreshServices() {
        context.refreshAllObjects()
        performFetch()
    }

    private func updateServices() {
        guard let fetchedObjects = fetchedResultsController.fetchedObjects else {
            upcomingServices = []
            completedServices = []
            return
        }

        let calendar = Calendar.current
        let todayStartOfDay = calendar.startOfDay(for: Date())
        
        var upcoming: [ServiceHistory] = []
        var completed: [ServiceHistory] = []
        
        // Grouping untuk mengecek apakah ada service "penerus"
        let servicesByName = Dictionary(grouping: fetchedObjects) { service in
            (service.service_name ?? "").trimmingCharacters(in: .whitespaces).lowercased()
        }
        
        for service in fetchedObjects {
            guard let serviceDate = service.service_date else { continue }
            
            let serviceDateStartOfDay = calendar.startOfDay(for: serviceDate)
            let serviceName = (service.service_name ?? "").trimmingCharacters(in: .whitespaces).lowercased()
            let relatedServices = servicesByName[serviceName] ?? []
            
            // Cek apakah ada service yang LEBIH BARU dengan nama yang sama
            let hasNewerService = relatedServices.contains { other in
                guard let otherDate = other.service_date else { return false }
                return otherDate > serviceDate && other.objectID != service.objectID
            }
            
            // --- LOGIKA FIX ---
            // Service dianggap COMPLETED jika:
            // 1. Odometer > 0 (Artinya user sudah menginput hasil servisnya)
            // 2. ATAU ada service selanjutnya (logika otomatisasi kamu)
            let isActuallyDone = service.odometer > 0 || hasNewerService
            
            if isActuallyDone {
                completed.append(service)
            } else {
                // Jika odometer masih 0 DAN tidak ada service baru setelahnya,
                // maka dia adalah service yang sedang ditunggu (Upcoming/Overdue)
                upcoming.append(service)
            }
        }
        
        // Sort Upcoming: Yang paling lama/overdue di atas
        self.upcomingServices = upcoming.sorted {
            ($0.service_date ?? Date.distantFuture) < ($1.service_date ?? Date.distantFuture)
        }
        
        // Sort Completed: Yang paling baru selesai di atas
        self.completedServices = completed.sorted {
            ($0.service_date ?? Date.distantPast) > ($1.service_date ?? Date.distantPast)
        }
    }

    func deleteService(_ service: ServiceHistory) {
        context.delete(service)
        do {
            try context.save()
            // Paksa update UI setelah delete
            updateServices()
            print("✅ Service deleted & UI updated")
        } catch {
            print("❌ Failed to delete service: \(error.localizedDescription)")
        }
    }

    // --- Helper Methods untuk UI ---

    func isServiceOverdue(_ service: ServiceHistory) -> Bool {
        guard let serviceDate = service.service_date else { return false }
        let calendar = Calendar.current
        let todayStartOfDay = calendar.startOfDay(for: Date())
        let serviceDateStartOfDay = calendar.startOfDay(for: serviceDate)
        
        return serviceDateStartOfDay < todayStartOfDay
    }
    
    func daysOverdue(for service: ServiceHistory) -> Int {
        guard let serviceDate = service.service_date, isServiceOverdue(service) else { return 0 }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: calendar.startOfDay(for: serviceDate), to: calendar.startOfDay(for: Date()))
        return components.day ?? 0
    }

    private func startDailyUpdateTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateServices()
            }
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}
