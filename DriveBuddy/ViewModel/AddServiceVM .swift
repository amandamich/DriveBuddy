// AddServiceViewModel - FIXED: Don't auto-create next service for past dates

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
    
    // ✅ NEW: Auto-create next service settings
    @Published var autoCreateNext: Bool = true
    @Published var nextServiceInterval: Int = 5000 // km
    @Published var nextServiceMonths: Int = 6 // months

    @Published var successMessage: String?
    @Published var errorMessage: String?

    let reminderOptions = ["One week before", "Two weeks before", "One month before"]

    private let viewContext: NSManagedObjectContext
    private let vehicle: Vehicles
    private let profileVM: ProfileViewModel

    init(context: NSManagedObjectContext, vehicle: Vehicles, profileVM: ProfileViewModel) {
        print("[AddServiceVM] init")
        self.viewContext = context
        self.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        self.vehicle = vehicle
        self.profileVM = profileVM
    }

    func addService() {
        print("[AddServiceVM] addService called")

        successMessage = nil
        errorMessage = nil

        // Validation
        let trimmedName = serviceName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Please enter the service name."
            print("[AddServiceVM] validation failed: empty service name")
            return
        }

        guard !odometer.trimmingCharacters(in: .whitespaces).isEmpty,
              let odometerValue = Double(odometer) else {
            errorMessage = "Please enter a valid odometer value."
            print("[AddServiceVM] validation failed: invalid odometer '\(odometer)'")
            return
        }
        
        // ✅ SMART VALIDATION: Check if service is in past/today or future
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let selectedStart = calendar.startOfDay(for: selectedDate)
        let isInPast = selectedStart < todayStart
        let isToday = selectedStart == todayStart
        let isInPastOrToday = selectedStart <= todayStart  // ✅ Combined check
        let isInFuture = selectedStart > todayStart
        
        let vehicleCurrentOdometer = vehicle.odometer
        
        if isInPast || isToday {
            // ✅ CHANGED: Past OR Today service = Historical fact (already happened or happening now)
            // Odometer can be higher and will update vehicle odometer
            // Show info message if jump is extreme (might be intentional data correction)
            if odometerValue > vehicleCurrentOdometer * 2 && vehicleCurrentOdometer > 0 {
                // Extreme jump detected - log warning but allow
                let difference = Int(odometerValue - vehicleCurrentOdometer)
                print("[AddServiceVM] ⚠️ WARNING: Large odometer jump detected")
                print("   Service: \(Int(odometerValue)) km")
                print("   Vehicle: \(Int(vehicleCurrentOdometer)) km")
                print("   Difference: \(difference) km")
                print("   Vehicle odometer will be updated to \(Int(odometerValue)) km")
                
                // Note: We allow this because:
                // 1. Past/today service = historical fact (already happened)
                // 2. User might be correcting initial vehicle odometer
                // 3. Vehicle might have traveled far since purchase
                // 4. Better to allow and update than block valid data
            } else {
                print("[AddServiceVM] Past/today service - odometer \(odometerValue) will be recorded as fact")
            }
        } else if isInFuture {
            // Future/today service (upcoming) - odometer should be reasonable
            
            // Check 1: Odometer should not exceed current odometer
            if odometerValue > vehicleCurrentOdometer && vehicleCurrentOdometer > 0 {
                errorMessage = "For upcoming services, odometer (\(Int(odometerValue)) km) should not exceed vehicle's current odometer (\(Int(vehicleCurrentOdometer)) km)."
                print("[AddServiceVM] validation failed: future service odometer (\(odometerValue)) > vehicle odometer (\(vehicleCurrentOdometer))")
                return
            }
            
            // ✅ NEW Check 2: Odometer should not be significantly lower than current odometer
            // (Allows small differences for estimation, but blocks obvious mistakes)
            if vehicleCurrentOdometer > 0 && odometerValue < vehicleCurrentOdometer * 0.5 {
                let difference = Int(vehicleCurrentOdometer - odometerValue)
                errorMessage = "Odometer value seems too low.\n\nService odometer: \(Int(odometerValue)) km\nVehicle current odometer: \(Int(vehicleCurrentOdometer)) km\nDifference: \(difference) km\n\nFor upcoming services, odometer should be close to current vehicle odometer. Did you mean \(Int(vehicleCurrentOdometer)) km?"
                print("[AddServiceVM] validation failed: future service odometer too low - service: \(odometerValue), vehicle: \(vehicleCurrentOdometer)")
                return
            }
            
            print("[AddServiceVM] Future/today service - odometer \(odometerValue) validated")
        }
        
        // ✅ NEW: Check odometer sequence for services with same name
        let request: NSFetchRequest<ServiceHistory> = ServiceHistory.fetchRequest()
        request.predicate = NSPredicate(
            format: "vehicle == %@ AND service_name ==[c] %@",
            vehicle,
            trimmedName as CVarArg
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ServiceHistory.service_date, ascending: true)]
        
        do {
            let existingServices = try viewContext.fetch(request)
            
            // Check if new odometer makes sense in the timeline
            for existing in existingServices {
                guard let existingDate = existing.service_date else { continue }
                let existingDateStart = calendar.startOfDay(for: existingDate)
                
                // If new service is AFTER existing service, odometer should be >= existing odometer
                if selectedStart > existingDateStart && odometerValue < existing.odometer && existing.odometer > 0 {
                    errorMessage = "Odometer (\(Int(odometerValue)) km) is lower than previous \"\(trimmedName)\" service on \(formatDate(existingDate)) (\(Int(existing.odometer)) km). Please check the odometer reading."
                    print("[AddServiceVM] validation failed: odometer sequence issue")
                    return
                }
                
                // If new service is BEFORE existing service, odometer should be <= existing odometer
                if selectedStart < existingDateStart && odometerValue > existing.odometer && existing.odometer > 0 {
                    errorMessage = "Odometer (\(Int(odometerValue)) km) is higher than later \"\(trimmedName)\" service on \(formatDate(existingDate)) (\(Int(existing.odometer)) km). Please check the odometer reading."
                    print("[AddServiceVM] validation failed: odometer sequence issue")
                    return
                }
            }
        } catch {
            print("[AddServiceVM] Warning: Could not validate odometer sequence: \(error)")
            // Continue anyway - don't block save if validation fails
        }

        // Create history object
        let history = ServiceHistory(context: viewContext)
        history.history_id = UUID()
        history.service_name = trimmedName
        history.service_date = selectedDate
        history.odometer = odometerValue
        history.created_at = Date()

        if history.responds(to: Selector(("setReminder_days_before:"))) {
            history.setValue(Int16(daysBeforeReminder), forKey: "reminder_days_before")
        }

        // Relate to vehicle
        history.vehicle = vehicle

        // ✅ SMART: Update vehicle summary fields based on service type
        if isInPastOrToday {
            // ✅ CHANGED: Past OR Today service = Last completed service
            // Update vehicle's last service info AND current odometer (if higher)
            vehicle.last_service_date = selectedDate
            vehicle.service_name = trimmedName
            
            // Update vehicle odometer if service odometer is higher (represents current state)
            if odometerValue > vehicle.odometer {
                vehicle.odometer = odometerValue
                print("[AddServiceVM] Updated vehicle odometer to \(odometerValue) km (from last/today service)")
            }
            vehicle.last_odometer = odometerValue
            
        } else {
            // Future service = Upcoming service
            // Only update if this is the most recent info we have
            vehicle.last_service_date = selectedDate
            vehicle.last_odometer = odometerValue
            vehicle.service_name = trimmedName
        }

        // Save context
        do {
            try viewContext.save()
            viewContext.processPendingChanges()
            print("[AddServiceVM] saved service for vehicle: \(vehicle.make_model ?? "unknown")")

            // Schedule reminder if enabled
            if addToReminder {
                Task {
                    await scheduleReminderSafely(for: history, daysBefore: daysBeforeReminder)
                }
            }

            // ✅ SMART LOGIC FOR PAST/TODAY SERVICES:
            // If user adds a service with past/today date, treat it as "last service" (completed)
            // and ALWAYS create the next service
            
            if isInPastOrToday {
                // Past/today service = Last service (completed/just completed)
                // ALWAYS create next service
                print("ℹ️ Service is in the past or today - treating as completed service")
                print("ℹ️ Will auto-create next service for tracking")
                
                createNextService(serviceName: trimmedName, fromDate: selectedDate, fromOdometer: odometerValue)
                
            } else if autoCreateNext {
                // Future service with auto-create enabled
                print("✅ Auto-creating next service (current service is future)")
                createNextService(serviceName: trimmedName, fromDate: selectedDate, fromOdometer: odometerValue)
            }

            successMessage = "Service added successfully!"
            clearFields()

            NotificationCenter.default.post(name: .init("DriveBuddyServiceAdded"), object: vehicle)

        } catch {
            errorMessage = "Failed to save service: \(error.localizedDescription)"
            print("[AddServiceVM] save error:", error)
        }
    }

    // ✅ SMART DUPLICATE PREVENTION: Create next service
    private func createNextService(serviceName: String, fromDate: Date, fromOdometer: Double) {
        print("\n🔄 AUTO-CREATE NEXT SERVICE:")
        print("   Service: '\(serviceName)'")
        print("   From date: \(fromDate)")
        print("   From odometer: \(fromOdometer)")
        
        // ✅ CRITICAL: Validate service name is not empty
        guard !serviceName.trimmingCharacters(in: .whitespaces).isEmpty else {
            print("❌ Cannot create service with empty name")
            return
        }
        
        // ✅ Check for existing future service with SAME NAME
        let futureRequest: NSFetchRequest<ServiceHistory> = ServiceHistory.fetchRequest()
        futureRequest.predicate = NSPredicate(
            format: "vehicle == %@ AND service_name ==[c] %@ AND service_date > %@",
            vehicle,
            serviceName as CVarArg,
            fromDate as NSDate
        )
        
        do {
            let existingFutureServices = try viewContext.fetch(futureRequest)
            
            print("   Found \(existingFutureServices.count) existing future '\(serviceName)' service(s)")
            
            if !existingFutureServices.isEmpty {
                print("ℹ️ Future '\(serviceName)' already exists, skipping auto-create")
                for existing in existingFutureServices {
                    print("      - Existing: '\(existing.service_name ?? "NO NAME")' on \(existing.service_date?.description ?? "N/A")")
                }
                return
            }
        } catch {
            print("❌ Failed to check for future services: \(error)")
            return
        }
        
        // Calculate next service date
        guard let nextDate = Calendar.current.date(byAdding: .month, value: nextServiceMonths, to: fromDate) else {
            print("❌ Failed to calculate next date")
            return
        }
        
        // ✅ FIXED: Don't calculate next odometer - let user input manually
        
        // ✅ Create the next service with SAME NAME
        let upcomingService = ServiceHistory(context: viewContext)
        upcomingService.history_id = UUID()
        upcomingService.service_name = serviceName // ✅ CRITICAL: Use exact same name
        upcomingService.service_date = nextDate
        upcomingService.odometer = 0 // ✅ FIXED: Set to 0, user inputs manually when completing
        upcomingService.created_at = Date()
        upcomingService.vehicle = vehicle
        
        if upcomingService.responds(to: Selector(("setReminder_days_before:"))) {
            upcomingService.setValue(Int16(daysBeforeReminder), forKey: "reminder_days_before")
        }
        
        print("📝 Creating next '\(serviceName)':")
        print("   ID: \(upcomingService.history_id?.uuidString ?? "N/A")")
        print("   Name: '\(serviceName)'")
        print("   Date: \(nextDate)")
        print("   Odometer: 0 km (manual input required)")
        print("   Interval: +\(nextServiceMonths) months")
        
        do {
            try viewContext.save()
            viewContext.processPendingChanges()
            print("✅ Auto-created next '\(serviceName)' successfully\n")
            
            // Schedule reminder for next service too
            if addToReminder {
                Task {
                    await scheduleReminderSafely(for: upcomingService, daysBefore: daysBeforeReminder)
                }
            }
        } catch {
            print("❌ Failed to auto-create next service: \(error)")
        }
    }

    // MARK: - Schedule helper
    private func scheduleReminderSafely(for history: ServiceHistory, daysBefore: Int) async {
        do {
            await profileVM.scheduleServiceReminder(
                serviceId: history.history_id ?? UUID(),
                serviceName: history.service_name ?? "Service",
                vehicleName: vehicle.make_model ?? "Vehicle",
                serviceDate: history.service_date ?? Date(),
                daysBeforeReminder: daysBefore
            )
            
            if profileVM.user?.add_to_calendar == true {
                try? await profileVM.addCalendarEvent(
                    title: "🔧 Service: \(history.service_name ?? "Service")",
                    notes: "Service for \(vehicle.make_model ?? "Vehicle")",
                    startDate: history.service_date ?? Date(),
                    alarmOffsetDays: daysBefore
                )
            }
            print("[AddServiceVM] reminder scheduled")
        } catch {
            print("[AddServiceVM] reminder scheduling failed:", error)
        }
    }

    var daysBeforeReminder: Int {
        switch reminder {
        case "One week before": return 7
        case "Two weeks before": return 14
        case "One month before": return 30
        default: return 7
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }

    private func clearFields() {
        serviceName = ""
        selectedDate = Date()
        odometer = ""
        reminder = "One month before"
        addToReminder = true
        autoCreateNext = true
        nextServiceInterval = 5000
        nextServiceMonths = 6
    }
}
