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
    
    var isShowingError: Bool {
        errorMessage != nil
    }

    // MARK: - Init
    init(context: NSManagedObjectContext, vehicle: Vehicles, activeUser: User) {
        self.context = context
        self.context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        self.activeVehicle = vehicle
        self.activeUser = activeUser
        loadVehicleData()
        
        // Initialize temp tax date
        if let existingDate = vehicle.tax_due_date {
            self.tempTaxDate = existingDate
            self.hasTaxDate = true
        } else {
            self.tempTaxDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
            self.hasTaxDate = false
        }
    }

    // MARK: - Load Data from Core Data
    func loadVehicleData() {
        makeModel = activeVehicle.make_model ?? ""
        plateNumber = activeVehicle.plate_number ?? ""
        odometer = String(format: "%.0f", activeVehicle.odometer)
        taxDueDate = activeVehicle.tax_due_date ?? Date()
        stnkDueDate = activeVehicle.stnk_due_date ?? Date()
        serviceName = activeVehicle.service_name ?? ""
        lastServiceDate = activeVehicle.last_service_date ?? Date()
        lastOdometer = String(format: "%.0f", activeVehicle.last_odometer)
        
        // Update hasTaxDate status
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
            print("✅ SUCCESS: Data saved to Core Data.")
            context.refresh(activeVehicle, mergeChanges: false)
            loadVehicleData()
            successMessage = "Vehicle details updated successfully!"
            isEditing = false
        } catch {
            print("❌ FAILED TO SAVE: \(error.localizedDescription)")
            errorMessage = "Failed to save vehicle: \(error.localizedDescription)"
        }
    }

    // MARK: - Update Tax Due Date (NEW)
    func updateTaxDueDate() async {
        successMessage = nil
        errorMessage = nil
        
        // Update the vehicle's tax due date
        activeVehicle.tax_due_date = tempTaxDate
        taxDueDate = tempTaxDate
        hasTaxDate = true
        
        // Save to Core Data
        do {
            try context.save()
            print("✅ Tax due date updated successfully")
            context.refresh(activeVehicle, mergeChanges: false)
            
            // Request calendar access and add event
            await requestCalendarAccessAndAddEvent()
            
            successMessage = "✅ Tax due date updated successfully!"
            showingTaxDatePicker = false
            
        } catch {
            errorMessage = "❌ Failed to update tax due date: \(error.localizedDescription)"
            print("❌ Core Data save error: \(error)")
        }
    }
    
    // MARK: - Remove Tax Due Date (NEW)
    func removeTaxDueDate() {
        activeVehicle.tax_due_date = nil
        hasTaxDate = false
        
        do {
            try context.save()
            context.refresh(activeVehicle, mergeChanges: false)
            successMessage = "Tax due date removed"
            showingTaxDatePicker = false
            
            // Remove calendar event
            Task {
                await removeExistingTaxReminder()
            }
        } catch {
            errorMessage = "Failed to remove tax due date: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Calendar Integration (NEW)
    private func requestCalendarAccessAndAddEvent() async {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            
            if granted {
                await addTaxReminderToCalendar()
            } else {
                print("⚠️ Calendar access denied")
                // Still show success since Core Data save succeeded
            }
        } catch {
            print("❌ Calendar access error: \(error)")
        }
    }
    
    private func addTaxReminderToCalendar() async {
        guard let taxDate = activeVehicle.tax_due_date else { return }
        
        // Remove existing tax reminder for this vehicle
        await removeExistingTaxReminder()
        
        // Create new reminder event
        let event = EKEvent(eventStore: eventStore)
        event.title = "🚗 Vehicle Tax Due: \(activeVehicle.make_model ?? "Vehicle")"
        event.notes = """
        Vehicle: \(activeVehicle.make_model ?? "Unknown")
        Plate: \(activeVehicle.plate_number ?? "Unknown")
        Tax Due Date: \(formatDate(taxDate))
        
        Please renew your vehicle tax before expiration.
        """
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        // Set reminder 7 days before tax due date
        let reminderDate = Calendar.current.date(byAdding: .day, value: -7, to: taxDate) ?? taxDate
        event.startDate = reminderDate
        event.endDate = reminderDate.addingTimeInterval(3600) // 1 hour duration
        event.isAllDay = true
        
        // Add alarm 1 day before the event (8 days before tax due)
        let alarm = EKAlarm(relativeOffset: -86400) // 1 day before
        event.addAlarm(alarm)
        
        // Save event
        do {
            try eventStore.save(event, span: .thisEvent)
            print("✅ Tax reminder added to calendar")
        } catch {
            print("❌ Failed to save calendar event: \(error)")
        }
    }
    
    private func removeExistingTaxReminder() async {
        // Search for existing events with this vehicle's info
        let startDate = Date().addingTimeInterval(-365 * 24 * 3600) // 1 year ago
        let endDate = Date().addingTimeInterval(365 * 24 * 3600) // 1 year ahead
        
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let events = eventStore.events(matching: predicate)
        
        for event in events {
            if event.title.contains(activeVehicle.make_model ?? "") &&
               event.title.contains("Vehicle Tax Due") {
                do {
                    try eventStore.remove(event, span: .thisEvent)
                    print("✅ Removed old tax reminder")
                } catch {
                    print("❌ Failed to remove old event: \(error)")
                }
            }
        }
    }

    // MARK: - Delete Vehicle
    func deleteVehicle() {
        // Remove calendar reminder first
        Task {
            await removeExistingTaxReminder()
        }
        
        context.delete(activeVehicle)
        do {
            try context.save()
            successMessage = "Vehicle deleted successfully."
        } catch {
            errorMessage = "Failed to delete vehicle: \(error.localizedDescription)"
        }
    }
    
    // MARK: - New Vehicle Creation Helper
    func createNewVehicle(makeModel: String, plateNumber: String) {
        let newVehicle = Vehicles(context: context)
        newVehicle.make_model = makeModel
        newVehicle.plate_number = plateNumber
        newVehicle.user = activeUser
        
        do {
            try context.save()
            self.activeVehicle = newVehicle
        } catch {
            errorMessage = "Gagal membuat kendaraan baru: \(error.localizedDescription)"
        }
    }

    // MARK: - Tax Status Helper (NEW)
    func getTaxStatus() -> (status: String, color: Color) {
        guard let taxDate = activeVehicle.tax_due_date else {
            return ("Unknown", .gray)
        }
        
        let today = Date()
        let daysUntilDue = Calendar.current.dateComponents([.day], from: today, to: taxDate).day ?? 0
        
        if daysUntilDue < 0 {
            return ("Overdue", .red)
        } else if daysUntilDue <= 30 {
            return ("Due Soon", .orange)
        } else {
            return ("Up to Date", .green)
        }
    }

    // MARK: - Computed Helpers
    var formattedOdometer: String {
        if let value = Double(odometer) {
            return String(format: "%.0f km", value)
        }
        return "0 km"
    }

    var formattedTaxDueDate: String {
        format(date: taxDueDate)
    }

    var formattedSTNKDueDate: String {
        format(date: stnkDueDate)
    }

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
