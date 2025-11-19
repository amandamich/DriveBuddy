//
//  AddVehicleVM.swift
//  DriveBuddy
//
//  Created by Jennifer Alicia Litan on 03/11/25.
//

import Foundation
import CoreData
import SwiftUI
import Combine
@MainActor
class AddVehicleViewModel: ObservableObject {
    // MARK: - Published Fields (bind to SwiftUI form)
    @Published var makeModel: String = ""
    @Published var vehicleType: String = ""
    @Published var plateNumber: String = ""
    @Published var yearManufacture: String = ""
    @Published var odometer: String = ""
    @Published var taxDueDate: Date = Date()
    @Published var stnkDueDate: Date = Date()
    @Published var lastServiceDate: Date = Date()
    @Published var serviceName: String = ""
    @Published var lastOdometer: String = ""
    @Published var taxReminder: Bool = false

    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    private let context: NSManagedObjectContext
    private let user: User

    // MARK: - Init
    init(context: NSManagedObjectContext, user: User) {
        self.context = context
        self.user = user
    }

    // MARK: - Add Vehicle Function
    func addVehicle() {
        guard !makeModel.isEmpty,
              !vehicleType.isEmpty,
              !plateNumber.isEmpty,
              !yearManufacture.isEmpty else {
            errorMessage = "Please fill in all required fields."
            return
        }

        let newVehicle = Vehicles(context: context)
        newVehicle.vehicles_id = UUID()
        newVehicle.make_model = makeModel
        newVehicle.vehicle_type = vehicleType
        newVehicle.plate_number = plateNumber.uppercased()
        newVehicle.year_manufacture = yearManufacture
        newVehicle.odometer = Double(odometer) ?? 0
        newVehicle.tax_due_date = taxDueDate
        newVehicle.stnk_due_date = stnkDueDate
        newVehicle.last_service_date = lastServiceDate
        newVehicle.service_name = serviceName
        newVehicle.created_at = Date()
        newVehicle.user = user
        newVehicle.tax_reminder = taxReminder
        newVehicle.last_odometer = Double(lastOdometer) ?? 0
        print("Created vehicle with ID:", newVehicle.vehicles_id!)

        do {
            try context.save()
            successMessage = "Vehicle added successfully!"
            clearFields()
        } catch {
            errorMessage = "Failed to save vehicle: \(error.localizedDescription)"
        }
    }

    // MARK: - Clear Input Fields
    private func clearFields() {
        makeModel = ""
        vehicleType = ""
        plateNumber = ""
        yearManufacture = ""
        odometer = ""
        serviceName = ""
        taxDueDate = Date()
        stnkDueDate = Date()
        lastServiceDate = Date()
        lastOdometer = ""
        taxReminder = false
        
    }
}
