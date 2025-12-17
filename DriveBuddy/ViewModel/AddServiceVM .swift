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
    
    // Auto-create settings
    @Published var autoCreateNext: Bool = true
    @Published var nextServiceMonths: Int = 6

    @Published var successMessage: String?
    @Published var errorMessage: String?

    // Dibutuhkan oleh View untuk Menu/Picker
    let reminderOptions = ["One week before", "Two weeks before", "One month before"]

    private let viewContext: NSManagedObjectContext
    private let vehicle: Vehicles
    private let profileVM: ProfileViewModel

    init(context: NSManagedObjectContext, vehicle: Vehicles, profileVM: ProfileViewModel) {
        self.viewContext = context
        self.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        self.vehicle = vehicle
        self.profileVM = profileVM
    }

    func addService() {
        successMessage = nil
        errorMessage = nil

        let trimmedName = serviceName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 1. Validasi Input
        guard !trimmedName.isEmpty else {
            errorMessage = "Please enter the service name."
            return
        }

        guard let odometerValue = Double(odometer) else {
            errorMessage = "Please enter a valid odometer value."
            return
        }
        
        // 2. Cek Duplikasi (Jangan izinkan nama yang sama di daftar Upcoming)
        if isDuplicateUpcoming(name: trimmedName) {
            errorMessage = "Service '\(trimmedName)' is already scheduled in your upcoming list."
            return
        }

        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let selectedStart = calendar.startOfDay(for: selectedDate)
        
        // Kondisi: Apakah servis ini terjadi sekarang/masa lalu atau rencana masa depan?
        let isInPastOrToday = selectedStart <= todayStart
        
        // 3. Buat Objek Servis
        let history = ServiceHistory(context: viewContext)
        history.history_id = UUID()
        history.service_name = trimmedName
        history.service_date = selectedDate
        history.odometer = odometerValue
        history.created_at = Date()
        history.vehicle = vehicle

        // Set reminder days
        if history.responds(to: Selector(("setReminder_days_before:"))) {
            history.setValue(Int16(daysBeforeReminder), forKey: "reminder_days_before")
        }

        // 4. Update Status Kendaraan
        if isInPastOrToday {
            vehicle.last_service_date = selectedDate
            vehicle.service_name = trimmedName
            if odometerValue > vehicle.odometer {
                vehicle.odometer = odometerValue
            }
            vehicle.last_odometer = odometerValue
        }

        // 5. Simpan dan Logika Auto-Create
        do {
            try viewContext.save()
            
            // --- LOGIKA UTAMA PERBAIKAN ---
            // Jika user menginput tanggal MASA DEPAN (misal Dec 2025):
            // Kita TIDAK membuat servis berikutnya (Jun 2026).
            // Servis Jun 2026 baru dibuat saat Dec 2025 nanti diselesaikan.
            
            if isInPastOrToday && autoCreateNext {
                createNextService(serviceName: trimmedName, fromDate: selectedDate)
            }

            if addToReminder {
                Task { await scheduleReminderSafely(for: history, daysBefore: daysBeforeReminder) }
            }

            successMessage = "Service added successfully!"
            clearFields()
            NotificationCenter.default.post(name: .init("DriveBuddyServiceAdded"), object: vehicle)

        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }

    // MARK: - Core Logic

    private func isDuplicateUpcoming(name: String) -> Bool {
        let request: NSFetchRequest<ServiceHistory> = ServiceHistory.fetchRequest()
        // Cek nama yang sama (case insensitive) yang belum selesai (odometer 0)
        request.predicate = NSPredicate(
            format: "vehicle == %@ AND service_name ==[c] %@ AND odometer == 0",
            vehicle, name
        )
        
        do {
            let count = try viewContext.count(for: request)
            return count > 0
        } catch {
            return false
        }
    }

    private func createNextService(serviceName: String, fromDate: Date) {
        if isDuplicateUpcoming(name: serviceName) { return }
        
        guard let nextDate = Calendar.current.date(byAdding: .month, value: nextServiceMonths, to: fromDate) else { return }
        
        let upcomingService = ServiceHistory(context: viewContext)
        upcomingService.history_id = UUID()
        upcomingService.service_name = serviceName
        upcomingService.service_date = nextDate
        upcomingService.odometer = 0
        upcomingService.created_at = Date()
        upcomingService.vehicle = vehicle
        
        try? viewContext.save()
    }

    // MARK: - Helpers

    private func scheduleReminderSafely(for history: ServiceHistory, daysBefore: Int) async {
        await profileVM.scheduleServiceReminder(
            serviceId: history.history_id ?? UUID(),
            serviceName: history.service_name ?? "Service",
            vehicleName: vehicle.make_model ?? "Vehicle",
            serviceDate: history.service_date ?? Date(),
            daysBeforeReminder: daysBefore
        )
    }

    var daysBeforeReminder: Int {
        switch reminder {
        case "One week before": return 7
        case "Two weeks before": return 14
        case "One month before": return 30
        default: return 7
        }
    }

    private func clearFields() {
        serviceName = ""
        selectedDate = Date()
        odometer = ""
    }
}
