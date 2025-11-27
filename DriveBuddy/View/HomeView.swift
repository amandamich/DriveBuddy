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
struct HomeView: View {
    @ObservedObject var authVM: AuthenticationViewModel
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        // Get current user ID
        let currentID = authVM.currentUserID ?? ""
        
        // Show main content with user ID
        MainContentView(authVM: authVM, userIDString: currentID)
            .id(currentID)
            .onAppear {
                print("🏠 HomeView appeared with userID: \(currentID)")
            }
            .onDisappear {
                print("🏠 HomeView disappeared")
            }
    }
}

// MARK: - 2. MAIN CONTENT VIEW (LOGIC UTAMA)
struct MainContentView: View {
    @ObservedObject var authVM: AuthenticationViewModel
    @State private var selectedTab: Int = 0
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest var userVehicles: FetchedResults<Vehicles>
    @FetchRequest var userResult: FetchedResults<User>
    
    init(authVM: AuthenticationViewModel, userIDString: String) {
        self.authVM = authVM
        
        let targetUUID = UUID(uuidString: userIDString) ?? UUID()
        
        _userVehicles = FetchRequest(
            entity: Vehicles.entity(),
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Vehicles.make_model, ascending: true)
            ],
            predicate: NSPredicate(format: "user.user_id == %@", targetUUID as CVarArg)
        )
        
        _userResult = FetchRequest(
            entity: User.entity(),
            sortDescriptors: [],
            predicate: NSPredicate(format: "user_id == %@", targetUUID as CVarArg)
        )
    }
    
    var body: some View {
        let activeUser = userResult.first
        let activeVehicle = userVehicles.first
        
        TabView(selection: $selectedTab) {
            
            // TAB 1: Dashboard - Pass selectedTab binding
            NavigationStack {
                DashboardView(authVM: authVM, selectedTab: $selectedTab)
            }
            .tabItem { Label("Home", systemImage: "house") }
            .tag(0)
            
            // TAB 2: Vehicles
            NavigationStack {
                if let vehicle = activeVehicle, let user = activeUser {
                    let profileVM = ProfileViewModel(context: viewContext, user: user)
                    VehicleDetailView(
                        initialVehicle: vehicle,
                        allVehicles: userVehicles,
                        context: viewContext,
                        activeUser: user,
                        profileVM: profileVM
                    )
                } else {
                    VStack(spacing: 20) {
                        if activeUser == nil {
                            Text("Menunggu Data Pengguna...")
                                .foregroundColor(.gray)
                        } else {
                            Image(systemName: "car.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.gray.opacity(0.5))
                            
                            Text("Total Kendaraan: \(userVehicles.count)")
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
            NavigationStack {
                ProfileView(authVM: authVM)
            }
            .tabItem { Label("Profile", systemImage: "person") }
            .tag(3)
        }
        .tint(.blue)
        .onAppear {
            print("📱 MainContentView appeared")
            // Reset to home tab when appearing
            selectedTab = 0
        }
        .onDisappear {
            print("📱 MainContentView disappeared")
        }
    }
}
