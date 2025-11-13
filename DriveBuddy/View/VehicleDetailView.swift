import SwiftUI
import CoreData

struct VehicleDetailView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject var viewModel: VehicleDetailViewModel
    let allVehicles: [Vehicles]
    
    @State private var showAddService = false
    @State private var showMyService = false
    
    // Init
    init(initialVehicle: Vehicles, allVehicles: [Vehicles], context: NSManagedObjectContext) {
        self.allVehicles = allVehicles
        _viewModel = StateObject(wrappedValue: VehicleDetailViewModel(context: context, vehicle: initialVehicle))
    }
    
    
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
                    
                    
                    // MARK: VEHICLE DROPDOWN
                    Menu {
                        ForEach(allVehicles, id: \.objectID) { v in
                            Button(v.make_model ?? "Unknown") {
                                withAnimation(.easeInOut) {
                                    viewModel.activeVehicle = v
                                    viewModel.loadVehicleData()
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "car.fill")
                                .foregroundColor(.cyan)
                                .imageScale(.medium)
                            
                            Text(viewModel.activeVehicle.make_model ?? "N/A")
                                .foregroundColor(.white)
                                .bold()
                            
                            Spacer()
                            
                            Image(systemName: "chevron.down")
                                .foregroundColor(.cyan.opacity(0.9))
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 18)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.3),
                                    Color.blue.opacity(0.25)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
                        )
                        .cornerRadius(16)
                        .shadow(color: .cyan.opacity(0.3), radius: 7, x: 0, y: 4)
                        .padding(.horizontal)
                    }
                    
                    
                    // MARK: VEHICLE INFO BOX
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 20) {
                            
                            Image(viewModel.activeVehicle.vehicle_type == "Car" ? "Car" : "Motorbike")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 70)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text(viewModel.activeVehicle.make_model?.uppercased() ?? "")
                                    .font(.title3)
                                    .bold()
                                    .foregroundColor(.white)
                                
                                Text(viewModel.activeVehicle.plate_number ?? "")
                                    .foregroundColor(.gray)
                                
                                Text("\(Int(viewModel.activeVehicle.odometer)) km")
                                    .foregroundColor(.white)
                                    .font(.headline)
                            }
                            
                            Spacer()
                            
                            Button(action: { viewModel.startEditing() }) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding()
                    .background(Color(red: 17/255, green: 33/255, blue: 66/255))
                    .cornerRadius(18)
                    .shadow(color: .cyan.opacity(0.25), radius: 6, x: 0, y: 4)
                    .padding(.horizontal)
                    
                    
                    // MARK: UPCOMING SERVICE & TAX CLICKABLE SECTION
                    HStack(spacing: 16) {
                        
                        // UPCOMING SERVICES
                        Button(action: {
                            showMyService = true
                        }) {
                            ClickableCard(
                                icon: "wrench.and.screwdriver.fill",
                                title: "Upcoming Services",
                                subtitle: "Tire Rotation",
                                date: "1 November 2025"
                            )
                        }
                        
                        // TAX PAYMENT
                        Button(action: {
                            print("Tax clicked")
                        }) {
                            ClickableCard(
                                icon: "banknote.fill",
                                title: "Tax Payment",
                                subtitle: "Next Due",
                                date: "2 January 2026"
                            )
                        }
                    }
                    .frame(height: 150)
                    .padding(.horizontal)
                    
                    
                    // MARK: LAST SERVICE + BUTTON
                    VStack(alignment: .leading, spacing: 10) {
                        
                        HStack {
                            Text("Last Service")
                                .foregroundColor(.white)
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: { showAddService = true }) {
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
                    .shadow(color: .cyan.opacity(0.25), radius: 6, x: 0, y: 4)
                    .padding(.horizontal)
                    
                    Spacer(minLength: 60)
                }
            }
        }
        
        // SWIPE BACK
        .sheet(isPresented: $showMyService) {
            NavigationView {
                MyServiceView(vehicle: viewModel.activeVehicle, context: viewContext)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: { showMyService = false }) {
                                Image(systemName: "chevron.left")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
            }
        }

        
        // EDIT VEHICLE SHEET
        .sheet(isPresented: $viewModel.isEditing) {
            VehicleEditFormView(viewModel: viewModel)
        }
        
        
        .navigationBarBackButtonHidden(true)
    }
}


// MARK: - Info Card Component (Tidak berubah)
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
            .foregroundColor(.white).font(.headline)
            
            Text(subtitle)
                .foregroundColor(.white).font(.subheadline)
            
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                Text(date)
            }
            .font(.caption).foregroundColor(.white.opacity(0.8))
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(red: 17/255, green: 33/255, blue: 66/255))
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 4)
    }
}

struct ClickableCard: View {
    var icon: String
    var title: String
    var subtitle: String
    var date: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            HStack(spacing: 8) {
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
            .foregroundColor(.white.opacity(0.85))
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 20/255, green: 36/255, blue: 70/255),
                    Color(red: 27/255, green: 56/255, blue: 112/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.cyan.opacity(0.7), lineWidth: 1.5)
        )
        .cornerRadius(18)
        .shadow(color: .cyan.opacity(0.35), radius: 8, x: 0, y: 5)
    }
}


// MARK: - Kerangka Edit Form View (Penting)
struct VehicleEditFormView: View {
    // Menerima ViewModel yang sama
    @ObservedObject var viewModel: VehicleDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Informasi Kendaraan")) {
                    // Binding ($) ke properti di VM
                    TextField("Make and Model", text: $viewModel.makeModel)
                    TextField("Plate Number", text: $viewModel.plateNumber)
                }
                Section(header: Text("Data")) {
                    TextField("Odometer", text: $viewModel.odometer)
                        .keyboardType(.numberPad)
                    DatePicker("Tax Due Date", selection: $viewModel.taxDueDate, displayedComponents: .date)
                }
                
                Section {
                    Button("Delete Vehicle", role: .destructive) {
                        viewModel.deleteVehicle()
                        dismiss() // Tutup form
                    }
                }
            }
            .navigationTitle("Edit Vehicle")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss() // Tutup sheet
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.updateVehicle() // Panggil fungsi save di VM
                        // VM akan otomatis menutup sheet jika sukses
                        if viewModel.successMessage != nil {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview (Diperbarui untuk Core Data)
// Tambahkan fungsi pembantu ini di luar struct View Anda
private func setupVehicle(context: NSManagedObjectContext, makeModel: String, plate: String, odometer: Double) -> Vehicles {
    let vehicle = Vehicles(context: context)
    vehicle.make_model = makeModel
    vehicle.plate_number = plate
    vehicle.vehicle_type = "Car"
    vehicle.odometer = odometer
    vehicle.tax_due_date = Date()
    return vehicle
}

#Preview {
    let context = PersistenceController.preview.container.viewContext

    // 💡 PERBAIKAN: Panggil fungsi yang mengembalikan Vehicles
    let dummyVehicle = setupVehicle(context: context, makeModel: "Pajero Sport", plate: "AB 1234 CD", odometer: 25000)
    let dummyVehicle2 = setupVehicle(context: context, makeModel: "Honda Brio", plate: "B 9876 FG", odometer: 30000)

    VehicleDetailView(
        initialVehicle: dummyVehicle,
        allVehicles: [dummyVehicle, dummyVehicle2],
        context: context
    )
    .environment(\.managedObjectContext, context)
}
