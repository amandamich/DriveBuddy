//
//  MyServiceVM.swift
//  DriveBuddy
//
//  Created by Student on 12/11/25.
//

import Foundation
import CoreData
import SwiftUI
import Combine

@MainActor
class MyServiceViewModel: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
    // MARK: - Published properties
    @Published var upcomingServices: [ServiceHistory] = []
    @Published var completedServices: [ServiceHistory] = []

    // MARK: - Core Data
    private let viewContext: NSManagedObjectContext
    private let vehicle: Vehicles
    private var fetchedResultsController: NSFetchedResultsController<ServiceHistory>!
    private var timer: Timer?

    // MARK: - Init
    init(context: NSManagedObjectContext, vehicle: Vehicles) {
        self.viewContext = context
        self.vehicle = vehicle
        super.init()
        setupFetchedResultsController()
        performFetch()
        startDailyUpdateTimer()
    }

    // MARK: - Setup FetchedResultsController (live Core Data listener)
    private func setupFetchedResultsController() {
        let request: NSFetchRequest<ServiceHistory> = ServiceHistory.fetchRequest()
        request.predicate = NSPredicate(format: "vehicle == %@", vehicle)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ServiceHistory.service_date, ascending: false)]

        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        fetchedResultsController.delegate = self
    }

    // MARK: - Perform initial fetch
    private func performFetch() {
        do {
            try fetchedResultsController.performFetch()
            updateServices()
        } catch {
            print("❌ Failed to fetch services: \(error.localizedDescription)")
        }
    }

    // MARK: - React to Core Data changes
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        updateServices()
    }

    // MARK: - Classify services dynamically
    private func updateServices() {
        guard let fetchedObjects = fetchedResultsController.fetchedObjects else {
            upcomingServices = []
            completedServices = []
            return
        }

        let now = Date()

        upcomingServices = fetchedObjects.filter { service in
            guard let date = service.service_date else { return false }
            return date > now
        }

        completedServices = fetchedObjects.filter { service in
            guard let date = service.service_date else { return false }
            return date <= now
        }
    }

    // MARK: - Delete a service
    func deleteService(_ service: ServiceHistory) {
        viewContext.delete(service)
        do {
            try viewContext.save()
        } catch {
            print("❌ Failed to delete service: \(error.localizedDescription)")
        }
    }

    // MARK: - Optional: Refresh automatically every hour
    private func startDailyUpdateTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateServices()
            }
        }
    }
}
