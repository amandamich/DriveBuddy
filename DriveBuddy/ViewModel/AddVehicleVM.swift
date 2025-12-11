import Foundation
import CoreData
import SwiftUI
import Combine

@MainActor
class AddVehicleViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var makeModel: String = ""
    @Published var vehicleType: String = ""
    @Published var plateNumber: String = ""
    @Published var yearManufacture: String = ""
    @Published var odometer: String = ""
    @Published var lastServiceDate: Date = Date()
    @Published var serviceName: String = ""
    @Published var lastOdometer: String = ""
    
    @Published var successMessage: String?
    @Published var errorMessage: String?
    @Published var warningMessage: String?
    
    private let viewContext: NSManagedObjectContext
    private let user: User
    
    init(context: NSManagedObjectContext, user: User) {
        self.viewContext = context
        self.user = user
    }
    
    // MARK: - Add Vehicle
    func addVehicle(profileVM: ProfileViewModel) async {
        successMessage = nil
        errorMessage = nil
        warningMessage = nil

        // Validation
        guard !makeModel.isEmpty else {
            errorMessage = "Please enter vehicle make and model"
            return
        }
        guard !vehicleType.isEmpty else {
            errorMessage = "Please select vehicle type"
            return
        }
        guard !plateNumber.isEmpty else {
            errorMessage = "Please enter license plate number"
            return
        }
        guard let odometerValue = Int64(odometer), odometerValue > 0 else {
            errorMessage = "Please enter a valid odometer reading"
            return
        }

        // Create Vehicle
        let newVehicle = Vehicles(context: viewContext)
        newVehicle.vehicles_id = UUID()
        newVehicle.make_model = makeModel.trimmingCharacters(in: .whitespacesAndNewlines)
        newVehicle.vehicle_type = vehicleType
        newVehicle.plate_number = plateNumber.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        newVehicle.year_manufacture = yearManufacture.trimmingCharacters(in: .whitespacesAndNewlines)
        newVehicle.odometer = Double(odometerValue)
        newVehicle.user = user

        // MARK: - FIRST SERVICE (optional)
        if !serviceName.trimmingCharacters(in: .whitespaces).isEmpty {

            let firstService = ServiceHistory(context: viewContext)
            firstService.history_id = UUID()
            firstService.service_name = serviceName.trimmingCharacters(in: .whitespacesAndNewlines)
            firstService.service_date = lastServiceDate
            firstService.created_at = Date()
            firstService.vehicle = newVehicle
            
            // Odometer input
            if let lastOdoValue = Double(lastOdometer), lastOdoValue > 0 {
                firstService.odometer = lastOdoValue
            } else {
                firstService.odometer = Double(odometerValue)
            }
            
            // Default reminder_days_before (allowed if field exists)
            firstService.reminder_days_before = 7
            
            // Next service date
            if let nextDate = Calendar.current.date(byAdding: .month, value: 6, to: lastServiceDate) {
                firstService.next_service_date = nextDate
                newVehicle.next_service_date = nextDate
            }

            // MARK: Update Vehicle Summary
            newVehicle.service_name = firstService.service_name
            newVehicle.last_service_date = firstService.service_date
            newVehicle.last_odometer = firstService.odometer
            newVehicle.service_reminder_offset = 30 // default offset

            // Sync to calendar if user enables it
            if profileVM.user?.add_to_calendar == true {
                Task {
                    try? await profileVM.addCalendarEvent(
                        title: "🔧 Service: \(serviceName)",
                        notes: "Scheduled service for \(makeModel)\nOdometer: \(Int(firstService.odometer)) km",
                        startDate: lastServiceDate,
                        alarmOffsetDays: 7
                    )
                }
            }

        } else {
            // No service entered during vehicle creation
            newVehicle.service_name = nil
            newVehicle.last_service_date = nil
            newVehicle.last_odometer = 0
            newVehicle.next_service_date = nil
        }

        newVehicle.tax_due_date = nil

        // Save to CoreData
        do {
            try viewContext.save()
            print("✅ Vehicle saved successfully: \(makeModel)")
            successMessage = "Vehicle added successfully!"

            warningMessage = "⚠️ Don't forget to add your tax due date in vehicle details"
            
        } catch {
            errorMessage = "Failed to add vehicle: \(error.localizedDescription)"
            print("❌ CoreData error: \(error)")
        }
    }

    // MARK: - Reset Form
    func resetForm() {
        makeModel = ""
        vehicleType = ""
        plateNumber = ""
        yearManufacture = ""
        odometer = ""
        lastServiceDate = Date()
        serviceName = ""
        lastOdometer = ""
        successMessage = nil
        errorMessage = nil
        warningMessage = nil
    }
}
