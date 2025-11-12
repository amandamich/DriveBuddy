//
//  VehicleDetailViewModel.swift
//  DriveBuddy
//
//  Created by Jennifer Alicia Litan on 03/11/25.
//  Updated by ChatGPT on 12/11/25
//

import Foundation
import CoreData
import SwiftUI
import Combine

@MainActor
class VehicleDetailViewModel: ObservableObject {
    // MARK: - Core Model
    @Published var activeVehicle: Vehicles
    
    // MARK: - Form Bindings
    @Published var makeModel: String = ""
    @Published var plateNumber: String = ""
    @Published var odometer: String = ""
    @Published var taxDueDate: Date = Date()
    @Published var stnkDueDate: Date = Date()
    @Published var serviceName: String = ""
    @Published var lastServiceDate: Date = Date()
    @Published var lastOdometer: String = ""
    
    // MARK: - UI States
    @Published var isEditing: Bool = false
    @Published var isShowingDeleteConfirmation: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    var isShowingError: Bool {
        errorMessage != nil
    }

    // MARK: - Core Data Context
    private let viewContext: NSManagedObjectContext

    // MARK: - Init
    init(context: NSManagedObjectContext, vehicle: Vehicles) {
        self.viewContext = context
        self.activeVehicle = vehicle
        loadVehicleData()
    }

    // MARK: - Load Data from Core Data
    func loadVehicleData() {
        makeModel = activeVehicle.make_model ?? ""
        plateNumber = activeVehicle.plate_number ?? ""
        odometer = String(format: "%.0f", activeVehicle.odometer)
        taxDueDate = activeVehicle.tax_due_date ?? Date()
        stnkDueDate = activeVehicle.stnk_due_date ?? Date()
        serviceName = activeVehicle.service_name ?? ""
        lastServiceDate = activeVehicle.last_service_date ?? Date()
        lastOdometer = String(format: "%.0f", activeVehicle.last_odometer)
    }

    // MARK: - Start Editing
    func startEditing() {
        loadVehicleData()
        isEditing = true
    }

    // MARK: - Update Vehicle
    func updateVehicle() {
        // Validate basic input
        guard !makeModel.isEmpty, !plateNumber.isEmpty else {
            errorMessage = "Make & Model and Plate Number cannot be empty."
            return
        }

        // Apply changes to Core Data entity
        activeVehicle.make_model = makeModel
        activeVehicle.plate_number = plateNumber.uppercased()
        activeVehicle.odometer = Double(odometer) ?? 0
        activeVehicle.tax_due_date = taxDueDate
        activeVehicle.stnk_due_date = stnkDueDate
        activeVehicle.service_name = serviceName
        activeVehicle.last_service_date = lastServiceDate
        activeVehicle.last_odometer = Double(lastOdometer) ?? 0

        do {
            try viewContext.save()
            successMessage = "Vehicle details updated successfully!"
            isEditing = false
        } catch {
            errorMessage = "Failed to save vehicle: \(error.localizedDescription)"
        }
    }

    // MARK: - Delete Vehicle
    func deleteVehicle() {
        viewContext.delete(activeVehicle)
        do {
            try viewContext.save()
            successMessage = "Vehicle deleted successfully."
        } catch {
            errorMessage = "Failed to delete vehicle: \(error.localizedDescription)"
        }
    }

    // MARK: - Computed Helpers
    var formattedOdometer: String {
        if let value = Double(odometer) {
            return String(format: "%.0f km", value)
        }
        return "0 km"
    }

    var formattedTaxDueDate: String {
        format(date: taxDueDate)
    }

    var formattedSTNKDueDate: String {
        format(date: stnkDueDate)
    }

    private func format(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
