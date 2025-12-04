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
    
    // MARK: - Add Vehicle (Fixed with service data)
    func addVehicle(profileVM: ProfileViewModel) async {
        // Clear messages
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
        
        // Create new vehicle
        let newVehicle = Vehicles(context: viewContext)
        newVehicle.vehicles_id = UUID()
        newVehicle.make_model = makeModel.trimmingCharacters(in: .whitespacesAndNewlines)
        newVehicle.vehicle_type = vehicleType
        newVehicle.plate_number = plateNumber.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        newVehicle.year_manufacture = yearManufacture.trimmingCharacters(in: .whitespacesAndNewlines)
        newVehicle.odometer = Double(odometerValue)
        newVehicle.user = user
        
        // ✅ SAVE SERVICE DATA (if provided)
        // SAVE SERVICE DATA TO SERVICE ENTITY
        // SAVE SERVICE DATA TO SERVICE ENTITY
        if !serviceName.isEmpty {

            let firstService = ServiceHistory(context: viewContext)
            firstService.history_id = UUID()
            firstService.service_name = serviceName
            firstService.service_date = lastServiceDate

            // Relasi service ke vehicle
            firstService.vehicle = newVehicle

            // Update vehicle summary fields
            newVehicle.service_name = serviceName
            newVehicle.last_service_date = lastServiceDate
            newVehicle.last_odometer = Double(lastOdometer) ?? 0

            // Hitung next service 6 bulan
            newVehicle.next_service_date =
                Calendar.current.date(byAdding: .month, value: 6, to: lastServiceDate)

            print("✅ First service saved to ServiceHistory:")
            print("   - Name: \(serviceName)")
            print("   - Date: \(lastServiceDate)")
        } else {
            newVehicle.service_name = nil
            newVehicle.last_service_date = nil
            newVehicle.last_odometer = 0
            newVehicle.next_service_date = nil
        }


        
        // Tax date will be set later in detail view
        newVehicle.tax_due_date = nil
        
        // Save to Core Data
        do {
            try viewContext.save()
            print("✅ Vehicle saved successfully: \(makeModel)")
            
            successMessage = "✅ Vehicle added successfully!"
            
            // Show warning about tax date
            warningMessage = "⚠️ Don't forget to add your tax due date in vehicle details"
            
        } catch {
            errorMessage = "❌ Failed to add vehicle: \(error.localizedDescription)"
            print("❌ Core Data save error: \(error)")
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
