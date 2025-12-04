import SwiftUI
import CoreData
import Combine

struct DashboardView: View {
    @ObservedObject var authVM: AuthenticationViewModel
    @Binding var selectedTab: Int  // ADDED: For tab switching
    @StateObject private var dashboardVM: DashboardViewModel
    @StateObject private var profileVM: ProfileViewModel
    @State private var showingAddVehicle = false
    @State private var refreshID = UUID()
    
    // Add @FetchRequest for automatic updates
    @FetchRequest var vehicles: FetchedResults<Vehicles>
    
    init(authVM: AuthenticationViewModel, selectedTab: Binding<Int>) {
        self.authVM = authVM
        self._selectedTab = selectedTab  // ADDED: Bind the tab
        
        // Safely unwrap user or provide a fallback
        guard let user = authVM.currentUser else {
            // Create empty view models with nil user (they should handle this)
            _dashboardVM = StateObject(
                wrappedValue: DashboardViewModel(
                    context: authVM.viewContext,
                    user: nil
                )
            )
            
            _profileVM = StateObject(
                wrappedValue: ProfileViewModel(
                    context: authVM.viewContext,
                    user: nil
                )
            )
            
            // Create empty fetch request
            _vehicles = FetchRequest<Vehicles>(
                sortDescriptors: [NSSortDescriptor(keyPath: \Vehicles.make_model, ascending: true)],
                predicate: NSPredicate(value: false) // Will return no results
            )
            return
        }
        
        _dashboardVM = StateObject(
            wrappedValue: DashboardViewModel(
                context: authVM.viewContext,
                user: user
            )
        )
        
        _profileVM = StateObject(
            wrappedValue: ProfileViewModel(
                context: authVM.viewContext,
                user: user
            )
        )
        
        // Setup FetchRequest for user's vehicles
        let userId = user.user_id ?? UUID()
        let predicate = NSPredicate(format: "user.user_id == %@", userId as CVarArg)
        let sortDescriptors = [NSSortDescriptor(keyPath: \Vehicles.make_model, ascending: true)]
        
        _vehicles = FetchRequest<Vehicles>(
            sortDescriptors: sortDescriptors,
            predicate: predicate
        )
    }
    
    // MARK: - Computed Property: Check if any vehicle has no tax date
    var vehiclesWithoutTaxDate: [Vehicles] {
        let filtered = vehicles.filter { $0.tax_due_date == nil }
        print("🔍 [Dashboard Debug] Total vehicles: \(vehicles.count)")
        print("🔍 [Dashboard Debug] Vehicles without tax date: \(filtered.count)")
        for vehicle in filtered {
            print("🔍 [Dashboard Debug] - \(vehicle.make_model ?? "Unknown") has no tax date")
        }
        return filtered
    }
    
    var body: some View {
        ZStack {
            // MARK: - Background
            Color.black.opacity(0.95).ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 15) {
                // MARK: - Header
                VStack(alignment: .leading, spacing: 4) {
                    Image("LogoDriveBuddy")
                        .resizable().scaledToFit().frame(width: 180, height: 40)
                    
                    Text("Hello, \(dashboardVM.extractUsername(from: authVM.currentUser?.email)) 👋")
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
                if vehicles.isEmpty {
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
                            ForEach(vehicles, id: \.vehicles_id) { vehicle in
                                // CHANGED: Use Button to switch tabs instead of sheet
                                Button(action: {
                                    // Switch to Vehicle tab (tag 1)
                                    selectedTab = 1
                                }) {
                                    VehicleCard(
                                        vehicle: vehicle,
                                        taxStatus: dashboardVM.taxStatus(for: vehicle),
                                        serviceStatus: dashboardVM.serviceReminderStatus(for: vehicle)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .listRowBackground(Color.black.opacity(0.8))
                            }
                            .onDelete { offsets in
                                dashboardVM.deleteVehicles(at: offsets, from: Array(vehicles))
                                refreshID = UUID()
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .padding(.top, 10)
                        .id(refreshID)
                        
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
        .sheet(isPresented: $showingAddVehicle) {
            refreshID = UUID()
        } content: {
            AddVehicleView(authVM: authVM)
                .environment(\.managedObjectContext, authVM.viewContext)
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: authVM.viewContext)) { _ in
            refreshID = UUID()
        }
    }
}

// MARK: - Vehicle Card Component
extension DashboardView {
    struct VehicleCard: View {
        @ObservedObject var vehicle: Vehicles
        var taxStatus: VehicleTaxStatus
        var serviceStatus: ServiceReminderStatus
        
        // Check if tax date is missing
        private var isTaxDateMissing: Bool {
            vehicle.tax_due_date == nil
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                
                // MARK: - Header (Vehicle Name + Plate)
                VStack(alignment: .leading, spacing: 4) {
                    Text(vehicle.make_model ?? "Unknown Vehicle")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Odometer: \(vehicle.odometer.formatted(.number.grouping(.automatic))) km")
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                }
                
                // MARK: - Tax Warning Banner (if tax date not set)
                if isTaxDateMissing {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.orange)
                        
                        Text("Tax due date not set. Tap to set.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [
                                Color.orange.opacity(0.3),
                                Color.orange.opacity(0.2)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.orange.opacity(0.5), lineWidth: 1)
                    )
                }
                
                // MARK: - Divider
                Divider()
                    .background(Color.white.opacity(0.15))
                
                // MARK: - Tax Row (only show if tax date is set)
                if !isTaxDateMissing {
                    HStack(alignment: .center) {
                        Image(systemName: "calendar")
                            .font(.system(size: 17))
                            .foregroundColor(.gray)
                        
                        Text("Tax:")
                            .foregroundColor(.gray)
                            .font(.system(size: 15))
                        
                        Text(vehicle.tax_due_date?.formatted(date: .abbreviated, time: .omitted) ?? "N/A")
                            .foregroundColor(.white)
                            .font(.system(size: 15))
                        Spacer()
                        
                        Text(taxStatus.label)
                            .font(.system(size: 13, weight: .semibold))
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(taxStatus.color.opacity(0.9))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                    }
                }
                
                // MARK: - Service Row
                HStack {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 17))
                        .foregroundColor(.gray)
                    
                    Text("Next Service:")
                        .foregroundColor(.gray)
                        .font(.system(size: 15))
                    
                    Text(nextServiceDateText(for: vehicle))
                        .foregroundColor(.white)
                        .font(.system(size: 15))
                    Spacer()
                    Text(serviceStatus.label)
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(serviceStatus.color.opacity(0.9))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.05, green: 0.07, blue: 0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: isTaxDateMissing ?
                                [.orange.opacity(0.6), .orange.opacity(0.4)] :
                                [.cyan.opacity(0.6), .blue.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(
                color: isTaxDateMissing ?
                    .orange.opacity(0.3) :
                    .cyan.opacity(0.25),
                radius: 12,
                x: 0,
                y: 4
            )
        }
        
        // MARK: - Service Date Helper
        private func nextServiceDateText(for vehicle: Vehicles) -> String {
            guard let next = vehicle.next_service_date else { return "N/A" }
            return next.formatted(date: .abbreviated, time: .omitted)
        }
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
    
    return NavigationStack {
        DashboardView(authVM: mockAuthVM, selectedTab: .constant(0))
    }
    
}
