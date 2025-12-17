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
        let currentID = authVM.currentUserID ?? ""
        
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

// MARK: - Empty Vehicle View
struct EmptyVehicleView: View {
    @Binding var selectedTab: Int
    let activeUser: User?
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // MARK: HEADER
                    HStack {
                        Image("LogoDriveBuddy")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 180, height: 40)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // MARK: Empty State Content
                    VStack(spacing: 24) {
                        Spacer()
                        
                        if activeUser == nil {
                            Text("Waiting for User Data...")
                                .foregroundColor(.white.opacity(0.7))
                        } else {
                            VStack(spacing: 24) {
                                Image(systemName: "car.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.cyan.opacity(0.6))
                                
                                VStack(spacing: 12) {
                                    Text("No Vehicles Yet")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    
                                    Text("Add your first vehicle\nin Dashboard to get started")
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.white.opacity(0.7))
                                        .font(.subheadline)
                                }
                                
                                Button(action: {
                                    selectedTab = 0
                                }) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Add Vehicle")
                                    }
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 14)
                                    .padding(.horizontal, 28)
                                    .background(
                                        LinearGradient(
                                            colors: [
                                                Color.blue.opacity(0.8),
                                                Color.cyan.opacity(0.6)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(25)
                                    .shadow(color: .cyan.opacity(0.4), radius: 8, x: 0, y: 4)
                                }
                            }
                            .padding(32)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(red: 17/255, green: 33/255, blue: 66/255).opacity(0.6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, 32)
                        }
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, minHeight: 400)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 2. MAIN CONTENT VIEW
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
            
            // TAB 1: Dashboard
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
                    EmptyVehicleView(selectedTab: $selectedTab, activeUser: activeUser)
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
            selectedTab = 0
        }
        .onDisappear {
            print("📱 MainContentView disappeared")
        }
    }
}

