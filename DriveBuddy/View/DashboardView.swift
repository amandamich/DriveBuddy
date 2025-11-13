import SwiftUI
import CoreData

import SwiftUI
import CoreData

struct DashboardView: View {
    @ObservedObject var authVM: AuthenticationViewModel
    @State private var showingAddVehicle = false

    @FetchRequest var vehicles: FetchedResults<Vehicles>

    init(authVM: AuthenticationViewModel) {
        self.authVM = authVM

        let user = authVM.currentUser!

        _vehicles = FetchRequest(
            entity: Vehicles.entity(),
            sortDescriptors: [
                NSSortDescriptor(key: "created_at", ascending: true) // newest at bottom
            ],
            predicate: NSPredicate(format: "user == %@", user)
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.opacity(0.95).ignoresSafeArea()

                VStack(alignment: .leading, spacing: 15) {

                    // HEADER
                    VStack(alignment: .leading, spacing: 4) {
                        Image("LogoDriveBuddy")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 180, height: 40)

                        Text("Hello, \(authVM.currentUser?.email ?? "User") 👋")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    .padding(.top, 30)

                    // TITLE
                    Text("Your Vehicles")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .padding(.top, 10)

                    // LIST
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
                        List {
                            ForEach(vehicles, id: \.vehicles_id) { vehicle in
                                VehicleCard(
                                    vehicle: vehicle,
                                    taxStatus: taxStatus(for: vehicle),
                                    serviceStatus: serviceStatus(for: vehicle)
                                )
                                .listRowBackground(Color.black.opacity(0.8))
                            }
                            .onDelete(perform: deleteVehicle)
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)

                        // FLOATING BUTTON
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
                }
            }
            .sheet(isPresented: $showingAddVehicle) {
                AddVehicleView(authVM: authVM)
            }
        }
    }

    // DELETE VEHICLE
    private func deleteVehicle(at offsets: IndexSet) {
        offsets.map { vehicles[$0] }.forEach { authVM.viewContext.delete($0) }
        try? authVM.viewContext.save()
    }

    // TAX STATUS
    private func taxStatus(for vehicle: Vehicles) -> VehicleTaxStatus {
        guard let due = vehicle.tax_due_date else { return .unknown }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: due).day ?? 0

        if days < 0 { return .overdue }
        if days <= 7 { return .dueSoon }
        return .valid
    }

    // SERVICE STATUS
    private func serviceStatus(for vehicle: Vehicles) -> ServiceReminderStatus {
        guard let last = vehicle.last_service_date else { return .unknown }
        guard let next = Calendar.current.date(byAdding: .month, value: 6, to: last) else { return .unknown }

        let days = Calendar.current.dateComponents([.day], from: Date(), to: next).day ?? 0

        if days < 0 { return .overdue }
        if days == 1 { return .tomorrow }
        if days <= 7 { return .soon }
        if days <= 30 { return .upcoming }
        return .notYet
    }
}
// MARK: - Vehicle Card Component
struct VehicleCard: View {
    var vehicle: Vehicles
    var taxStatus: VehicleTaxStatus
    var serviceStatus: ServiceReminderStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            Text(vehicle.make_model ?? "Unknown Vehicle")
                .font(.headline)
                .foregroundColor(.white)

            Text("Odometer: \(Int(vehicle.odometer)) km")
                .foregroundColor(.gray)
                .font(.subheadline)

            HStack {
                Label(
                    "Tax: \(vehicle.tax_due_date?.formatted(date: .abbreviated, time: .omitted) ?? "N/A")",
                    systemImage: "calendar"
                )
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

            HStack {
                Label(
                    "Next Service: \(nextServiceDateText)",
                    systemImage: "wrench.and.screwdriver.fill"
                )
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

    // 🔥 FIX: THIS MUST BE INSIDE VEHICLECARD, NOT IN DASHBOARDVIEW
    private var nextServiceDateText: String {
        guard let last = vehicle.last_service_date else { return "N/A" }
        if let next = Calendar.current.date(byAdding: .month, value: 6, to: last) {
            return next.formatted(date: .abbreviated, time: .omitted)
        }
        return "N/A"
    }
}

