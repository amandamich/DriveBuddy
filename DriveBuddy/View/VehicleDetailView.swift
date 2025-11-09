import SwiftUI
import CoreData

struct VehicleDetailView: View {
    
    // 1. Mengambil Core Data Context dari Environment
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    // 2. ViewModel sebagai Sumber Logika dan Data
    @StateObject var viewModel: VehicleDetailViewModel
    
    // 3. Daftar Semua Kendaraan (untuk Dropdown)
    let allVehicles: [Vehicles]
    
    // 4. State Lokal untuk Sheet (ini diizinkan jika VM tidak mengelolanya)
    @State private var showAddService = false
    
    // MARK: Inisialisasi
    init(initialVehicle: Vehicles, allVehicles: [Vehicles], context: NSManagedObjectContext) {
        self.allVehicles = allVehicles
        // Meneruskan objek Vehicle spesifik ke ViewModel
        self._viewModel = StateObject(wrappedValue: VehicleDetailViewModel(context: context, vehicle: initialVehicle))
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // MARK: Header
                    HStack {
                        Image("LogoDriveBuddy")
                            .resizable().scaledToFit().frame(width: 180, height: 40)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // MARK: Vehicle Dropdown (Terhubung ke VM)
                    Menu {
                        ForEach(allVehicles, id: \.objectID) { v in // Gunakan objectID
                            Button(v.make_model ?? "Unknown") {
                                withAnimation(.easeInOut) {
                                    // Perintahkan VM untuk mengubah data
                                    viewModel.activeVehicle = v
                                    viewModel.loadVehicleData()
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "car.fill")
                                .foregroundColor(.cyan).imageScale(.medium)
                            
                            // Data dari VM
                            Text(viewModel.activeVehicle.make_model ?? "N/A")
                                .foregroundColor(.white).bold()
                            
                            Spacer()
                            
                            Image(systemName: "chevron.down")
                                .foregroundColor(.cyan.opacity(0.9))
                                .font(.system(size: 14, weight: .semibold))
                        }
                        // ... (Sisa styling Anda tetap dipertahankan) ...
                        .padding(.vertical, 14)
                        .padding(.horizontal, 18)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.black.opacity(0.35), Color.blue.opacity(0.25)]),
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.cyan.opacity(0.5), lineWidth: 1))
                        )
                        .cornerRadius(16)
                        .shadow(color: Color.cyan.opacity(0.3), radius: 8, x: 0, y: 4)
                        .padding(.horizontal)
                    }
                    
                    // MARK: Vehicle Info Card (Terhubung ke VM)
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .center, spacing: 20) {
                            // Data dari VM
                            Image(viewModel.activeVehicle.vehicle_type == "Car" ? "Car" : "Motorbike")
                                .resizable().scaledToFit().frame(width: 120, height: 70)
                                .padding(.leading, 6)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                // Data dari VM (gunakan make_model, plate_number)
                                Text(viewModel.activeVehicle.make_model?.uppercased() ?? "N/A")
                                    .font(.title3).fontWeight(.bold).foregroundColor(.white)
                                
                                Text(viewModel.activeVehicle.plate_number ?? "N/A")
                                    .font(.subheadline).foregroundColor(.gray)
                                
                                Text("\(Int(viewModel.activeVehicle.odometer)) km") // Data dari VM
                                    .font(.headline).foregroundColor(.white)
                            }
                            Spacer()
                            
                            // Tombol Edit (Terhubung ke VM)
                            Button(action: {
                                viewModel.startEditing() // Panggil fungsi VM
                            }) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                            }
                        }
                    }
                    .padding()
                    .background(Color(red: 17/255, green: 33/255, blue: 66/255))
                    .cornerRadius(18)
                    .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 4)
                    .padding(.horizontal)
                    
                    // MARK: Upcoming Services & Tax Section (Masih Statis)
                    HStack(alignment: .top, spacing: 16) {
                        InfoCard(
                            icon: "wrench.and.screwdriver.fill", title: "Upcoming Services",
                            subtitle: "Tire Rotation", date: "1 November 2025"
                        )
                        InfoCard(
                            icon: "banknote.fill", title: "Tax Payment",
                            subtitle: "Next Due", date: "2 January 2026"
                        )
                    }
                    .frame(height: 130)
                    .padding(.horizontal)
                    
                    // MARK: Last Service Section (Tombol Terhubung)
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Last Service")
                                .font(.headline).foregroundColor(.white)
                            Spacer()
                            Button(action: {
                                showAddService = true // Menggunakan @State lokal
                            }) {
                                Text("Add a service")
                                    .font(.subheadline).fontWeight(.semibold)
                                    .padding(.vertical, 10).padding(.horizontal, 22)
                                    .background(Color.blue).cornerRadius(25).foregroundColor(.white)
                            }
                        }
                        
                        Divider().background(Color.white.opacity(0.2))
                        
                        // Data statis Anda
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Oil Service"); Text("Engine Repair")
                            }
                            .foregroundColor(.white)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 6) {
                                Text("10 October 2025"); Text("27 October 2025")
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
        
        // MARK: Sheets (Terhubung ke VM dan State)
        .sheet(isPresented: $showAddService) {
            // AddServiceView() // Tampilan Anda untuk menambah servis
        }
        
        // Sheet ini dikontrol oleh ViewModel
        .sheet(isPresented: $viewModel.isEditing) {
            // Tampilkan form edit, dengan meneruskan ViewModel
            VehicleEditFormView(viewModel: viewModel)
        }
        
        // Menampilkan pesan sukses/error dari ViewModel
        .alert("Error", isPresented : .constant(viewModel.isShowingError)) {
            Button("Ok") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occured.")
        }
        .onReceive(viewModel.$successMessage) { message in
            if message != nil {
                // Anda bisa menampilkan alert sukses di sini jika mau
                // Untuk delete, kita akan dismiss
                if message == "Kendaraan berhasil dihapus." {
                    dismiss()
                }
            }
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
