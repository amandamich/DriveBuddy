import SwiftUI
import CoreData

struct DashboardView: View {
    @ObservedObject var authVM: AuthenticationViewModel
    @StateObject private var dashboardVM: DashboardViewModel
    @State private var showingAddVehicle = false
    
    init(authVM: AuthenticationViewModel) {
        _authVM = ObservedObject(initialValue: authVM)
        guard let user = authVM.currentUser else {
            fatalError("currentUser should not be nil in DashboardView")
        }
        
        _dashboardVM = StateObject(
            wrappedValue: DashboardViewModel(
                context: authVM.viewContext,
                user: user
            )
        )
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Background
                Color.black.opacity(0.95).ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 15) {
                    // MARK: - Header
                    VStack(alignment: .leading, spacing: 4) {
                        Image("LogoDriveBuddy")
                            .resizable().scaledToFit().frame(width: 180, height: 40)
                        
                        Text("Hello, \(authVM.currentUser?.email ?? "User") 👋")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    .padding(.top, 30)
                    
                    // MARK: - Title
                    Text("Your Vehicles")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    // MARK: - Vehicle List
                    if dashboardVM.userVehicles.isEmpty {
                        //                        Spacer()
                        VStack {
                            Text("No vehicles added yet.")
                                .foregroundColor(.gray)
                                .padding(.bottom, 10)
                            
                            Button(action: { showingAddVehicle = true }) {
                                Text("+ Add Vehicle")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 45)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.cyan, lineWidth: 2)
                                            .shadow(color: .blue, radius: 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color.black.opacity(0.5))
                                            )
                                    )
                                    .shadow(color: .blue, radius: 10)
                            }
                            .padding(.horizontal)
                        }
                        Spacer()
                    } else {
                        ZStack(alignment: .bottomTrailing){
                            List {
                                ForEach(dashboardVM.userVehicles, id: \.vehicles_id) { vehicle in
                                    VehicleCard(
                                        vehicle: vehicle,
                                        taxStatus: dashboardVM.taxStatus(for: vehicle),
                                        serviceStatus: dashboardVM.serviceReminderStatus(for: vehicle)
                                    )
                                    .listRowBackground(Color.black.opacity(0.8))
                                }
                                .onDelete(perform: dashboardVM.deleteVehicle)
                            }
                            .listStyle(.plain)
                            .scrollContentBackground(.hidden)
                            .padding(.top, 10)
                            Button(action: { showingAddVehicle = true }) {
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                    .shadow(radius: 5)
                            }
                            .padding()
                        }
                        .frame(maxHeight: .infinity)
                    }
                }
            }
                    
                    // MARK: - Add Vehicle Sheet
                        .sheet(isPresented: $showingAddVehicle, onDismiss: {
                            dashboardVM.fetchVehicles()
                        }) {
                            AddVehicleView(authVM: authVM)
                        }
                }
            }
        }
        
        // MARK: - Vehicle Card Component
        struct VehicleCard: View {
            var vehicle: Vehicles
            var taxStatus: VehicleTaxStatus
            var serviceStatus: ServiceReminderStatus
            
            var body: some View {
                VStack(alignment: .leading, spacing: 8) {
                    // MARK: - Vehicle Info
                    Text(vehicle.make_model ?? "Unknown Vehicle")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Odometer: \(Int(vehicle.odometer)) km")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                    
                    // MARK: - Tax Info
                    HStack {
                        Label("Tax: \(vehicle.tax_due_date?.formatted(date: .abbreviated, time: .omitted) ?? "N/A")", systemImage: "calendar")
                            .foregroundColor(.white)
                            .font(.caption)
                        Spacer()
                        
                        Text(taxStatus.label)
                            .font(.caption)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(taxStatus.color)
                            .cornerRadius(8)
                            .foregroundColor(.white)
                    }
                    
                    // MARK: - Service Info
                    HStack {
                        Label("Next Service: \(nextServiceDateText(for: vehicle))", systemImage: "wrench.and.screwdriver.fill")
                            .foregroundColor(.white)
                            .font(.caption)
                        Spacer()
                        
                        Text(serviceStatus.label)
                            .font(.caption)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(serviceStatus.color)
                            .cornerRadius(8)
                            .foregroundColor(.white)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.cyan, lineWidth: 1.5)
                        .background(Color.black.opacity(0.6))
                        .shadow(color: .blue.opacity(0.3), radius: 5)
                )
            }
            
            // MARK: - Compute Next Service Date Text
            private func nextServiceDateText(for vehicle: Vehicles) -> String {
                guard let lastServiceDate = vehicle.last_service_date else { return "N/A" }
                if let nextService = Calendar.current.date(byAdding: .month, value: 6, to: lastServiceDate) {
                    return nextService.formatted(date: .abbreviated, time: .omitted)
                }
                return "N/A"
            }
        }
        
        // MARK: - Preview
        #Preview {
            let context = PersistenceController.shared.container.viewContext
            
            // Mock user
            let mockUser = User(context: context)
            mockUser.user_id = UUID()
            mockUser.email = "preview@drivebuddy.com"
            mockUser.password_hash = "mockhash"
            mockUser.created_at = Date()
            
            // Mock vehicle
            let mockVehicle = Vehicles(context: context)
            mockVehicle.make_model = "Honda Brio"
            mockVehicle.vehicle_type = "Car"
            mockVehicle.plate_number = "B 9876 FG"
            mockVehicle.tax_due_date = Calendar.current.date(byAdding: .day, value: 10, to: Date())
            mockVehicle.last_service_date = Calendar.current.date(byAdding: .day, value: 3, to: Date())
            mockVehicle.odometer = 25000
            mockVehicle.user = mockUser
            
            let mockAuthVM = AuthenticationViewModel(context: context)
            mockAuthVM.currentUser = mockUser
            mockAuthVM.isAuthenticated = true
            
            return DashboardView(authVM: mockAuthVM)
        }
