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

    /// LOGIKA UTAMA: Memisahkan servis ke kategori yang benar
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
        
        // Grouping untuk mengecek hubungan antar servis dengan nama yang sama
        let servicesByName = Dictionary(grouping: fetchedObjects) { service in
            (service.service_name ?? "").trimmingCharacters(in: .whitespaces).lowercased()
        }
        
        for service in fetchedObjects {
            guard let serviceDate = service.service_date else { continue }
            
            let serviceDateStartOfDay = calendar.startOfDay(for: serviceDate)
            let serviceName = (service.service_name ?? "").trimmingCharacters(in: .whitespaces).lowercased()
            let relatedServices = servicesByName[serviceName] ?? []
            
            // 1. Cek apakah tanggal servis adalah MASA LALU atau HARI INI
            let isPastOrToday = serviceDateStartOfDay <= todayStartOfDay
            
            // 2. Cek apakah ada servis selanjutnya (penerus)
            let hasNewerService = relatedServices.contains { other in
                guard let otherDate = other.service_date else { return false }
                return otherDate > serviceDate && other.objectID != service.objectID
            }
            
            // --- LOGIKA KLASIFIKASI FIX ---
            // Syarat Utama: Harus isPastOrToday agar bisa masuk Completed.
            // Jika tanggalnya masih di masa depan (isPastOrToday = false),
            // dia WAJIB masuk Upcoming, meskipun punya servis penerus atau odometer diisi.
            
            let isActuallyDone = isPastOrToday && (service.odometer > 0 || hasNewerService)
            
            if isActuallyDone {
                completed.append(service)
            } else {
                upcoming.append(service)
            }
        }
        
        // Sorting
        // Upcoming: Yang paling dekat (atau paling telat) muncul di atas
        self.upcomingServices = upcoming.sorted {
            ($0.service_date ?? Date.distantFuture) < ($1.service_date ?? Date.distantFuture)
        }
        
        // Completed: Yang baru saja dilakukan muncul di paling atas
        self.completedServices = completed.sorted {
            ($0.service_date ?? Date.distantPast) > ($1.service_date ?? Date.distantPast)
        }
    }

    func deleteService(_ service: ServiceHistory) {
        context.delete(service)
        do {
            try context.save()
            updateServices() // Refresh data setelah hapus
            print("✅ Service deleted & UI updated")
        } catch {
            print("❌ Failed to delete service: \(error.localizedDescription)")
        }
    }

    // MARK: - Helper Methods

    func isServiceOverdue(_ service: ServiceHistory) -> Bool {
        guard let serviceDate = service.service_date else { return false }
        let calendar = Calendar.current
        let todayStartOfDay = calendar.startOfDay(for: Date())
        let serviceDateStartOfDay = calendar.startOfDay(for: serviceDate)
        
        // Overdue jika tanggal sudah lewat dari hari ini
        return serviceDateStartOfDay < todayStartOfDay
    }
    
    func daysOverdue(for service: ServiceHistory) -> Int {
        guard let serviceDate = service.service_date, isServiceOverdue(service) else { return 0 }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day],
                                                 from: calendar.startOfDay(for: serviceDate),
                                                 to: calendar.startOfDay(for: Date()))
        return components.day ?? 0
    }

    private func startDailyUpdateTimer() {
        timer?.invalidate()
        // Cek setiap jam untuk memindahkan status jika hari berganti
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
