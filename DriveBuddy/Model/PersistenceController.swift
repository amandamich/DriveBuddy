//
//  PersistenceController.swift
//  DriveBuddy
//
//  Created by Timothy on 28/10/25.
//


import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    // untuk prevew di VehicleDetailView
    static var preview: PersistenceController = {
            let result = PersistenceController(inMemory: true)
            let viewContext = result.container.viewContext

            // --- TAMBAHKAN DUMMY DATA KE CONTEXT ---
            // Contoh: Membuat satu Vehicles untuk Preview
            let newVehicle = Vehicles(context: viewContext)
            newVehicle.make_model = "Avanza Merah"
            newVehicle.plate_number = "N 1234 XX"
            newVehicle.odometer = 50000
            newVehicle.tax_due_date = Date().addingTimeInterval(86400 * 30) // 30 hari dari sekarang

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
            // --- AKHIR DUMMY DATA ---
            
            return result
        }()
    
    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "DriveBuddyModel")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
}
