import Foundation
import CoreData
import Combine
import SwiftUI

@MainActor
class AddServiceViewModel: ObservableObject {

    @Published var serviceName: String = ""
    @Published var selectedDate: Date = Date()
    @Published var odometer: String = ""
    @Published var reminder: String = "One month before"
    @Published var addToReminder: Bool = true

    @Published var successMessage: String?
    @Published var errorMessage: String?

    let reminderOptions = ["One week before", "Two weeks before", "One month before"]

    private let viewContext: NSManagedObjectContext
    private let vehicle: Vehicles
    private let profileVM: ProfileViewModel

    init(context: NSManagedObjectContext, vehicle: Vehicles, profileVM: ProfileViewModel) {
        self.viewContext = context
        self.vehicle = vehicle
        self.profileVM = profileVM
    }
    
    // MARK: - Convert reminder label → number of days
    var daysBeforeReminder: Int16 {
        switch reminder {
        case "One week before": return 7
        case "Two weeks before": return 14
        case "One month before": return 30
        default: return 7
        }
    }

    func addService() {
        successMessage = nil
        errorMessage = nil

        guard !serviceName.isEmpty else {
            errorMessage = "Please enter the service name."
            return
        }

        guard !odometer.isEmpty, let odometerValue = Double(odometer) else {
            errorMessage = "Please enter a valid odometer value."
            return
        }

        // === CREATE NEW SERVICE HISTORY ===
        let newService = ServiceHistory(context: viewContext)
        newService.history_id = UUID()
        newService.service_name = serviceName
        newService.service_date = selectedDate
        newService.odometer = odometerValue
        newService.created_at = Date()
        newService.vehicle = vehicle
        
        // ==============================
        //       Update Vehicle fields
        // ==============================
        vehicle.last_service_date = selectedDate

        // Next service = 5 bulan dari tanggal ini
                if let nextService = Calendar.current.date(byAdding: .month, value: 5, to: selectedDate) {
                    vehicle.next_service_date = nextService
                }
                
                // Reminder offset
                vehicle.service_reminder_offset = daysBeforeReminder

        // ==============================
        //       Save context
        // ==============================

        do {
            try viewContext.save()
            successMessage = "Service added successfully!"

            // === OPTIONAL: Schedule real notification ===
            if addToReminder {
                Task {
                    await profileVM.scheduleServiceReminder(
                        serviceId: newService.history_id!,
                        serviceName: newService.service_name ?? "Vehicle Service",
                        vehicleName: vehicle.make_model ?? "Your Vehicle",
                        serviceDate: newService.service_date ?? Date(),
                        daysBeforeReminder: Int(daysBeforeReminder)
                    )
                }
            }


            clearFields()

        } catch {
            errorMessage = "Failed to save service: \(error.localizedDescription)"
        }
    }
    // MARK: - RESET FORM
       private func clearFields() {
           serviceName = ""
           selectedDate = Date()
           odometer = ""
           reminder = "One month before"
           addToReminder = true
       }
}

