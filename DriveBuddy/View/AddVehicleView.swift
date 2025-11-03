import SwiftUI
import CoreData

struct AddVehicleView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var authVM: AuthenticationViewModel
    @StateObject private var addVehicleVM: AddVehicleViewModel

    init(authVM: AuthenticationViewModel) {
        self._authVM = ObservedObject(initialValue: authVM)
        
        // use a mock user if currentUser is nil
        let user = authVM.currentUser ?? {
            let tempUser = User(context: PersistenceController.shared.container.viewContext)
            tempUser.user_id = UUID()
            tempUser.email = "preview@drivebuddy.com"
            tempUser.password_hash = "mock"
            tempUser.created_at = Date()
            return tempUser
        }()
        
        // Use the same context from your persistence controller
        _addVehicleVM = StateObject(
            wrappedValue: AddVehicleViewModel(
                context: PersistenceController.shared.container.viewContext,
                user: user
            )
        )
    }
    let vehicleTypes = ["Car", "Motorbike"]

    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                Text("Add New Vehicle")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top)

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // MARK: Vehicle Type
                        Text("Vehicle Type")
                            .foregroundColor(.white)
                        Menu {
                            ForEach(vehicleTypes, id: \.self) { type in
                                Button(type) { addVehicleVM.vehicleType = type }
                            }
                        } label: {
                            HStack {
                                Text(addVehicleVM.vehicleType.isEmpty ? "Select type" : addVehicleVM.vehicleType)
                                    .foregroundColor(.black)
                                Spacer()
                                Image(systemName: "chevron.down")
                            }
                            .padding()
                            .background(.white)
                            .cornerRadius(10)
                        }

                        // MARK: TextFields
                        Group {
                            TextField("Vehicle Model", text: $addVehicleVM.makeModel)
                                .padding()
                                .background(.white)
                                .cornerRadius(10)

                            TextField("License Plate", text: $addVehicleVM.plateNumber)
                                .padding()
                                .background(.white)
                                .cornerRadius(10)
                                .textInputAutocapitalization(.characters)

                            TextField("Year", text: $addVehicleVM.yearManufacture)
                                .padding()
                                .background(.white)
                                .cornerRadius(10)
                                .keyboardType(.numberPad)

                            TextField("Odometer (km)", text: $addVehicleVM.odometer)
                                .padding()
                                .background(.white)
                                .cornerRadius(10)
                                .keyboardType(.numberPad)
                        }

                        // MARK: Dates
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tax Due Date")
                                .foregroundColor(.white)
                            DatePicker("", selection: $addVehicleVM.taxDueDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .padding()
                                .background(.white)
                                .cornerRadius(10)

                            Text("STNK Due Date")
                                .foregroundColor(.white)
                            DatePicker("", selection: $addVehicleVM.stnkDueDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .padding()
                                .background(.white)
                                .cornerRadius(10)
                        }

                        // MARK: Add Button
                        Button(action: {
                            addVehicleVM.addVehicle()
                            if addVehicleVM.successMessage != nil {
                                dismiss()
                            }
                        }) {
                            Text("Add Vehicle")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue.opacity(0.8))
                                .cornerRadius(12)
                        }
                        .padding(.top, 10)

                        // MARK: Feedback
                        if let success = addVehicleVM.successMessage {
                            Text(success)
                                .foregroundColor(.green)
                                .font(.caption)
                                .padding(.top, 5)
                        }

                        if let error = addVehicleVM.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.top, 5)
                        }
                    }
                    .padding()
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    AddVehicleView(authVM: AuthenticationViewModel(context: PersistenceController.shared.container.viewContext))
}
