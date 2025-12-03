//
//  VehicleDetailViewModel.swift
//  DriveBuddy
//
//  Created by Jennifer Alicia Litan on 03/11/25.
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

    // Fetch service history from the activeVehicle relationship
    func fetchServiceHistory() {
        // relationship name MUST match your data model: "servicehistory"
        if let set = activeVehicle.servicehistory as? Set<ServiceHistory> {
            // sort by service_date descending (newest first)
            serviceHistories = set.sorted {
                let d0 = $0.service_date ?? Date.distantPast
                let d1 = $1.service_date ?? Date.distantPast
                return d0 > d1
            }
        } else {
            serviceHistories = []
        }
    }

    // MARK: - Init
    init(context: NSManagedObjectContext, vehicle: Vehicles, activeUser: User) {
        self.context = context
        self.context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        self.activeVehicle = vehicle
        self.activeUser = activeUser
        loadVehicleData()
        
        if let existingDate = vehicle.tax_due_date {
            self.tempTaxDate = existingDate
            self.hasTaxDate = true
        } else {
            self.tempTaxDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
            self.hasTaxDate = false
        }
        fetchServiceHistory()
    }

    // MARK: - Load Data
    func loadVehicleData() {
        makeModel = activeVehicle.make_model ?? ""
        plateNumber = activeVehicle.plate_number ?? ""
        odometer = String(format: "%.0f", activeVehicle.odometer)
        taxDueDate = activeVehicle.tax_due_date ?? Date()
        stnkDueDate = activeVehicle.stnk_due_date ?? Date()
        serviceName = activeVehicle.service_name ?? ""
        lastServiceDate = activeVehicle.last_service_date ?? Date()
        lastOdometer = String(format: "%.0f", activeVehicle.last_odometer)
        hasTaxDate = activeVehicle.tax_due_date != nil
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
        activeVehicle.service_name = serviceName
        activeVehicle.last_service_date = lastServiceDate
        activeVehicle.last_odometer = Double(lastOdometer) ?? 0
        activeVehicle.user = activeUser

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
        context.refresh(activeVehicle, mergeChanges: true)
        fetchServiceHistory()

    }

    // MARK: - Create Service History Entry
    func addServiceHistoryEntry() {
        let history = ServiceHistory(context: context)

        history.history_id = UUID()
        history.service_name = self.serviceName
        history.service_date = self.lastServiceDate
        history.odometer = Double(self.lastOdometer) ?? 0
        history.created_at = Date()
        history.vehicle = activeVehicle

        // ⬇️ Tambahkan ke relationship "servicehistory" (to-many)
        let set = activeVehicle.mutableSetValue(forKey: "servicehistory")
        set.add(history)

        do {
            try context.save()
            print("✅ Service history entry added")
            context.refresh(activeVehicle, mergeChanges: true)
            fetchServiceHistory()   // refresh list
        } catch {
            print("❌ Failed to save service history entry: \(error)")
            self.errorMessage = "Failed to save service history"
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
        context.refresh(activeVehicle, mergeChanges: true)
        fetchServiceHistory()

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

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date)
    }
}
