//
//  VehicleDetailVM.swift
//  DriveBuddy
//
//  Created by Jennifer Alicia Litan on 03/11/25.
//

import Foundation
import CoreData
import Combine
import SwiftUI

// Menggunakan @MainActor untuk memastikan semua pembaruan UI/Published dilakukan di thread utama
@MainActor
class VehicleDetailViewModel: ObservableObject {
    // MARK: - Properti Inti (Model)
    // Objek Core Data yang akan dilihat/diedit
    @Published var activeVehicle: Vehicles
    
    // MARK: - Properti Form Edit (State)
    // Properti yang mengikat (bind) ke form input di View
    @Published var makeModel: String = ""
    @Published var plateNumber: String = ""
    @Published var odometer: String = "" // String untuk input teks
    @Published var taxDueDate: Date = Date()
    @Published var stnkDueDate: Date = Date()
    @Published var serviceName: String = ""
    @Published var lastServiceDate: Date = Date()
    @Published var lastOdometer: String = "" // String untuk input teks
    
    // MARK: - Properti UI/Umpan Balik
    @Published var isEditing: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let viewContext: NSManagedObjectContext

    // MARK: - Inisialisasi
    
    init(context: NSManagedObjectContext, vehicle: Vehicles) {
        self.viewContext = context
        // Menerima objek kendaraan yang akan ditampilkan
        self.activeVehicle = vehicle
        
        // Memuat data awal ke properti @Published
        loadVehicleData()
    }

    // MARK: - FUNGSI PEMUATAN DATA
    
    // Menyalin data dari objek Core Data ke properti @Published untuk form
    private func loadVehicleData() {
        makeModel = activeVehicle.make_model ?? ""
        plateNumber = activeVehicle.plate_number ?? ""
        // Konversi Double (dari Core Data) ke String (untuk form input)
        odometer = activeVehicle.odometer.description
        taxDueDate = activeVehicle.tax_due_date ?? Date()
        stnkDueDate = activeVehicle.stnk_due_date ?? Date()
        serviceName = activeVehicle.service_name ?? ""
        lastServiceDate = activeVehicle.last_service_date ?? Date()
        lastOdometer = activeVehicle.last_odometer.description
    }

    // MARK: - FUNGSI EDIT DAN UPDATE

    // Dipanggil saat pengguna ingin mulai mengedit
    func startEditing() {
        loadVehicleData() // Memastikan data di form edit adalah yang terbaru
        isEditing = true
    }
    
    // Dipanggil saat pengguna menekan tombol Simpan (Save)
    func updateVehicle() {
        // --- 1. Validasi ---
        guard !makeModel.isEmpty, !plateNumber.isEmpty else {
            errorMessage = "Nama model atau plat nomor tidak boleh kosong."
            return
        }

        // --- 2. Penerapan Perubahan ke Model ---
        activeVehicle.make_model = makeModel
        activeVehicle.plate_number = plateNumber.uppercased()
        // Konversi String (dari form) ke Double (untuk Core Data)
        activeVehicle.odometer = Double(odometer) ?? 0
        activeVehicle.tax_due_date = taxDueDate
        activeVehicle.stnk_due_date = stnkDueDate
        activeVehicle.service_name = serviceName
        activeVehicle.last_service_date = lastServiceDate
        activeVehicle.last_odometer = Double(lastOdometer) ?? 0

        // --- 3. Penyimpanan Data ---
        do {
            try viewContext.save()
            successMessage = "Detail kendaraan berhasil diperbarui! 🎉"
            isEditing = false // Keluar dari mode edit
        } catch {
            errorMessage = "Gagal memperbarui kendaraan: \(error.localizedDescription)"
        }
    }
    
    // MARK: - FUNGSI HAPUS

    // Dipanggil saat pengguna ingin menghapus kendaraan
    func deleteVehicle() {
        viewContext.delete(activeVehicle)
        
        do {
            try viewContext.save()
            successMessage = "Kendaraan berhasil dihapus."
            // Catatan: Setelah ini berhasil, VehicleDetailView harus menutup dirinya (dismiss)
        } catch {
            errorMessage = "Gagal menghapus kendaraan: \(error.localizedDescription)"
        }
    }
}


