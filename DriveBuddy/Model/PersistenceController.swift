import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    // untuk preview di VehicleDetailView
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        // --- TAMBAHKAN DUMMY DATA KE CONTEXT ---
        let newVehicle = Vehicles(context: viewContext)
        newVehicle.vehicles_id = UUID()
        newVehicle.make_model = "Avanza Merah"
        newVehicle.plate_number = "N 1234 XX"
        newVehicle.odometer = 50000
        newVehicle.tax_due_date = Date().addingTimeInterval(86400 * 30)

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
        return result
    }()
    
    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "DriveBuddyModel")
        if inMemory {
                            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
                        } else {
                            // ✅ ADD THIS: Delete old store before loading
                            if let storeURL = container.persistentStoreDescriptions.first?.url {
                                try? FileManager.default.removeItem(at: storeURL)
                                print("🗑️ Old database deleted")
                            }
                        }
        // Enable automatic lightweight migration
        if let description = container.persistentStoreDescriptions.first {
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
        }
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
}
