//
//  TaxHistoryVM.swift
//  DriveBuddy
//
//  Created by Timothy on 26/11/25.
//

import Foundation
import Combine
import UserNotifications

class TaxHistoryManager: ObservableObject {
	static let shared = TaxHistoryManager()
	
	@Published var taxHistories: [TaxModel] = []
	
	private let taxHistoriesKey = "taxHistories"
	
	init() {
		loadTaxHistories()
		requestNotificationPermission()
	}
	
	// MARK: - Load & Save
	func loadTaxHistories() {
		if let data = UserDefaults.standard.data(forKey: taxHistoriesKey),
		   let decoded = try? JSONDecoder().decode([TaxModel].self, from: data) {
			taxHistories = decoded.sorted { $0.validUntil > $1.validUntil }
		}
	}
	
	private func saveTaxHistories() {
		if let encoded = try? JSONEncoder().encode(taxHistories) {
			UserDefaults.standard.set(encoded, forKey: taxHistoriesKey)
		}
	}
	
	// MARK: - CRUD Operations
	func addTaxHistory(_ history: TaxModel) {
		taxHistories.append(history)
		taxHistories.sort { $0.validUntil > $1.validUntil }
		saveTaxHistories()
		scheduleNotification(for: history)
	}
	
	func updateTaxHistory(_ history: TaxModel) {
		if let index = taxHistories.firstIndex(where: { $0.id == history.id }) {
			taxHistories[index] = history
			taxHistories.sort { $0.validUntil > $1.validUntil }
			saveTaxHistories()
			scheduleNotification(for: history)
		}
	}
	
	func deleteTaxHistory(_ history: TaxModel) {
		taxHistories.removeAll { $0.id == history.id }
		saveTaxHistories()
		cancelNotification(for: history)
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
	
	// MARK: - Notifications
	func requestNotificationPermission() {
		UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
			if granted {
				print("✅ Notification permission granted")
			} else {
				print("❌ Notification permission denied")
			}
		}
	}
	
	func scheduleNotification(for history: TaxModel) {
		let center = UNUserNotificationCenter.current()
		
		// Cancel existing notification for this tax
		center.removePendingNotificationRequests(withIdentifiers: [history.id.uuidString])
		
		// Calculate notification dates (30 days, 7 days, 1 day before expiry)
		let notificationDays = [30, 7, 1]
		
		for days in notificationDays {
			guard let notificationDate = Calendar.current.date(byAdding: .day, value: -days, to: history.validUntil) else { continue }
			
			// Only schedule if notification date is in the future
			guard notificationDate > Date() else { continue }
			
			let content = UNMutableNotificationContent()
			content.title = "Tax Reminder 🚗"
			content.body = "\(history.vehiclePlate) - Tax expires in \(days) day(s)!"
			content.sound = .default
			content.badge = 1
			
			let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
			let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
			
			let identifier = "\(history.id.uuidString)-\(days)days"
			let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
			
			center.add(request) { error in
				if let error = error {
					print("❌ Error scheduling notification: \(error)")
				} else {
					print("✅ Notification scheduled for \(days) days before expiry")
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
	}
}
