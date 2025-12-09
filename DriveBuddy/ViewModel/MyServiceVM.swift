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

    private func updateServices() {
        guard let fetchedObjects = fetchedResultsController.fetchedObjects else {
            upcomingServices = []
            completedServices = []
            return
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        upcomingServices = fetchedObjects.filter { service in
            guard let date = service.service_date else { return false }
            return calendar.startOfDay(for: date) > today
        }

        completedServices = fetchedObjects.filter { service in
            guard let date = service.service_date else { return false }
            return calendar.startOfDay(for: date) <= today
        }

        print("\n🔍 CLASSIFY RESULT")
        print("Upcoming:", upcomingServices.count)
        print("Completed:", completedServices.count)
    }

    func deleteService(_ service: ServiceHistory) {
        context.delete(service)
        do {
            try context.save()
        } catch {
            print("❌ Failed to delete service: \(error.localizedDescription)")
        }
    }

    private func startDailyUpdateTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateServices()
            }
        }
    }
}
