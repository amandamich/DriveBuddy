import SwiftUI
import CoreData

struct VehicleDetailView: View {
    var vehicle: Vehicle
    var allVehicles: [Vehicle]
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedVehicle: Vehicle?
    @State private var showAddService = false
    @State private var showEditVehicle = false
    
    var activeVehicle: Vehicle {
        selectedVehicle ?? vehicle
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    
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
                        HStack(alignment: .center, spacing: 20) {
                            // Gambar kiri
                            Image(activeVehicle.vehicleType == "Car" ? "Car" : "Motorbike")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 70)
                                .padding(.leading, 6)
                            
                            // Teks kanan
                            VStack(alignment: .leading, spacing: 6) {
                                Text(activeVehicle.makeAndModel.uppercased())
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text(activeVehicle.licensePlate)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                Text("\(activeVehicle.odometer) km")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            
                            // Tombol Edit
                            Button(action: {
                                showEditVehicle = true
                            }) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding()
                    .background(Color(red: 17/255, green: 33/255, blue: 66/255))
                    .cornerRadius(18)
                    .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 4)
                    .padding(.horizontal)
                    
                    // MARK: Upcoming Services & Tax Section
                    HStack(alignment: .top, spacing: 16) {
                        InfoCard(
                            icon: "wrench.and.screwdriver.fill",
                            title: "Upcoming Services",
                            subtitle: "Tire Rotation",
                            date: "1 November 2025"
                        )
                        
                        InfoCard(
                            icon: "banknote.fill",
                            title: "Tax Payment",
                            subtitle: "Next Due",
                            date: "2 January 2026"
                        )
                    }
                    .frame(height: 130) // ✅ SAME HEIGHT for both cards
                    .padding(.horizontal)
                    
                    // MARK: Last Service Section
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Last Service")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                            Button(action: {
                                showAddService = true
                            }) {
                                Text("Add a service")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 22)
                                    .background(Color.blue)
                                    .cornerRadius(25)
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Divider().background(Color.white.opacity(0.2))
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Oil Service")
                                Text("Engine Repair")
                            }
                            .foregroundColor(.white)
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 6) {
                                Text("10 October 2025")
                                Text("27 October 2025")
                            }
                            .foregroundColor(.white.opacity(0.8))
                        }
                        .font(.subheadline)
                    }
                    .padding()
                    .background(Color(red: 17/255, green: 33/255, blue: 66/255))
                    .cornerRadius(18)
                    .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 4)
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
        // MARK: Sheets
        .sheet(isPresented: $showAddService) {
            AddServiceView()
        }
        .sheet(isPresented: $showEditVehicle) {
            EditVehicleView(vehicle: activeVehicle) { updated in
                selectedVehicle = updated
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Info Card Component
struct InfoCard: View {
    var icon: String
    var title: String
    var subtitle: String
    var date: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
            }
            .foregroundColor(.white)
            .font(.headline)
            
            Text(subtitle)
                .foregroundColor(.white)
                .font(.subheadline)
            
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                Text(date)
            }
            .font(.caption)
            .foregroundColor(.white.opacity(0.8))
            
            Spacer() // ✅ Biar isi tetap rata atas tapi tinggi konsisten
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(red: 17/255, green: 33/255, blue: 66/255))
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 4)
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
