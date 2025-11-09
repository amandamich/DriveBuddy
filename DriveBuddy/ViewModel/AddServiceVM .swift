//
//  AddServiceVM .swift
//  DriveBuddy
//
//  Created by Student on 05/11/25.
//

import Foundation
import CoreData
import Combine
import SwiftUI


@MainActor
class AddServiceViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var serviceName: String = ""
    @Published var selectedDate: Date = Date()
    @Published var odometer: String = ""
    @Published var reminder: String = "One month before"
    @Published var addToReminder: Bool = true
    @Published var successMessage: String?
    @Published var errorMessage: String?

    // Reminder options
    let reminderOptions = ["One week before", "Two weeks before", "One month before"]

    // MARK: - Core Data
    private let viewContext: NSManagedObjectContext
    private let vehicle: Vehicles

    // MARK: - Init
    init(context: NSManagedObjectContext, vehicle: Vehicles) {
        self.viewContext = context
        self.vehicle = vehicle
    }

    // MARK: - Add Service
    func addService() {
        // Reset messages
        successMessage = nil
        errorMessage = nil

        // Validate inputs
        guard !serviceName.isEmpty else {
            errorMessage = "Please enter the service name."
            return
        }

        guard !odometer.isEmpty, let odometerValue = Double(odometer) else {
            errorMessage = "Please enter a valid odometer value."
            return
        }

        // ✅ Create a new service record
        let newService = ServiceHistory(context: viewContext)
        newService.history_id = UUID()
        newService.service_name = serviceName
        newService.service_date = selectedDate
        newService.odometer = odometerValue
        newService.created_at = Date()
        newService.vehicle = vehicle

        do {
            try viewContext.save()
            successMessage = "Service added successfully!"
            clearFields()
        } catch {
            errorMessage = "Failed to save service: \(error.localizedDescription)"
        }
    }

    // MARK: - Clear Fields
    private func clearFields() {
        serviceName = ""
        selectedDate = Date()
        odometer = ""
        reminder = "One month before"
        addToReminder = true
    }
}
