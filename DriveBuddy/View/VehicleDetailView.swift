import SwiftUI

struct VehicleDetailView: View {
    var vehicle: Vehicle
    var allVehicles: [Vehicle]
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedVehicle: Vehicle?
    
    var activeVehicle: Vehicle {
        selectedVehicle ?? vehicle
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // MARK: Header
                    HStack {
                        Image("LogoDriveBuddy")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 180, height: 40)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // MARK: Vehicle Dropdown
                    Menu {
                        ForEach(allVehicles, id: \.id) { v in
                            Button(v.makeAndModel) {
                                withAnimation(.easeInOut) {
                                    selectedVehicle = v
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(activeVehicle.makeAndModel)
                                .foregroundColor(.white)
                                .bold()
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.white)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                    }
                    
                    // MARK: Vehicle Info Card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image("CarIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 50)
                            Spacer()
                            Button(action: {}) {
                                Image(systemName: "pencil")
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Text(activeVehicle.makeAndModel.uppercased())
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                        
                        Text(activeVehicle.licensePlate)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text("\(activeVehicle.odometer) km")
                            .font(.title3)
                            .bold()
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    
                    // MARK: Upcoming Services & Tax Example Section
                    HStack(spacing: 15) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "wrench.and.screwdriver.fill")
                                Text("Upcoming Services")
                            }
                            .foregroundColor(.white)
                            .font(.headline)
                            Text("Tire Rotation")
                                .foregroundColor(.white)
                            Label("1 November 2025", systemImage: "calendar")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.caption)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.3))
                        .cornerRadius(15)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "banknote")
                                Text("Tax Payment")
                            }
                            .foregroundColor(.white)
                            .font(.headline)
                            Text("2 January 2026")
                                .foregroundColor(.white)
                            Label("Next Due", systemImage: "calendar")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.caption)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.3))
                        .cornerRadius(15)
                    }
                    .padding(.horizontal)
                    
                    // MARK: Last Service Section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Last Service")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                            Button(action: {}) {
                                Text("Add a service")
                                    .font(.caption)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .background(Color.blue.opacity(0.8))
                                    .foregroundColor(.white)
                                    .cornerRadius(20)
                            }
                        }
                        
                        Divider().background(Color.white.opacity(0.2))
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Oil Service")
                                Text("Engine Repair")
                            }
                            .foregroundColor(.white)
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("10 October 2025")
                                Text("27 October 2025")
                            }
                            .foregroundColor(.white.opacity(0.8))
                        }
                        .font(.subheadline)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    
                    Spacer(minLength: 50)
                }
                .padding(.bottom, 80)
            }
        }
        // Swipe gesture back
        .gesture(DragGesture().onEnded { value in
            if value.translation.width > 100 { dismiss() }
        })
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    VehicleDetailView(
        vehicle: Vehicle(makeAndModel: "Pajero Sport", vehicleType: "Car", licensePlate: "AB 1234 CD", year: "2021", odometer: "25000", taxDate: Date()),
        allVehicles: [
            Vehicle(makeAndModel: "Pajero Sport", vehicleType: "Car", licensePlate: "AB 1234 CD", year: "2021", odometer: "25000", taxDate: Date()),
            Vehicle(makeAndModel: "Honda Brio", vehicleType: "Car", licensePlate: "B 9876 FG", year: "2022", odometer: "30000", taxDate: Date())
        ]
    )
}
