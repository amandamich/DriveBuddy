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
    
    var body: some View {
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
                VehicleDetailView(
                    vehicle: Vehicle(
                        makeAndModel: "Pajero Sport",
                        vehicleType: "Car",
                        licensePlate: "L 1111 E",
                        year: "2021",
                        odometer: "20357",
                        taxDate: Date()
                    ),
                    allVehicles: [
                        Vehicle(makeAndModel: "Pajero Sport", vehicleType: "Car", licensePlate: "L 1111 E", year: "2021", odometer: "20357", taxDate: Date()),
                        Vehicle(makeAndModel: "Honda Brio", vehicleType: "Car", licensePlate: "B 9876 FG", year: "2022", odometer: "30000", taxDate: Date())
                    ]
                )
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
            ProfileView()
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
