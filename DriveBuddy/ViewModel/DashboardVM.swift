//
//  DashboardVM.swift - FIXED VERSION
//  DriveBuddy
//

import Foundation
import CoreData
import SwiftUI
import Combine

@MainActor
class DashboardViewModel: ObservableObject {

    private let viewContext: NSManagedObjectContext
    private let user: User?

    init(context: NSManagedObjectContext, user: User?) {
        self.viewContext = context
        self.user = user
    }

    // MARK: - Delete Vehicle
    func deleteVehicle(_ vehicle: Vehicles) {
        viewContext.delete(vehicle)
        
        do {
            try viewContext.save()
            print("Vehicle deleted successfully")
        } catch {
            print("Error deleting vehicle: \(error.localizedDescription)")
        }
    }
    
    func deleteVehicles(at offsets: IndexSet, from vehicles: [Vehicles]) {
        for index in offsets {
            let vehicle = vehicles[index]
            deleteVehicle(vehicle)
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
    
    func extractUsername(from email: String?) -> String {
        guard let email = email else { return "User" }
        if let atIndex = email.firstIndex(of: "@") {
            let username = String(email[..<atIndex])
            return username.prefix(1).uppercased() + username.dropFirst()
        }
        return email
    }

    // MARK: - ✅ FIXED: Get Next Service Date from ServiceHistory
    func getNextServiceDate(for vehicle: Vehicles) -> Date? {
        let request: NSFetchRequest<ServiceHistory> = ServiceHistory.fetchRequest()
        request.predicate = NSPredicate(
            format: "vehicle == %@ AND service_date > %@",
            vehicle,
            Date() as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ServiceHistory.service_date, ascending: true)]
        request.fetchLimit = 1 // Only get the nearest upcoming service
        
        do {
            let upcomingServices = try viewContext.fetch(request)
            if let nearestService = upcomingServices.first {
                print("📅 [Dashboard] Next service for \(vehicle.make_model ?? "Unknown"): \(nearestService.service_date?.description ?? "nil")")
                return nearestService.service_date
            }
        } catch {
            print("❌ [Dashboard] Failed to fetch upcoming services: \(error)")
        }
        
        // Fallback: Calculate from last service if no upcoming service in database
        if let lastService = vehicle.last_service_date {
            let calculated = Calendar.current.date(byAdding: .month, value: 6, to: lastService)
            print("⚠️ [Dashboard] No upcoming service in DB, using calculated: \(calculated?.description ?? "nil")")
            return calculated
        }
        
        return nil
    }

    // MARK: - ✅ FIXED: Service Reminder Logic (uses actual ServiceHistory)
    func serviceReminderStatus(for vehicle: Vehicles) -> ServiceReminderStatus {
        guard let nextService = getNextServiceDate(for: vehicle) else {
            return .unknown
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let nextServiceDay = calendar.startOfDay(for: nextService)

        let daysUntilNext = calendar.dateComponents([.day], from: today, to: nextServiceDay).day ?? 0
        
        print("🔔 [Dashboard] \(vehicle.make_model ?? "Unknown"): \(daysUntilNext) days until next service")

        switch daysUntilNext {
        case ..<0:
            return .overdue
        case 0:
            return .tomorrow
        case 1...7:
            return .upcoming
        case 8...30:
            return .soon
        default:
            return .notYet
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

// MARK: - Enum for Service Reminder Status
enum ServiceReminderStatus {
    case tomorrow
    case upcoming
    case soon
    case overdue
    case notYet
    case unknown

    var label: String {
        switch self {
        case .tomorrow: return "Tomorrow"
        case .upcoming: return "Upcoming"
        case .soon: return "Soon"
        case .overdue: return "Overdue"
        case .notYet: return "Not Yet"
        case .unknown: return "Unknown"
        }
    }

    var color: Color {
        switch self {
        case .tomorrow: return .cyan
        case .upcoming: return .orange
        case .soon: return .yellow
        case .overdue: return .red
        case .notYet: return .gray
        case .unknown: return .gray
        }
    }
}
