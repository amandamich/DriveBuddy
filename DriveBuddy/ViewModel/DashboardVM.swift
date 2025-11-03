//
//  DashboardVM.swift
//  DriveBuddy
//
//  Created by Jennifer Alicia Litan on 03/11/25.
//

import Foundation
import CoreData
import SwiftUI
import Combine

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var userVehicles: [Vehicles] = []

    private let viewContext: NSManagedObjectContext
    private let user: User

    init(context: NSManagedObjectContext, user: User) {
        self.viewContext = context
        self.user = user
        fetchVehicles()
    }

    // MARK: - Fetch Vehicles
    func fetchVehicles() {
        let request: NSFetchRequest<Vehicles> = Vehicles.fetchRequest()
        request.predicate = NSPredicate(format: "user == %@", user)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Vehicles.created_at, ascending: false)]

        do {
            userVehicles = try viewContext.fetch(request)
        } catch {
            print("Error fetching vehicles: \(error.localizedDescription)")
        }
    }

    // MARK: - Delete Vehicle
    func deleteVehicle(at offsets: IndexSet) {
        for index in offsets {
            let vehicleToDelete = userVehicles[index]
            viewContext.delete(vehicleToDelete)
        }

        do {
            try viewContext.save()
            fetchVehicles()
        } catch {
            print("Error deleting vehicle: \(error.localizedDescription)")
        }
    }

    // MARK: - Tax Status Logic
    func taxStatus(for vehicle: Vehicles) -> VehicleTaxStatus {
        guard let taxDate = vehicle.tax_due_date else { return .unknown }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dueDate = calendar.startOfDay(for: taxDate)

        let daysRemaining = calendar.dateComponents([.day], from: today, to: dueDate).day ?? 0

        if daysRemaining < 0 {
            return .overdue
        } else if daysRemaining <= 30 {
            return .dueSoon
        } else {
            return .valid
        }
    }
}

// MARK: - Enum for Vehicle Tax Status
enum VehicleTaxStatus {
    case valid
    case dueSoon
    case overdue
    case unknown

    var label: String {
        switch self {
        case .valid: return "Up to Date"
        case .dueSoon: return "Due Soon"
        case .overdue: return "Overdue"
        case .unknown: return "Unknown"
        }
    }

    var color: Color {
        switch self {
        case .valid: return .green
        case .dueSoon: return .orange
        case .overdue: return .red
        case .unknown: return .gray
        }
    }
}

