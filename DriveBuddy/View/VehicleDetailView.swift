// VehicleDetailView

import SwiftUI
import CoreData

struct VehicleDetailView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject var viewModel: VehicleDetailViewModel
    let allVehicles: [Vehicles]
    
    @State private var showAddService = false
    @State private var showMyService = false
    
    // Init untuk menerima objek User Aktif
    init(initialVehicle: Vehicles, allVehicles: [Vehicles], context: NSManagedObjectContext, activeUser: User) {
        self.allVehicles = allVehicles
        
        // Init viewmodel dengan meneruskan objek user
        _viewModel = StateObject(wrappedValue: VehicleDetailViewModel(
            context: context,
            vehicle: initialVehicle,
            activeUser: activeUser
        ))
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
                    // Di dalam VehicleDetailView, di bawah header logo
                    Text("Debug: Total Kendaraan = \(allVehicles.count)")
                        .font(.caption)
                        .foregroundColor(.red)
                    
                    // MARK: VEHICLE DROPDOWN
                    Menu {
                        ForEach(allVehicles, id: \.objectID) { v in
                            Button(v.make_model ?? "Unknown") {
                                withAnimation(.easeInOut) {
                                    // cek jika relasi user di v sama dengan user aktif di VM, ini memastikan User B tidak bisa pindah ke mobil milik User A
                                    if v.user == viewModel.activeUser {
                                        viewModel.activeVehicle = v
                                        viewModel.loadVehicleData()
                                        
                                    } else {
                                        print ("User B coba pindah mobil ke milik User A")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "car.fill")
                                .foregroundColor(.cyan)
                                .imageScale(.medium)
                            
                            Text(viewModel.makeModel.isEmpty ? "Nama Kosong" : viewModel.makeModel.uppercased())
                                .font(.title3)
                                .bold()
                                .foregroundColor(.white)
                            
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
                                
                                Text(viewModel.plateNumber.isEmpty ? "No Plat" : viewModel.plateNumber)
                                    .foregroundColor(.gray)
                                
                                Text("\(viewModel.formattedOdometer)")
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
                        .buttonStyle(CardButtonStyle())
                        .frame(maxWidth: .infinity)
                        
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
                        .buttonStyle(CardButtonStyle())
                        .frame(maxWidth: .infinity)
                    }
                    .frame(height: 140)
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
        .onAppear {
            print("[Debug] VehicleDetailView Muncul")
            viewModel.loadVehicleData() // Paksa muat ulang data saat layar tampil
        }
        
        // SWIPE BACK
        .sheet(isPresented: $showMyService) {
            NavigationView {
                // Catatan: MyServiceView harus didefinisikan untuk kompilasi berhasil
                MyServiceView(
                    vehicle: viewModel.activeVehicle,
                    context: viewContext,
                    activeUser: viewModel.activeUser
                )
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
            // PENTING: Nama View ini harus sesuai dengan struct di bawah
            EditVehicleView(viewModel: viewModel)
        }
        
        
        .navigationBarBackButtonHidden(true)
    }
    
}


// MARK: - Custom Button Style for Cards (Enhanced with Spring Animation)
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .brightness(configuration.isPressed ? 0.08 : 0)
            .shadow(
                color: .cyan.opacity(configuration.isPressed ? 0.5 : 0.3),
                radius: configuration.isPressed ? 12 : 10,
                x: 0,
                y: configuration.isPressed ? 3 : 5
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}


// MARK: - Clickable Card Component (Compact Version)
struct ClickableCard: View {
    var icon: String
    var title: String
    var subtitle: String
    var date: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            
            // Icon and title section
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(title)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .minimumScaleFactor(0.85)
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Text(subtitle)
                .lineLimit(1)
                .foregroundColor(.white.opacity(0.85))
                .font(.system(size: 13, weight: .regular))
            
            Spacer(minLength: 2)
            
            // Date section at bottom
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 10, weight: .medium))
                Text(date)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                
                Spacer()
                
                // Chevron indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.cyan.opacity(0.9))
            }
            .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    }
}


// MARK: - Edit Form View
// Saya mengubah nama dari VehicleEditFormView menjadi EditVehicleView agar sesuai dengan panggilan di baris 254
//struct EditVehicleView: View {
//    // Menerima ViewModel yang sama
//    @ObservedObject var viewModel: VehicleDetailViewModel
//    @Environment(\.dismiss) private var dismiss
//    
//    var body: some View {
//        NavigationView {
//            Form {
//                Section(header: Text("Informasi Kendaraan")) {
//                    // Binding ($) ke properti di VM
//                    TextField("Make and Model", text: $viewModel.makeModel)
//                    TextField("Plate Number", text: $viewModel.plateNumber)
//                }
//                Section(header: Text("Data")) {
//                    TextField("Odometer", text: $viewModel.odometer)
//                        .keyboardType(.numberPad)
//                    DatePicker("Tax Due Date", selection: $viewModel.taxDueDate, displayedComponents: .date)
//                }
//                
//                Section {
//                    Button("Delete Vehicle", role: .destructive) {
//                        viewModel.deleteVehicle()
//                        dismiss() // Tutup form
//                    }
//                }
//            }
//            .navigationTitle("Edit Vehicle")
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button("Cancel") {
//                        dismiss() // Tutup sheet
//                    }
//                }
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button("Save") {
//                        viewModel.updateVehicle() // Panggil fungsi save di VM
//                        // VM akan otomatis menutup sheet jika sukses
//                        if viewModel.successMessage != nil {
//                            dismiss()
//                        }
//                    }
//                }
//            }
//        }
//    }
//}

// MARK: - Preview Helper Functions

private func setupUser(context: NSManagedObjectContext) -> User {
    let user = User(context: context)
    user.user_id = UUID()
    user.email = "preview@user.com"
    return user
}

private func setupVehicle(context: NSManagedObjectContext, makeModel: String, plate: String, odometer: Double, user: User) -> Vehicles {
    let vehicle = Vehicles(context: context)
    vehicle.make_model = makeModel
    vehicle.plate_number = plate
    vehicle.vehicle_type = "Car"
    vehicle.odometer = odometer
    vehicle.tax_due_date = Date().addingTimeInterval(86400 * 365) // Set 1 tahun ke depan
    vehicle.user = user // <<< PENTING: Menautkan ke User
    return vehicle
}


#Preview {
    let context = PersistenceController.preview.container.viewContext

    // 1. Buat Dummy User
    let dummyUser = setupUser(context: context)
    
    // 2. Buat Dummy Vehicles yang terikat ke User
    let dummyVehicle = setupVehicle(context: context, makeModel: "Pajero Sport", plate: "AB 1234 CD", odometer: 25000, user: dummyUser)
    let dummyVehicle2 = setupVehicle(context: context, makeModel: "Honda Brio", plate: "B 9876 FG", odometer: 30000, user: dummyUser)

    // 3. Inisialisasi View dengan User Aktif
    return VehicleDetailView(
        initialVehicle: dummyVehicle,
        allVehicles: [dummyVehicle, dummyVehicle2],
        context: context,
        activeUser: dummyUser // <<< Perbaikan Krusial: User Aktif harus ada
    )
    .environment(\.managedObjectContext, context)
}
