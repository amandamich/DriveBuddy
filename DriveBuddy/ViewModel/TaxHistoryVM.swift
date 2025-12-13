//
//  TaxHistoryVM.swift
//  DriveBuddy
//
//  Created by Timothy on 26/11/25.
//

import Foundation
import Combine
import UserNotifications
import CoreData

class TaxHistoryVM: ObservableObject {
    static let shared = TaxHistoryVM()
    
    @Published var taxHistories: [TaxModel] = []
    
    private let taxHistoriesKey = "taxHistories"
    
    private init() {
        loadTaxHistories()
        requestNotificationPermission()
    }
    
    // MARK: - Load & Save
    func loadTaxHistories() {
        if let data = UserDefaults.standard.data(forKey: taxHistoriesKey),
           let decoded = try? JSONDecoder().decode([TaxModel].self, from: data) {
            taxHistories = decoded.sorted { $0.validUntil > $1.validUntil }
            print("✅ Loaded \(taxHistories.count) tax records from database")
        } else {
            print("ℹ️ No tax records found in database")
        }
    }
    
    private func saveTaxHistories() {
        if let encoded = try? JSONEncoder().encode(taxHistories) {
            UserDefaults.standard.set(encoded, forKey: taxHistoriesKey)
            print("✅ Saved \(taxHistories.count) tax records to database")
        } else {
            print("❌ Failed to save tax records")
        }
    }
    
    // MARK: - CRUD Operations
    func addTaxHistory(_ history: TaxModel, context: NSManagedObjectContext? = nil) {
        taxHistories.append(history)
        taxHistories.sort { $0.validUntil > $1.validUntil }
        saveTaxHistories()
        scheduleNotification(for: history)
        print("✅ Added new tax record: \(history.vehiclePlate)")
        
        // ✅ SYNC WITH CORE DATA VEHICLE
        if let context = context {
            syncTaxDateToVehicle(licensePlate: history.vehiclePlate, validUntil: history.validUntil, context: context)
        }
    }
    
    func updateTaxHistory(_ history: TaxModel, context: NSManagedObjectContext? = nil) {
        if let index = taxHistories.firstIndex(where: { $0.id == history.id }) {
            taxHistories[index] = history
            taxHistories.sort { $0.validUntil > $1.validUntil }
            saveTaxHistories()
            scheduleNotification(for: history)
            print("✅ Updated tax record: \(history.vehiclePlate)")
            
            // ✅ SYNC WITH CORE DATA VEHICLE
            if let context = context {
                syncTaxDateToVehicle(licensePlate: history.vehiclePlate, validUntil: history.validUntil, context: context)
            }
        }
    }
    
    func deleteTaxHistory(_ history: TaxModel, context: NSManagedObjectContext? = nil) {
        taxHistories.removeAll { $0.id == history.id }
        saveTaxHistories()
        cancelNotification(for: history)
        print("✅ Deleted tax record: \(history.vehiclePlate)")
        
        // ✅ UPDATE CORE DATA VEHICLE - Check if there's another valid tax, otherwise clear the date
        if let context = context {
            if let latestTax = getLatestValidTax(for: history.vehiclePlate) {
                // Sync to the next valid tax
                syncTaxDateToVehicle(licensePlate: history.vehiclePlate, validUntil: latestTax.validUntil, context: context)
            } else {
                // No more valid taxes, clear the tax_due_date
                clearVehicleTaxDate(licensePlate: history.vehiclePlate, context: context)
            }
        }
    }
    
    // MARK: - ✅ CLEAR TAX DATE FROM CORE DATA VEHICLE
    private func clearVehicleTaxDate(licensePlate: String, context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<Vehicles> = Vehicles.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "plate_number == %@", licensePlate)
        
