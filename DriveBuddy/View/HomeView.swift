//
//  HomeView.swift
//  DriveBuddy
//
//  Created by Timothy on 28/10/25.
//

import SwiftUI
import CoreData

struct HomeView: View {
    @ObservedObject var authVM: AuthenticationViewModel
    @State private var selectedTab: Int = 0
    
    @Environment(\.managedObjectContext) private var viewContext
        
        // Ambil semua Vehicles dari Core Data
        @FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Vehicles.make_model, ascending: true)],
            animation: .default)
    private var allVehicles: FetchedResults<Vehicles>
    
    var body: some View {
        
        // 1. Tentukan Kendaraan Aktif (pertama dalam daftar, atau nil jika kosong)
        let activeVehicle = allVehicles.first
        
        // MARK: - Main Tab View
        TabView(selection: $selectedTab) {
            
            // MARK: Dashboard / Home
            DashboardView(authVM: authVM)
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)
            
            // MARK: Vehicles → langsung ke VehicleDetailView
            NavigationStack {
                // 2. Gunakan 'if let' untuk memastikan ada kendaraan sebelum memanggil View
                if let activeVehicle = activeVehicle {
                    VehicleDetailView(
                        // Menggunakan parameter baru dan data Core Data
                        initialVehicle: activeVehicle,
                        allVehicles: Array(allVehicles), // Konversi FetchedResults ke Array
                        context: viewContext // Meneruskan Core Data context
                    )
                } else {
                    // Tampilkan pesan atau View untuk menambahkan kendaraan jika allVehicles kosong
                    // Atau mungkin langsung menampilkan AddVehicleView jika user belum ada data kendaraan yang tersimpan di Core Data
                    VStack {
                        Image(systemName: "car.fill").font(.largeTitle)
                        Text("Anda belum memiliki kendaraan. Silakan tambahkan kendaraan pertama Anda.")
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
            }
            .tabItem {
                Label("Vehicle", systemImage: "gauge.with.dots.needle.67percent")
            }
            .tag(1)
            
            // MARK: Workshops
            WorkshopView()
                .tabItem {
                    Label("Workshops", systemImage: "wrench.and.screwdriver.fill")
                }
                .tag(2)
            
            // MARK: Profile
            ProfileView(authVM: authVM)
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
                .tag(3)
        }
        .tint(.blue)
    }
}

//
// MARK: - Subviews
//

//struct WorkshopsView: View {
//    var body: some View {
//        VStack {
//            Text("🛞🛠️ Nearby Workshops")
//                .font(.largeTitle)
//                .foregroundColor(.white)
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .background(Color.black.opacity(0.95))
//        .ignoresSafeArea()
//    }
//}

//struct ProfileView: View {
//    var body: some View {
//        VStack {
//            Text("👀 PROFILE")
//                .font(.largeTitle)
//                .foregroundColor(.white)
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .background(Color.black.opacity(0.95))
//        .ignoresSafeArea()
//    }
//}

#Preview {
    HomeView(authVM: AuthenticationViewModel(context: PersistenceController.shared.container.viewContext))
}
