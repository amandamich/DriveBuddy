//
//  VehicleDetailViewModel.swift
//  DriveBuddy
//

import Foundation
import CoreData
import SwiftUI
import Combine
import EventKit

@MainActor
class VehicleDetailViewModel: ObservableObject {
    
    private let context: NSManagedObjectContext
    private let eventStore = EKEventStore()
    
    // MARK: - Core Model
    @Published var activeVehicle: Vehicles
    let activeUser: User
    
    // MARK: - Form Bindings
    @Published var makeModel: String = ""
    @Published var plateNumber: String = ""
    @Published var odometer: String = ""
    @Published var taxDueDate: Date = Date()
    @Published var stnkDueDate: Date = Date()
    @Published var serviceName: String = ""
    @Published var lastServiceDate: Date = Date()
    @Published var lastOdometer: String = ""
    
    // MARK: - Tax Date Management
    @Published var showingTaxDatePicker = false
    @Published var tempTaxDate: Date = Date()
    @Published var hasTaxDate: Bool = false
    
    // MARK: - UI States
    @Published var isEditing: Bool = false
    @Published var isShowingDeleteConfirmation: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    var isShowingError: Bool { errorMessage != nil }
    
    // MARK: - Service History List (for UI)
    @Published var serviceHistories: [ServiceHistory] = []
    
    // ✅ FIXED: Published computed properties for UI binding
    @Published var latestServiceName: String = "No service recorded"
    @Published var latestServiceDate: Date? = nil
    @Published var upcomingServiceName: String = "No service scheduled"
    @Published var upcomingServiceDate: Date? = nil
    @Published var latestServiceOdometer: Double? = nil

    // ✅ FIXED: Compare actual date/time, not just day
    private func isDateInPast(_ date: Date) -> Bool {
        return date < Date()
    }
    
    private func isDateInFuture(_ date: Date) -> Bool {
        return date > Date()
    }

