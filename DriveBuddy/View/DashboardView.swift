import SwiftUI
import CoreData

struct DashboardView: View {
    @ObservedObject var authVM: AuthenticationViewModel
    @StateObject private var dashboardVM: DashboardViewModel
    @State private var showingAddVehicle = false

    init(authVM: AuthenticationViewModel) {
        _authVM = ObservedObject(initialValue: authVM)
        
        // Use a fallback mock user if currentUser is nil
        let user = authVM.currentUser ?? {
            let tempUser = User(context: authVM.viewContext)
            tempUser.user_id = UUID()
            tempUser.email = "preview@drivebuddy.com"
            tempUser.password_hash = "mock"
            tempUser.created_at = Date()
            return tempUser
        }()

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
                // MARK: Background
                Color.black.opacity(0.95).ignoresSafeArea()

                VStack(alignment: .leading, spacing: 15) {
                    // MARK: Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("DriveBuddy")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)

                        Text("Hello, \(authVM.currentUser?.email ?? "User") 👋")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    .padding(.top, 30)

                    // MARK: Title
                    Text("Your Vehicles")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .padding(.top, 10)

                    // MARK: Vehicle List
                    if dashboardVM.userVehicles.isEmpty {
                        Spacer()
                        VStack {
                            Text("No vehicles added yet.")
                                .foregroundColor(.gray)
                                .padding(.bottom, 10)

                            Button(action: { showingAddVehicle = true }) {
                                Text("+ Add Vehicle")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(dashboardVM.userVehicles, id: \.self) { vehicle in
                                VehicleCard(
                                    vehicle: vehicle,
                                    status: dashboardVM.taxStatus(for: vehicle)
                                )
                                .listRowBackground(Color.black.opacity(0.8))
                            }
                            .onDelete(perform: dashboardVM.deleteVehicle)
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }

                // MARK: Floating Add Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
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
                }
            }
            // MARK: Add Vehicle Sheet
            .sheet(isPresented: $showingAddVehicle, onDismiss: {
                dashboardVM.fetchVehicles()
            }) {
                AddVehicleView(authVM: authVM)
            }
        }
    }
}

 // MARK: - Vehicle Card Component (inside same file)
struct VehicleCard: View {
    var vehicle: Vehicles
    var status: VehicleTaxStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(vehicle.make_model ?? "Unknown Vehicle")
                .font(.headline)
                .foregroundColor(.white)

            Text("Odometer: \(Int(vehicle.odometer)) km")
                .foregroundColor(.gray)
                .font(.subheadline)

            HStack {
                Label("Tax: \(vehicle.tax_due_date?.formatted(date: .abbreviated, time: .omitted) ?? "N/A")", systemImage: "calendar")
                    .foregroundColor(.white)
                    .font(.caption)
                Spacer()

                // Status Badge
                Text(status.label)
                    .font(.caption)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(status.color)
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
}

 // MARK: - Preview
#Preview {
    let context = PersistenceController.shared.container.viewContext

    // Mock user for preview
    let mockUser = User(context: context)
    mockUser.user_id = UUID()
    mockUser.email = "preview@drivebuddy.com"
    mockUser.password_hash = "mockhash"
    mockUser.created_at = Date()

    // Mock vehicle for preview
    let mockVehicle = Vehicles(context: context)
    mockVehicle.make_model = "Honda Brio"
    mockVehicle.vehicle_type = "Car"
    mockVehicle.plate_number = "B 9876 FG"
    mockVehicle.tax_due_date = Calendar.current.date(byAdding: .day, value: 10, to: Date())
    mockVehicle.odometer = 25000
    mockVehicle.user = mockUser
    try? context.save()

    // Mock authentication VM
    let mockAuthVM = AuthenticationViewModel(context: context)
    mockAuthVM.currentUser = mockUser
    mockAuthVM.isAuthenticated = true

    return DashboardView(authVM: mockAuthVM)
}
