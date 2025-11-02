//
//  DashboardView.swift
//  DriveBuddy
//
//  Created by Antonius Trimaryono on 02/11/25.
//

import SwiftUI

struct DashboardView: View {
    @State private var vehicles: [Vehicle] = [
        // Contoh data dummy
        Vehicle(makeAndModel: "Pajeroo", vehicleType: "Car", licensePlate: "B 1234 XYZ", year: "2021", odometer: "25000", taxDate: Date()),
        Vehicle(makeAndModel: "Brioo", vehicleType: "Car", licensePlate: "B 4321 ABC", year: "2022", odometer: "30000", taxDate: Date())
    ]
    
    @State private var showingAddVehicle = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 15) {
                // MARK: Header Section
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
                
                // MARK: Section Title
                Text("Your Vehicles")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .padding(.top, 10) // Tambahkan jarak dari header
                
                // MARK: Vehicle List
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(vehicles) { vehicle in
                            VehicleCard(vehicle: vehicle)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top, 10)
                }
                
                Spacer()
            }
            
            // MARK: Add Button
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

#Preview {
    DashboardView()
}
