//
//  HomeView.swift
//  DriveBuddy
//

import SwiftUI
import CoreData
import Combine

// MARK: - AppState Class
class AppState: ObservableObject {
    @Published var currentUserID: String = ""
}

// MARK: - 1. HOME VIEW (WRAPPER)
// Tugasnya hanya mendengarkan perubahan Auth dan memanggil MainContent
struct HomeView: View {
    @ObservedObject var authVM: AuthenticationViewModel
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        // Ambil ID Pengguna saat ini
        // Jika nil, gunakan string kosong (User belum login)
        let currentID = authVM.currentUserID ?? ""
        
        // Panggil MainContent dan kirim ID-nya
        // .id(currentID) memaksa View dibuat ulang jika ID berubah
        MainContentView(authVM: authVM, userIDString: currentID)
            .id(currentID)
    }
}

// MARK: - 2. MAIN CONTENT VIEW (LOGIC UTAMA)
// View ini baru akan dibuat setelah kita punya User ID yang valid
struct MainContentView: View {
    @ObservedObject var authVM: AuthenticationViewModel
    @State private var selectedTab: Int = 0
    @Environment(\.managedObjectContext) private var viewContext
    
    // Fetch Request untuk Vehicles
    @FetchRequest var userVehicles: FetchedResults<Vehicles>
    
    // Fetch Request untuk User Owner
    @FetchRequest var userResult: FetchedResults<User>
    
    init(authVM: AuthenticationViewModel, userIDString: String) {
        self.authVM = authVM
        
        // Konversi String ID ke UUID untuk Predicate Core Data
        let targetUUID = UUID(uuidString: userIDString) ?? UUID()
        
        // A. FETCH VEHICLES: Ambil kendaraan milik User ID ini
        // Sortir berdasarkan tanggal dibuat agar yang baru muncul
        _userVehicles = FetchRequest(
            entity: Vehicles.entity(),
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Vehicles.make_model, ascending: true)
            ],
            predicate: NSPredicate(format: "user.user_id == %@", targetUUID as CVarArg)
        )
        
        // B. FETCH USER: Ambil data User itu sendiri
        _userResult = FetchRequest(
            entity: User.entity(),
            sortDescriptors: [],
            predicate: NSPredicate(format: "user_id == %@", targetUUID as CVarArg)
        )
    }
    
    var body: some View {
        let activeUser = userResult.first
        // Ambil kendaraan pertama dari hasil fetch
        let activeVehicle = userVehicles.first
        
        TabView(selection: $selectedTab) {
            
            // TAB 1: Dashboard
            DashboardView(authVM: authVM)
                .tabItem { Label("Home", systemImage: "house") }
                .tag(0)
            
            // TAB 2: Vehicles
            NavigationStack {
                // Cek apakah ada kendaraan
                if let vehicle = activeVehicle, let user = activeUser {
                    let profileVM = ProfileViewModel(context: viewContext, user: user)
                    // TAMPILKAN DETAIL
                    VehicleDetailView(
                        initialVehicle: vehicle,
                        allVehicles: Array(userVehicles), // Kirim semua hasil fetch ke dropdown
                        context: viewContext,
                        activeUser: user,
                        profileVM: profileVM
                    )
                    
                } else {
                    // TAMPILAN KOSONG (EMPTY STATE)
                    VStack(spacing: 20) {
                        if activeUser == nil {
                            Text("Menunggu Data Pengguna...")
                                .foregroundColor(.gray)
                        } else {
                            Image(systemName: "car.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.gray.opacity(0.5))
                            
                            Text("Total Kendaraan: \(userVehicles.count)") // Debug Text
                                .font(.caption).foregroundColor(.red)
                            
                            Text("Belum ada kendaraan.\nTambahkan di Dashboard.")
                                .multilineTextAlignment(.center)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .tabItem { Label("Vehicle", systemImage: "gauge.with.dots.needle.67percent") }
            .tag(1)
            
            // TAB 3: Workshops
            WorkshopView()
                .tabItem { Label("Workshops", systemImage: "wrench.and.screwdriver.fill") }
                .tag(2)
            
            // TAB 4: Profile
            ProfileView(authVM: authVM)
                .tabItem { Label("Profile", systemImage: "person") }
                .tag(3)
        }
        .tint(.blue)
    }
}

// MARK: - Placeholder Views (JANGAN LUPA HAPUS JIKA SUDAH ADA FILE ASLINYA)
// struct WorkshopView: View { var body: some View { Text("Workshop") } }
// struct ProfileView: View { @ObservedObject var authVM: AuthenticationViewModel; var body: some View { Text("Profile") } }
