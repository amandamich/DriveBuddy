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
        print("🏁 AddServiceViewModel initialized")
        self.viewContext = context
        self.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        self.vehicle = vehicle
        self.profileVM = profileVM
    }

    func addService() {

        successMessage = nil
        errorMessage = nil

        // validation
        guard !serviceName.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter the service name."
            return
        }

        guard let odometerValue = Double(odometer) else {
            errorMessage = "Please enter a valid odometer value."
            return
        }

        print("\n🔴 addService() CALLED")

        // MARK: Create new ServiceHistory
        let newService = ServiceHistory(context: viewContext)
        newService.history_id = UUID()
        newService.service_name = serviceName.trimmingCharacters(in: .whitespacesAndNewlines)
        newService.service_date = selectedDate
        newService.odometer = odometerValue
        newService.created_at = Date()
        newService.vehicle = vehicle
        newService.reminder_days_before = Int16(daysBeforeReminder)

        let isPastService = selectedDate < Date()

        // save next service date on ServiceHistory
        if let nextDate = Calendar.current.date(byAdding: .month, value: 6, to: selectedDate) {
            newService.next_service_date = nextDate
        }

        // MARK: Store reminder offset on VEHICLE
        switch reminder {
        case "One week before": vehicle.service_reminder_offset = 7
        case "Two weeks before": vehicle.service_reminder_offset = 14
        case "One month before": vehicle.service_reminder_offset = 30
        default: vehicle.service_reminder_offset = 7
        }

        // MARK: Update VEHICLE summary
        vehicle.last_service_date = selectedDate
        vehicle.service_name = newService.service_name
        vehicle.last_odometer = odometerValue

        if let nextDate = Calendar.current.date(byAdding: .month, value: 6, to: selectedDate) {
            vehicle.next_service_date = nextDate
        }

        do {
            try viewContext.save()
            viewContext.processPendingChanges()

            // if past → auto create next service
            if isPastService {
                autoCreateUpcomingServiceIfNeeded()

                if addToReminder && profileVM.user?.add_to_calendar == true {
                    Task {
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        await profileVM.syncAllVehiclesToCalendar()
                    }
                }
            }

            // add reminders
            if addToReminder {
                Task {
                    await profileVM.scheduleServiceReminder(
                        serviceId: newService.history_id!,
                        serviceName: newService.service_name ?? "Vehicle Service",
                        vehicleName: vehicle.make_model ?? "Your Vehicle",
                        serviceDate: newService.service_date ?? Date(),
                        daysBeforeReminder: daysBeforeReminder
                    )

                    if profileVM.user?.add_to_calendar == true {
                        try? await profileVM.addCalendarEvent(
                            title: "🔧 Service: \(newService.service_name ?? "Service")",
                            notes: "Scheduled service for \(vehicle.make_model ?? "Vehicle")",
                            startDate: newService.service_date ?? Date(),
                            alarmOffsetDays: daysBeforeReminder
                        )
                    }
                }
            }

            successMessage = "Service added successfully!"
            clearFields()

        } catch {
            errorMessage = "Failed to save service: \(error.localizedDescription)"
        }
    }

    // MARK: Auto-create upcoming service
    private func autoCreateUpcomingServiceIfNeeded() {

        guard selectedDate < Date() else { return }

        let req: NSFetchRequest<ServiceHistory> = ServiceHistory.fetchRequest()
        req.predicate = NSPredicate(format: "vehicle == %@ AND service_date > %@", vehicle, Date() as NSDate)

        if let future = try? viewContext.fetch(req), !future.isEmpty {
            return
        }

        guard let nextDate = Calendar.current.date(byAdding: .month, value: 6, to: selectedDate) else { return }

        let upcoming = ServiceHistory(context: viewContext)
        upcoming.history_id = UUID()
        upcoming.service_name = "Scheduled Maintenance"
        upcoming.service_date = nextDate
        upcoming.odometer = 0
        upcoming.created_at = Date()
        upcoming.vehicle = vehicle
        upcoming.reminder_days_before = Int16(daysBeforeReminder)
        upcoming.next_service_date = Calendar.current.date(byAdding: .month, value: 6, to: nextDate)

        do {
            try viewContext.save()
            viewContext.processPendingChanges()
        } catch {
            print("❌ Failed auto-create: \(error)")
        }
    }

    var daysBeforeReminder: Int {
        switch reminder {
