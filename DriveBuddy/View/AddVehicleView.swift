import SwiftUI
import CoreData

struct AddVehicleView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var authVM: AuthenticationViewModel
    @StateObject private var addVehicleVM: AddVehicleViewModel
    @StateObject private var profileVM: ProfileViewModel
    @State private var showError = false
    @State private var errorMessage = ""

    init(authVM: AuthenticationViewModel) {
        self._authVM = ObservedObject(initialValue: authVM)
        
        // ✅ FIXED: Safe unwrapping WITHOUT fatalError
        if let user = authVM.currentUser {
            _addVehicleVM = StateObject(
                wrappedValue: AddVehicleViewModel(
                    context: PersistenceController.shared.container.viewContext,
                    user: user
                )
            )
            
            _profileVM = StateObject(
                wrappedValue: ProfileViewModel(
                    context: PersistenceController.shared.container.viewContext,
                    user: user
                )
            )
        } else {
            // ✅ Create temporary placeholder WITHOUT crashing
            let tempContext = PersistenceController.shared.container.viewContext
            let tempUser = User(context: tempContext)
            
            _addVehicleVM = StateObject(
                wrappedValue: AddVehicleViewModel(
                    context: tempContext,
                    user: tempUser
                )
            )
            
            _profileVM = StateObject(
                wrappedValue: ProfileViewModel(
                    context: tempContext,
                    user: tempUser
                )
            )
            
            print("⚠️ WARNING: currentUser is nil in AddVehicleView init")
        }
    }

    let vehicleTypes = ["Car", "Motorbike"]

    // MARK: HEADER
    var headerView: some View {
        HStack(spacing: 12) {
            // Back button
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 100000)
                            .fill(Color.white.opacity(0.15))
                    )
            }

            // Title
            Text("New Vehicle")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(Color.black.opacity(0.95))
    }

    // MARK: - SCROLL CONTENT
    var contentView: some View {
        VStack(alignment: .leading, spacing: 24) {
            
            // ✅ Show error if user is not logged in
            if authVM.currentUser == nil {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    Text("User Not Found")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    Text("Please log out and log in again to continue.")
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Go Back")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.cyan, lineWidth: 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.black.opacity(0.5))
                                    )
                            )
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Normal content when user is logged in
                VStack(alignment: .leading, spacing: 24) {
                    // MARK: Vehicle Info Section
                    SectionBox(title: "Vehicle Info", icon: "car.fill") {
                        Group {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Make & Model")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                TextField("Honda Brio", text: $addVehicleVM.makeModel)
                                    .textFieldStyle(CustomTextFieldStyle())
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Vehicle Type")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                Menu {
                                    ForEach(vehicleTypes, id: \.self) { type in
                                        Button(type) { addVehicleVM.vehicleType = type }
                                    }
                                } label: {
                                    HStack {
                                        Text(addVehicleVM.vehicleType.isEmpty ? "Select Vehicle Type" : addVehicleVM.vehicleType)
                                            .foregroundColor(addVehicleVM.vehicleType.isEmpty ? .gray : .black)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(10)
                                }
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("License Plate Number")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                TextField("L 567 GX", text: $addVehicleVM.plateNumber)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .textInputAutocapitalization(.characters)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Year of Manufacture")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                TextField("2019", text: $addVehicleVM.yearManufacture)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(CustomTextFieldStyle())
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Current Odometer")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                TextField("4500 km", text: $addVehicleVM.odometer)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(CustomTextFieldStyle())
                            }
                        }
                    }

                    // MARK: Last Service Section
                    SectionBox(title: "History Last Service", icon: "wrench.and.screwdriver.fill") {
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Last Service Date")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                HStack {
                                    DatePicker("", selection: $addVehicleVM.lastServiceDate, displayedComponents: .date)
                                        .labelsHidden()
                                        .datePickerStyle(.compact)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Service Item")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                TextField("Tune-Up", text: $addVehicleVM.serviceName)
                                    .textFieldStyle(CustomTextFieldStyle())
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Odometer at Last Service")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                TextField("42000 km", text: $addVehicleVM.lastOdometer)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(CustomTextFieldStyle())
                            }
                        }
                    }

                    // MARK: Add Button
                    Button(action: {
                        Task {
                            await addVehicleVM.addVehicle(profileVM: profileVM)
                            if addVehicleVM.successMessage != nil {
                                dismiss()
                            }
                        }
                    }) {
                        Text("Add Vehicle")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
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

                    // MARK: Feedback Messages
                    if let success = addVehicleVM.successMessage {
                        Text(success)
                            .foregroundColor(.green)
                            .font(.caption)
                    }

                    if let error = addVehicleVM.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }

                    if let warning = addVehicleVM.warningMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(warning)
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - BODY
    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()

            VStack(spacing: 0) {
                headerView
                
                ScrollView {
                    contentView
                        .padding(.top, 10)
                }
            }
        }
        .navigationBarHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // ✅ Check if user is logged in when view appears
            if authVM.currentUser == nil {
                print("⚠️ WARNING: currentUser is nil in AddVehicleView")
                print("⚠️ Email: \(authVM.email)")
                print("⚠️ isAuthenticated: \(authVM.isAuthenticated)")
            } else {
                print("✅ AddVehicleView: User is logged in: \(authVM.currentUser?.email ?? "")")
            }
        }
    }
}

// MARK: - Custom Components

struct SectionBox<Content: View>: View {
    var title: String
    var icon: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
            }

            VStack(spacing: 12) {
                content
            }
            .padding()
            .background(Color.blue.opacity(0.15))
            .cornerRadius(15)
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.white)
            .cornerRadius(10)
    }
}

// MARK: - Preview
#Preview {
    AddVehicleView(authVM: AuthenticationViewModel(context: PersistenceController.shared.container.viewContext))
}
