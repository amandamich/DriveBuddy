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
            
            // Dashboard / Home
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)
            
            // Vehicles
            VehicleView()
                .tabItem {
                    Label("Vehicle", systemImage: "gauge.with.dots.needle.67percent")
                }
                .tag(1)
            
            // Workshops
            WorkshopsView()
                .tabItem {
                    Label("Workshops", systemImage: "wrench.and.screwdriver.fill")
                }
                .tag(2)
            
            // Profile
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

struct VehicleView: View {
    var body: some View {
        VStack {
            Text("👀 VEHICLE")
                .font(.largeTitle)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.95))
        .ignoresSafeArea()
    }
}

struct WorkshopsView: View {
    var body: some View {
        VStack {
            Text("🛞🛠️ Nearby Workshops")
                .font(.largeTitle)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.95))
        .ignoresSafeArea()
    }
}

struct ProfileView: View {
    var body: some View {
        VStack {
            Text("👀 PROFILE")
                .font(.largeTitle)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.95))
        .ignoresSafeArea()
    }
}

#Preview {
    HomeView(authVM: AuthenticationViewModel(context: PersistenceController.shared.container.viewContext))
}