        do {
            let vehicles = try context.fetch(fetchRequest)
            if let vehicle = vehicles.first {
                vehicle.tax_due_date = nil
                
                try context.save()
                print("✅ Tax date cleared from Core Data vehicle: \(licensePlate)")
                
                // Post notification to refresh UI
                NotificationCenter.default.post(name: .NSManagedObjectContextDidSave, object: context)
            }
        } catch {
            print("❌ Failed to clear tax date: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Filtering
    func getExpiringTaxes() -> [TaxModel] {
        return taxHistories.filter { $0.status == .expiringSoon }
    }
    
    func getExpiredTaxes() -> [TaxModel] {
        return taxHistories.filter { $0.status == .expired }
    }
    
    func getValidTaxes() -> [TaxModel] {
        return taxHistories.filter { $0.status == .valid }
    }
    
    // MARK: - Get Latest Valid Tax for Vehicle
    func getLatestValidTax(for licensePlate: String) -> TaxModel? {
        let vehicleTaxes = taxHistories.filter { $0.vehiclePlate == licensePlate }
        
        // Get the tax with the latest validUntil date that is still valid or expiring soon
        return vehicleTaxes
            .filter { $0.status == .valid || $0.status == .expiringSoon }
            .sorted { $0.validUntil > $1.validUntil }
            .first
    }
    
    // MARK: - ✅ SYNC TAX DATE TO CORE DATA VEHICLE
    private func syncTaxDateToVehicle(licensePlate: String, validUntil: Date, context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<Vehicles> = Vehicles.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "plate_number == %@", licensePlate)
        
        do {
            let vehicles = try context.fetch(fetchRequest)
            if let vehicle = vehicles.first {
                vehicle.tax_due_date = validUntil
                
                try context.save()
                print("✅ Tax date synced to Core Data vehicle: \(licensePlate)")
                
                // Post notification to refresh UI
                NotificationCenter.default.post(name: .NSManagedObjectContextDidSave, object: context)
            } else {
                print("⚠️ Vehicle not found for license plate: \(licensePlate)")
            }
        } catch {
            print("❌ Failed to sync tax date: \(error.localizedDescription)")
        }
    }
    
    // MARK: - ✅ PUBLIC METHOD TO SYNC FROM OUTSIDE
    func syncLatestTaxToVehicle(licensePlate: String, context: NSManagedObjectContext) {
        if let latestTax = getLatestValidTax(for: licensePlate) {
            syncTaxDateToVehicle(licensePlate: licensePlate, validUntil: latestTax.validUntil, context: context)
        } else {
            print("ℹ️ No valid tax found for vehicle: \(licensePlate)")
        }
    }
    
    // MARK: - Notifications
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Notification permission granted")
            } else if let error = error {
                print("❌ Notification permission error: \(error.localizedDescription)")
            } else {
                print("❌ Notification permission denied")
            }
        }
    }
    
    func scheduleNotification(for history: TaxModel) {
        let center = UNUserNotificationCenter.current()
        
        // Cancel existing notifications for this tax
        let oldIdentifiers = [
            "\(history.id.uuidString)-30days",
            "\(history.id.uuidString)-7days",
            "\(history.id.uuidString)-1days"
        ]
        center.removePendingNotificationRequests(withIdentifiers: oldIdentifiers)
        
        // Calculate notification dates (30 days, 7 days, 1 day before expiry)
        let notificationDays = [30, 7, 1]
        
        for days in notificationDays {
            guard let notificationDate = Calendar.current.date(byAdding: .day, value: -days, to: history.validUntil) else { continue }
            
            // Only schedule if notification date is in the future
            guard notificationDate > Date() else {
                print("⏭️ Skipping notification for \(days) days (date has passed)")
                continue
            }
            
            let content = UNMutableNotificationContent()
            content.title = "Tax Reminder 🚗"
            content.body = "\(history.vehiclePlate) - \(history.vehicleName) tax expires in \(days) day(s)!"
            content.sound = .default
            content.badge = 1
            
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            let identifier = "\(history.id.uuidString)-\(days)days"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            center.add(request) { error in
                if let error = error {
                    print("❌ Error scheduling notification: \(error.localizedDescription)")
                } else {
                    print("✅ Notification scheduled for \(history.vehiclePlate) - \(days) days before expiry")
                }
            }
        }
    }
    
    func cancelNotification(for history: TaxModel) {
        let center = UNUserNotificationCenter.current()
        let identifiers = [
            "\(history.id.uuidString)-30days",
            "\(history.id.uuidString)-7days",
            "\(history.id.uuidString)-1days"
        ]
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        print("✅ Cancelled notifications for: \(history.vehiclePlate)")
    }
}
