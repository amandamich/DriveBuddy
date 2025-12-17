//
//  TaxHistoryVM.swift
//  DriveBuddy
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
        
        if let context = context {
            if let latestTax = getLatestPaidTax(for: history.vehiclePlate) {
                syncTaxDateToVehicle(licensePlate: history.vehiclePlate, validUntil: latestTax.validUntil, context: context)
            } else {
                clearVehicleTaxDate(licensePlate: history.vehiclePlate, context: context)
            }
        }
    }
    
    private func clearVehicleTaxDate(licensePlate: String, context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<Vehicles> = Vehicles.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "plate_number == %@", licensePlate)
        
        do {
            let vehicles = try context.fetch(fetchRequest)
            if let vehicle = vehicles.first {
                vehicle.tax_due_date = nil
                try context.save()
                print("✅ Tax date cleared from Core Data vehicle: \(licensePlate)")
                NotificationCenter.default.post(name: .NSManagedObjectContextDidSave, object: context)
            }
        } catch {
            print("❌ Failed to clear tax date: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Filtering
    func getExpiringSoonTaxes() -> [TaxModel] {
        return taxHistories.filter { $0.status == .expiringSoon }
    }
    
    func getExpiredTaxes() -> [TaxModel] {
        return taxHistories.filter { $0.status == .expired }
    }
    
    func getPaidTaxes() -> [TaxModel] {
        return taxHistories.filter { $0.status == .paid }
    }
    
    func getExpiredPaidTaxes() -> [TaxModel] {
        return taxHistories.filter { $0.status == .expiredPaid }
    }
    
    // MARK: - Get Latest Paid Tax for Vehicle
    func getLatestPaidTax(for licensePlate: String) -> TaxModel? {
        let vehicleTaxes = taxHistories.filter { $0.vehiclePlate == licensePlate }
        
        return vehicleTaxes
            .filter { $0.status == .paid || $0.status == .expiringSoon }
            .sorted { $0.validUntil > $1.validUntil }
            .first
    }
    
    // MARK: - SYNC TAX DATE TO CORE DATA VEHICLE
    func syncTaxDateToVehicle(licensePlate: String, validUntil: Date, context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<Vehicles> = Vehicles.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "plate_number == %@", licensePlate)
        
        do {
            let vehicles = try context.fetch(fetchRequest)
            if let vehicle = vehicles.first {
                // ✅ Only save if the date actually changed
                if vehicle.tax_due_date != validUntil {
                    vehicle.tax_due_date = validUntil
                    try context.save()
                    print("✅ Tax date synced to Core Data vehicle: \(licensePlate) -> \(validUntil)")
                } else {
                    print("ℹ️ Tax date already up to date for: \(licensePlate)")
                }
            } else {
                print("⚠️ Vehicle not found for plate: \(licensePlate)")
            }
        } catch {
            print("❌ Failed to sync tax date: \(error.localizedDescription)")
        }
    }
    
    func syncLatestTaxToVehicle(licensePlate: String, context: NSManagedObjectContext) {
        if let latestTax = getLatestPaidTax(for: licensePlate) {
            syncTaxDateToVehicle(licensePlate: licensePlate, validUntil: latestTax.validUntil, context: context)
        }
    }
    
    // MARK: - Notifications
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Notification permission granted")
            }
        }
    }
    
    func scheduleNotification(for history: TaxModel) {
        let center = UNUserNotificationCenter.current()
        
        let oldIdentifiers = [
            "\(history.id.uuidString)-30days",
            "\(history.id.uuidString)-7days",
            "\(history.id.uuidString)-1days"
        ]
        center.removePendingNotificationRequests(withIdentifiers: oldIdentifiers)
        
        let notificationDays = [30, 7, 1]
        
        for days in notificationDays {
            guard let notificationDate = Calendar.current.date(byAdding: .day, value: -days, to: history.validUntil) else { continue }
            guard notificationDate > Date() else { continue }
            
            let content = UNMutableNotificationContent()
            content.title = "Tax Reminder 🚗"
            content.body = "\(history.vehiclePlate) - \(history.vehicleName) tax expires in \(days) day(s)!"
            content.sound = .default
            content.badge = 1
            
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            let identifier = "\(history.id.uuidString)-\(days)days"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            center.add(request)
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
    }
}
