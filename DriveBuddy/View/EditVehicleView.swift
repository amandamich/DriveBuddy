//
//  EditVehicleView.swift
//  DriveBuddy
//

import SwiftUI

struct EditVehicleView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var working: Vehicle
    let onSave: (Vehicle) -> Void

    init(vehicle: Vehicle, onSave: @escaping (Vehicle) -> Void) {
        _working = State(initialValue: vehicle)
        self.onSave = onSave
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // MARK: Header
                    Text("Edit Vehicle")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top)
                    
                    // MARK: Vehicle Info
                    VStack(alignment: .leading, spacing: 12) {
                        Group {
                            Text("Make & Model").foregroundColor(.white)
                            TextField("Enter model", text: $working.makeAndModel)
                                .textFieldStyle(CustomTextFieldStyle())
                            
                            Text("License Plate").foregroundColor(.white)
                            TextField("Enter plate", text: $working.licensePlate)
                                .textFieldStyle(CustomTextFieldStyle())
                            
                            Text("Odometer").foregroundColor(.white)
                            TextField("Enter odometer", text: $working.odometer)
                                .textFieldStyle(CustomTextFieldStyle())
                                .keyboardType(.numberPad)
                            
                            Text("Tax Due Date").foregroundColor(.white)
                            DatePicker("", selection: $working.taxDate, displayedComponents: .date)
                                .labelsHidden()
                                .datePickerStyle(.compact)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.15))
                    .cornerRadius(15)
                    
                    // MARK: Save Button
                    Button {
                        onSave(working)
                        dismiss()
                    } label: {
                        Text("Save Changes")
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
                    .padding(.top, 10)
                }
                .padding(.horizontal)
            }
        }
    }
}



#Preview {
    EditVehicleView(
        vehicle: Vehicle(
            makeAndModel: "Pajero Sport",
            vehicleType: "Car",
            licensePlate: "AB 1234 CD",
            year: "2021",
            odometer: "25000",
            taxDate: Date()
        ),
        onSave: { _ in } // closure dummy untuk preview
    )
}

