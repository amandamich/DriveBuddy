import SwiftUI
import CoreData

struct AddVehicleView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var authVM: AuthenticationViewModel
    @StateObject private var addVehicleVM: AddVehicleViewModel
    @StateObject private var profileVM: ProfileViewModel

    init(authVM: AuthenticationViewModel) {
        self._authVM = ObservedObject(initialValue: authVM)
        
        guard let user = authVM.currentUser else {
            fatalError("currentUser must not be nil in AddVehicleView")
        }
        
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
    }

    let vehicleTypes = ["Car", "Motorbike"]

    // MARK: - BODY FINAL
    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header - Back button only
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .padding(.top, 8)
                    
                    // Title
                    Text("New Vehicle")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
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

                    // MARK: Feedback
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
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
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

#Preview {
    NavigationStack {
        AddVehicleView(authVM: AuthenticationViewModel(context: PersistenceController.shared.container.viewContext))
    }
}
