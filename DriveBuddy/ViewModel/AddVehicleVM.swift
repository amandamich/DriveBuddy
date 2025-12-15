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
    
    // MARK: - Add Vehicle (Fixed - proper date handling)
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
        if !serviceName.isEmpty {
            // ✅ CRITICAL FIX: Normalize date to start of day for proper comparison
            let calendar = Calendar.current
            let normalizedServiceDate = calendar.startOfDay(for: lastServiceDate)
            
            let firstService = ServiceHistory(context: viewContext)
            firstService.history_id = UUID()
            firstService.service_name = serviceName
            firstService.service_date = normalizedServiceDate // ✅ Use normalized date
            firstService.created_at = Date()
            
            // ✅ Save the odometer value for completed service
            if let lastOdometerValue = Double(lastOdometer), lastOdometerValue > 0 {
                firstService.odometer = lastOdometerValue
                print("✅ Using lastOdometer: \(lastOdometerValue) km")
            } else {
                firstService.odometer = Double(odometerValue)
                print("⚠️ lastOdometer empty, using vehicle odometer: \(odometerValue) km")
            }
            
            // ✅ Save reminder preference (default to 7 days)
            firstService.reminder_days_before = 7

            // Relate service to vehicle
            firstService.vehicle = newVehicle

            // Update vehicle summary fields
            newVehicle.service_name = serviceName
            newVehicle.last_service_date = normalizedServiceDate // ✅ Use normalized date
            newVehicle.last_odometer = firstService.odometer

            // Calculate next service date (6 months from last service)
            newVehicle.next_service_date = calendar.date(byAdding: .month, value: 6, to: normalizedServiceDate)

            print("✅ First service saved to ServiceHistory:")
            print("   - Name: \(serviceName)")
            print("   - Date (normalized): \(normalizedServiceDate)")
            print("   - Odometer: \(firstService.odometer) km")
            
            // ✅ IMPROVED: Check if service is in the past (before today's start)
            let todayStart = calendar.startOfDay(for: Date())
            let isPastService = normalizedServiceDate < todayStart
            
            print("📊 Date comparison:")
            print("   - Service date: \(normalizedServiceDate)")
            print("   - Today start: \(todayStart)")
            print("   - Is past? \(isPastService)")
            
            if isPastService {
                print("🔄 Service is in the past, auto-creating upcoming service...")
                autoCreateUpcomingService(
                    for: newVehicle,
                    basedOn: normalizedServiceDate,
                    serviceName: serviceName
                )
            } else {
                print("⏭️ Service is today or in the future, no need to auto-create")
            }

            // Add to calendar if user enables it
            if profileVM.user?.add_to_calendar == true {
                Task {
                    // Add the service to calendar
                    try? await profileVM.addCalendarEvent(
                        title: "🔧 Service: \(serviceName)",
                        notes: "Scheduled service for \(makeModel)\nOdometer: \(Int(firstService.odometer)) km",
                        startDate: normalizedServiceDate,
                        alarmOffsetDays: 7
                    )
                    
                    // ✅ If we auto-created an upcoming service, sync it too
                    if isPastService {
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        await profileVM.syncAllVehiclesToCalendar()
                    }
                }
            }
        }

        // Tax date will be set later in detail view
        newVehicle.tax_due_date = nil

        // Save to Core Data
        do {
            try viewContext.save()
            viewContext.processPendingChanges()
            print("✅ Vehicle saved successfully: \(makeModel)")
            successMessage = "✅ Vehicle added successfully!"

            // Show warning about tax date
            warningMessage = "⚠️ Don't forget to add your tax due date in vehicle details"
        } catch {
            errorMessage = "❌ Failed to add vehicle: \(error.localizedDescription)"
            print("❌ Core Data save error: \(error)")
        }
    }
    
    // ✅ Auto-create upcoming service WITHOUT odometer
    private func autoCreateUpcomingService(for vehicle: Vehicles, basedOn pastDate: Date, serviceName: String) {
        // Validate service name
        guard !serviceName.trimmingCharacters(in: .whitespaces).isEmpty else {
            print("❌ Cannot create service with empty name")
            return
        }
        
        // Check if there's already a future service with the SAME NAME
        let futureRequest: NSFetchRequest<ServiceHistory> = ServiceHistory.fetchRequest()
        futureRequest.predicate = NSPredicate(
            format: "vehicle == %@ AND service_name ==[c] %@ AND service_date > %@",
            vehicle,
            serviceName as CVarArg,
            Date() as NSDate
        )
        
        do {
            let existingFutureServices = try viewContext.fetch(futureRequest)
            if !existingFutureServices.isEmpty {
                print("ℹ️ Future '\(serviceName)' already exists, skipping auto-create")
                for existing in existingFutureServices {
                    print("   - Existing: '\(existing.service_name ?? "NO NAME")' on \(existing.service_date?.description ?? "N/A")")
                }
                return
            }
        } catch {
            print("❌ Failed to check for future services: \(error)")
            return
        }
        
        // Calculate next service date (6 months from the past service)
        guard let nextDate = Calendar.current.date(byAdding: .month, value: 6, to: pastDate) else {
            print("❌ Failed to calculate next service date")
            return
        }
        
        print("📝 Creating upcoming '\(serviceName)' for \(nextDate)")
        
        // ✅ Create upcoming service with odometer = 0 (user will input manually)
        let upcomingService = ServiceHistory(context: viewContext)
        upcomingService.history_id = UUID()
        upcomingService.service_name = serviceName
        upcomingService.service_date = nextDate
        upcomingService.odometer = 0 // ✅ Set to 0, user inputs manually
        upcomingService.created_at = Date()
        upcomingService.reminder_days_before = 7
        upcomingService.vehicle = vehicle
        
        print("   Service ID: \(upcomingService.history_id?.uuidString ?? "nil")")
        print("   Name: '\(upcomingService.service_name ?? "nil")'")
        print("   Date: \(upcomingService.service_date?.description ?? "nil")")
        print("   Odometer: 0 km (manual input required)")
        
        do {
            try viewContext.save()
            viewContext.processPendingChanges()
            print("✅ Auto-created upcoming '\(serviceName)' successfully")
            
            // Verify it was saved
            let verifyRequest: NSFetchRequest<ServiceHistory> = ServiceHistory.fetchRequest()
            verifyRequest.predicate = NSPredicate(format: "vehicle == %@", vehicle)
            let allServices = try viewContext.fetch(verifyRequest)
            print("📊 Total services for this vehicle: \(allServices.count)")
            
            let todayStart = Calendar.current.startOfDay(for: Date())
            for (index, service) in allServices.enumerated() {
                let serviceDate = service.service_date ?? Date()
                let serviceStart = Calendar.current.startOfDay(for: serviceDate)
                let isPast = serviceStart < todayStart
                print("   \(index + 1). '\(service.service_name ?? "nil")' - [\(isPast ? "COMPLETED" : "UPCOMING")] - \(serviceStart) - \(Int(service.odometer)) km")
            }
        } catch {
            print("❌ Failed to auto-create upcoming service: \(error)")
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