    // ✅ FIXED: Fetch and immediately update published properties
    func fetchServiceHistory() {
        let request: NSFetchRequest<ServiceHistory> = ServiceHistory.fetchRequest()
        request.predicate = NSPredicate(format: "vehicle == %@", activeVehicle)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ServiceHistory.service_date, ascending: false)]
        
        do {
            serviceHistories = try context.fetch(request)
            
            print("\n📋 LOADED \(serviceHistories.count) SERVICES:")
            for service in serviceHistories {
                let serviceDate = service.service_date ?? Date()
                let isPast = isDateInPast(serviceDate)
                print("- \(service.service_name ?? "NO NAME")")
                print("  Date: \(serviceDate)")
                print("  Status: [\(isPast ? "PAST" : "FUTURE")]")
            }
            
            // ✅ FIXED: Immediately update computed properties
            updateComputedProperties()
            
        } catch {
            print("❌ Failed to fetch service history: \(error)")
            serviceHistories = []
            updateComputedProperties()
        }
    }
    
    // ✅ NEW: Centralized method to update all computed properties
    private func updateComputedProperties() {
        // Update latest completed service
        let completed = serviceHistories.filter { service in
            guard let date = service.service_date else { return false }
            return isDateInPast(date)
        }.first
        
        if let service = completed {
            latestServiceName = service.service_name?.isEmpty == false ? service.service_name! : "Service Record"
            latestServiceDate = service.service_date
            latestServiceOdometer = service.odometer
        } else {
            latestServiceName = "No service recorded"
            latestServiceDate = nil
            latestServiceOdometer = nil
        }
        
        // Update upcoming service
        let upcoming = serviceHistories.filter { service in
            guard let date = service.service_date else { return false }
            return isDateInFuture(date)
        }.sorted {
            ($0.service_date ?? .distantFuture) < ($1.service_date ?? .distantFuture)
        }.first
        
        if let service = upcoming {
            upcomingServiceName = service.service_name?.isEmpty == false ? service.service_name! : "Scheduled Service"
            upcomingServiceDate = service.service_date
        } else {
            // ✅ If no upcoming service in database, show calculated next service
            if let calculatedDate = calculatedNextServiceDate {
                upcomingServiceName = "Scheduled Service"
                upcomingServiceDate = calculatedDate
            } else {
                upcomingServiceName = "No service scheduled"
                upcomingServiceDate = nil
            }
        }
        
        print("\n📊 Updated Properties:")
        print("Latest: \(latestServiceName) on \(latestServiceDate?.description ?? "N/A")")
        print("Upcoming: \(upcomingServiceName) on \(upcomingServiceDate?.description ?? "N/A")")
        if let calc = calculatedNextServiceDate {
            print("Calculated next service: \(calc.description)")
        }
    }

    // MARK: - Init
    init(context: NSManagedObjectContext, vehicle: Vehicles, activeUser: User) {
        self.context = context
        self.context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        self.activeVehicle = vehicle
        self.activeUser = activeUser
        
        if let existingDate = vehicle.tax_due_date {
            self.tempTaxDate = existingDate
            self.hasTaxDate = true
        } else {
            self.tempTaxDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
            self.hasTaxDate = false
        }
        
        // ✅ FIXED: Load data after all properties are initialized
        loadVehicleData()
    }

    // MARK: - Load Data
    func loadVehicleData() {
        print("\n🔄 Loading vehicle data...")
        
        // ✅ Force refresh from persistent store
        context.refreshAllObjects()
        context.refresh(activeVehicle, mergeChanges: true)
        
        // ✅ Fetch service history AFTER refreshing context
        fetchServiceHistory()
        
        makeModel = activeVehicle.make_model ?? ""
        plateNumber = activeVehicle.plate_number ?? ""
        odometer = String(format: "%.0f", activeVehicle.odometer)
        taxDueDate = activeVehicle.tax_due_date ?? Date()
        stnkDueDate = activeVehicle.stnk_due_date ?? Date()
        
        // ✅ Load from latest completed service for editing
        serviceName = latestService?.service_name ?? ""
        lastServiceDate = latestService?.service_date ?? Date()
        lastOdometer = String(format: "%.0f", latestService?.odometer ?? activeVehicle.odometer)
        
        hasTaxDate = activeVehicle.tax_due_date != nil
        
        print("✅ Vehicle data loaded")
    }

    // MARK: - Start Editing
    func startEditing() {
        loadVehicleData()
        isEditing = true
    }

    // MARK: - Update Vehicle
    func updateVehicle() {
        guard !makeModel.isEmpty, !plateNumber.isEmpty else {
            errorMessage = "Make & Model and Plate Number cannot be empty."
            return
        }

        activeVehicle.make_model = makeModel
        activeVehicle.plate_number = plateNumber.uppercased()
        activeVehicle.odometer = Double(odometer) ?? 0
        activeVehicle.tax_due_date = taxDueDate
        activeVehicle.stnk_due_date = stnkDueDate
        activeVehicle.user = activeUser
        
        // ✅ FIXED: Only update the LATEST COMPLETED service history entry
        let completed = serviceHistories.filter { service in
            guard let date = service.service_date else { return false }
            return isDateInPast(date)
        }.first
        
        if let latestService = completed {
            latestService.service_name = serviceName
            latestService.service_date = lastServiceDate
            latestService.odometer = Double(lastOdometer) ?? 0
            print("✅ Updated existing service history entry")
        }

        do {
            try context.save()
            print("SUCCESS: Vehicle updated")
            context.refresh(activeVehicle, mergeChanges: false)
            loadVehicleData()
            successMessage = "Vehicle updated successfully!"
            isEditing = false
        } catch {
            print("SAVE FAILED: \(error.localizedDescription)")
            errorMessage = "Failed to save vehicle: \(error.localizedDescription)"
        }
    }

    // MARK: - Tax Updates
    func updateTaxDueDate() async {
        successMessage = nil
        errorMessage = nil
        
        activeVehicle.tax_due_date = tempTaxDate
        taxDueDate = tempTaxDate
        hasTaxDate = true
        
        do {
            try context.save()
            print("Tax date updated")
            context.refresh(activeVehicle, mergeChanges: false)
            await requestCalendarAccessAndAddEvent()
            successMessage = "Tax due date updated!"
            showingTaxDatePicker = false
        } catch {
            errorMessage = "Failed to update tax date: \(error.localizedDescription)"
        }
    }

    func removeTaxDueDate() {
        activeVehicle.tax_due_date = nil
        hasTaxDate = false
        
        do {
            try context.save()
            context.refresh(activeVehicle, mergeChanges: false)
            successMessage = "Tax date removed"
            showingTaxDatePicker = false
            Task { await removeExistingTaxReminder() }
        } catch {
            errorMessage = "Failed to remove tax date: \(error.localizedDescription)"
        }
    }

    // MARK: - Calendar
    private func requestCalendarAccessAndAddEvent() async {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            if granted { await addTaxReminderToCalendar() }
        } catch {
            print("Calendar access error: \(error)")
        }
    }

    private func addTaxReminderToCalendar() async {
        guard let taxDate = activeVehicle.tax_due_date else { return }
        await removeExistingTaxReminder()
        
        let event = EKEvent(eventStore: eventStore)
        event.title = "Vehicle Tax Due: \(activeVehicle.make_model ?? "Vehicle")"
        event.notes = "Vehicle: \(activeVehicle.make_model ?? "Unknown")\nPlate: \(activeVehicle.plate_number ?? "Unknown")"
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        let reminderDate = Calendar.current.date(byAdding: .day, value: -7, to: taxDate) ?? taxDate
        event.startDate = reminderDate
        event.endDate = reminderDate.addingTimeInterval(3600)
        event.isAllDay = true
        event.addAlarm(EKAlarm(relativeOffset: -86400))
        
        do { try eventStore.save(event, span: .thisEvent) } catch {
            print("Failed to save event: \(error)")
        }
    }

    private func removeExistingTaxReminder() async {
        let startDate = Date().addingTimeInterval(-365*24*3600)
        let endDate = Date().addingTimeInterval(365*24*3600)
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let events = eventStore.events(matching: predicate)
        
        for event in events {
            if event.title.contains(activeVehicle.make_model ?? "") && event.title.contains("Vehicle Tax Due") {
                try? eventStore.remove(event, span: .thisEvent)
            }
        }
    }

    // MARK: - Delete Vehicle
    func deleteVehicle() {
        Task { await removeExistingTaxReminder() }
        context.delete(activeVehicle)
        do {
            try context.save()
            successMessage = "Vehicle deleted"
        } catch {
            errorMessage = "Failed to delete: \(error.localizedDescription)"
        }
    }

    // MARK: - Create New Vehicle
    func createNewVehicle(makeModel: String, plateNumber: String) {
        let newVehicle = Vehicles(context: context)
        newVehicle.make_model = makeModel
        newVehicle.plate_number = plateNumber
        newVehicle.user = activeUser
        
        do {
            try context.save()
            self.activeVehicle = newVehicle
        } catch {
            errorMessage = "Failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Tax Status
    func getTaxStatus() -> (status: String, color: Color) {
        guard let taxDate = activeVehicle.tax_due_date else {
            return ("Unknown", .gray)
        }
        
        let today = Date()
        let days = Calendar.current.dateComponents([.day], from: today, to: taxDate).day ?? 0
        
        if days < 0 { return ("Overdue", .red) }
        if days <= 30 { return ("Due Soon", .orange) }
        return ("Up to Date", .green)
    }
    
    var latestService: ServiceHistory? {
        if let set = activeVehicle.servicehistory as? Set<ServiceHistory> {
            return set.sorted {
                ($0.service_date ?? .distantPast) > ($1.service_date ?? .distantPast)
            }.first
        }
        return nil
    }

    var nextServiceDate: Date? {
        upcomingServiceDate ?? activeVehicle.next_service_date ?? calculatedNextServiceDate
    }
    
    // ✅ Calculate next service date based on last service (6 months later)
    var calculatedNextServiceDate: Date? {
        guard let lastDate = latestServiceDate else { return nil }
        return Calendar.current.date(byAdding: .month, value: 6, to: lastDate)
    }

    // MARK: - Helpers
    var formattedOdometer: String {
        if let value = Double(odometer) {
            return String(format: "%.0f km", value)
        }
        return "0 km"
    }

    var formattedTaxDueDate: String { format(date: taxDueDate) }
    var formattedSTNKDueDate: String { format(date: stnkDueDate) }

    private func format(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    func formatDate(_ date: Date?) -> String {
        guard let date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date)
    }
    // MARK: - Service History Helpers

    /// Get the last N completed services
    func getLastServices(limit: Int = 3) -> [ServiceHistory] {
        let completed = serviceHistories.filter { service in
            guard let date = service.service_date else { return false }
            return isDateInPast(date)
        }
        return Array(completed.prefix(limit))
    }

    /// Get total count of completed services
    func getTotalCompletedServices() -> Int {
        return serviceHistories.filter { service in
            guard let date = service.service_date else { return false }
            return isDateInPast(date)
        }.count
    }

    /// Get upcoming services (returns array of name and date tuples)
    func getUpcomingServices() -> [(name: String, date: Date)] {
        let upcoming = serviceHistories.filter { service in
            guard let date = service.service_date else { return false }
            return isDateInFuture(date)
        }.sorted {
            ($0.service_date ?? .distantFuture) < ($1.service_date ?? .distantFuture)
        }
        
        // Return array of (name, date) tuples
        return upcoming.map { service in
            let name = service.service_name?.isEmpty == false ? service.service_name! : "Scheduled Service"
            let date = service.service_date ?? Date()
            return (name: name, date: date)
        }
    }

    /// Check if there are multiple services on the same date
    func hasMultipleServicesOnSameDate(_ targetDate: Date) -> Bool {
        let calendar = Calendar.current
        let servicesOnDate = serviceHistories.filter { service in
            guard let serviceDate = service.service_date else { return false }
            return calendar.isDate(serviceDate, inSameDayAs: targetDate)
        }
        return servicesOnDate.count > 1
    }
}
