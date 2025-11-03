import SwiftUI

struct DashboardView: View {
    @State private var vehicles: [Vehicle] = [
        Vehicle(makeAndModel: "Pajero Sport", vehicleType: "Car", licensePlate: "AB 1234 CD", year: "2021", odometer: "25000", taxDate: Date()),
        Vehicle(makeAndModel: "Honda Brio", vehicleType: "Car", licensePlate: "B 9876 FG", year: "2022", odometer: "30000", taxDate: Date())
    ]
    
    @State private var showingAddVehicle = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.opacity(0.95).ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 15) {
                    // MARK: Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("DriveBuddy")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Hello, Jonny 👋")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    .padding(.top, 30)
                    
                    Text("Your Vehicles")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    // MARK: Vehicle List
                    if vehicles.isEmpty {
                        Spacer()
                        Button(action: { showingAddVehicle = true }) {
                            Text("+ Add Vehicle")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(12)
                        }
                        .padding()
                        Spacer()
                    } else {
                        List {
                            ForEach(vehicles) { vehicle in
                                NavigationLink(destination: VehicleDetailView(vehicle: vehicle, allVehicles: vehicles)) {
                                    VehicleCard(vehicle: vehicle)
                                }
                            }
                            .onDelete(perform: deleteVehicle)
                            .listRowBackground(Color.black.opacity(0.8))
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                    
                    Spacer()
                }
                
                // Floating add button
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
            .sheet(isPresented: $showingAddVehicle) {
                AddVehicleView { newVehicle in
                    vehicles.append(newVehicle)
                }
            }
        }
    }
    
    // MARK: Delete Function
    private func deleteVehicle(at offsets: IndexSet) {
        withAnimation {
            vehicles.remove(atOffsets: offsets)
        }
    }
}

// MARK: - Vehicle Card
struct VehicleCard: View {
    var vehicle: Vehicle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(vehicle.makeAndModel)
                .font(.headline)
                .foregroundColor(.white)
            Text("Odometer: \(vehicle.odometer) km")
                .foregroundColor(.gray)
                .font(.subheadline)
            HStack {
                Label("Tax: \(vehicle.taxDate.formatted(date: .abbreviated, time: .omitted))", systemImage: "calendar")
                    .foregroundColor(.white)
                    .font(.caption)
                Spacer()
                Text("Upcoming")
                    .font(.caption)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color.orange)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.2))
        .cornerRadius(15)
    }
}

// MARK: - Preview
#Preview {
    DashboardView()
}
