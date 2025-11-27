//
//  VehicleManagerVM.swift
//  DriveBuddy
//
//  Created by student on 27/11/25.
//

import Foundation
import CoreData
import Combine

@MainActor
class VehicleManagerVM: ObservableObject {
    static let shared = VehicleManagerVM()
    
    @Published var vehicles: [Vehicle] = []
    
    private let context: NSManagedObjectContext
    
    private init() {
        self.context = PersistenceController.shared.container.viewContext
        loadVehicles()
    }
    
    // MARK: - Load Vehicles from Core Data
    func loadVehicles() {
        let request: NSFetchRequest<Vehicles> = Vehicles.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Vehicles.created_at, ascending: false)]
        
        do {
            let coreDataVehicles = try context.fetch(request)
            
            // Convert Core Data Vehicles to Vehicle struct
            self.vehicles = coreDataVehicles.compactMap { cdVehicle -> Vehicle? in
                guard let id = cdVehicle.vehicles_id,
                      let makeModel = cdVehicle.make_model,
                      let vehicleType = cdVehicle.vehicle_type,
                      let plateNumber = cdVehicle.plate_number,
                      let year = cdVehicle.year_manufacture,
                      let taxDate = cdVehicle.tax_due_date else {
                    return nil
                }
                
                return Vehicle(
                    id: id,
                    makeAndModel: makeModel,
                    vehicleType: vehicleType,
                    licensePlate: plateNumber,
                    year: year,
                    odometer: String(format: "%.0f", cdVehicle.odometer),
                    taxDate: taxDate
                )
            }
            
            print("✅ Loaded \(vehicles.count) vehicles from Core Data")
        } catch {
            print("❌ Failed to load vehicles: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Get Vehicle by Plate
    func getVehicleByPlate(_ plate: String) -> Vehicle? {
        return vehicles.first { $0.licensePlate == plate }
    }
    
    // MARK: - Get Vehicle by ID
    func getVehicleById(_ id: UUID) -> Vehicle? {
        return vehicles.first { $0.id == id }
    }
    
    // MARK: - Refresh vehicles (call after adding/updating)
    func refresh() {
        loadVehicles()
    }
}
