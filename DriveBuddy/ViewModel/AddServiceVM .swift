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
    @Published var nextServiceInterval: Int = 5000 // km
    @Published var nextServiceMonths: Int = 6 // months

    @Published var successMessage: String?
    @Published var errorMessage: String?

    let reminderOptions = ["One week before", "Two weeks before", "One month before"]

    private let viewContext: NSManagedObjectContext
    private let vehicle: Vehicles
    private let profileVM: ProfileViewModel

    init(context: NSManagedObjectContext, vehicle: Vehicles, profileVM: ProfileViewModel) {
        self.viewContext = context
        // Kebijakan merge untuk menghindari konflik Core Data
        self.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        self.vehicle = vehicle
        self.profileVM = profileVM
    }

    func addService() {
        successMessage = nil
        errorMessage = nil

        // 1. Validasi Input Dasar
        let trimmedName = serviceName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Please enter the service name."
            return
        }

        guard !odometer.trimmingCharacters(in: .whitespaces).isEmpty,
              let odometerValue = Double(odometer) else {
            errorMessage = "Please enter a valid odometer value."
            return
        }
        
        // 2. LOGIKA CEK DUPLIKASI (PENTING)
        // Mengecek apakah ada servis dengan nama yang sama yang belum dikerjakan (odometer 0)
        if isDuplicateUpcoming(name: trimmedName) {
            errorMessage = "A service named '\(trimmedName)' is already in your Upcoming list. Please complete or delete that one first."
            return
        }

        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let selectedStart = calendar.startOfDay(for: selectedDate)
        let isInPastOrToday = selectedStart <= todayStart
        let isInFuture = selectedStart > todayStart
        
        let vehicleCurrentOdometer = vehicle.odometer
        
        // 3. Validasi Odometer Terhadap Waktu
        if isInFuture {
            // Untuk servis masa depan, odometer biasanya adalah target (tidak boleh lebih kecil dari sekarang secara ekstrem)
            if odometerValue > vehicleCurrentOdometer && vehicleCurrentOdometer > 0 {
                errorMessage = "For future services, target odometer should not exceed current odometer."
                return
            }
        }
        
        // 4. Proses Simpan Data
        let history = ServiceHistory(context: viewContext)
        history.history_id = UUID()
        history.service_name = trimmedName
        history.service_date = selectedDate
        history.odometer = odometerValue
        history.created_at = Date()

        if history.responds(to: Selector(("setReminder_days_before:"))) {
            history.setValue(Int16(daysBeforeReminder), forKey: "reminder_days_before")
        }

        history.vehicle = vehicle

        // Update ringkasan kendaraan jika servis ini dianggap "terbaru/hari ini"
        if isInPastOrToday {
            vehicle.last_service_date = selectedDate
            vehicle.service_name = trimmedName
            if odometerValue > vehicle.odometer {
                vehicle.odometer = odometerValue
            }
            vehicle.last_odometer = odometerValue
        }

        do {
            try viewContext.save()
            
            // Jadwalkan Notifikasi
            if addToReminder {
                Task { await scheduleReminderSafely(for: history, daysBefore: daysBeforeReminder) }
            }

            // 5. Logika Auto-Create untuk Servis Berikutnya
            // Hanya buat servis baru jika servis yang diinput barusan adalah "Selesai" (Masa lalu/Hari ini)
            if isInPastOrToday {
                createNextService(serviceName: trimmedName, fromDate: selectedDate, fromOdometer: odometerValue)
            } else if autoCreateNext {
                createNextService(serviceName: trimmedName, fromDate: selectedDate, fromOdometer: odometerValue)
            }

            successMessage = "Service added successfully!"
            clearFields()
            NotificationCenter.default.post(name: .init("DriveBuddyServiceAdded"), object: vehicle)

        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }

    // MARK: - Internal Logic

    /// Fungsi untuk mengecek apakah nama servis sudah ada di daftar Upcoming
    private func isDuplicateUpcoming(name: String) -> Bool {
        let request: NSFetchRequest<ServiceHistory> = ServiceHistory.fetchRequest()
        // [c] membuat pencarian tidak peka huruf besar/kecil (case-insensitive)
        // odometer == 0 menandakan servis tersebut masih "Upcoming"
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

    private func createNextService(serviceName: String, fromDate: Date, fromOdometer: Double) {
        // Cek lagi agar tidak double create jika user spam tombol save
        if isDuplicateUpcoming(name: serviceName) { return }
        
        guard let nextDate = Calendar.current.date(byAdding: .month, value: nextServiceMonths, to: fromDate) else { return }
        
        let upcomingService = ServiceHistory(context: viewContext)
        upcomingService.history_id = UUID()
        upcomingService.service_name = serviceName
        upcomingService.service_date = nextDate
        upcomingService.odometer = 0 // Ditandai sebagai servis yang belum dilakukan (Upcoming)
        upcomingService.created_at = Date()
        upcomingService.vehicle = vehicle
        
        try? viewContext.save()
    }

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
        reminder = "One month before"
        addToReminder = true
    }
}
