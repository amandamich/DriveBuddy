//
//  EditVehicleView.swift
//  DriveBuddy
//

import SwiftUI

struct EditVehicleView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: VehicleDetailViewModel
    
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // MARK: - Title
                    Text("Edit Vehicle")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top)
                    
                    // MARK: - Vehicle Info Section
                    VStack(alignment: .leading, spacing: 12) {
                        
                        Group {
                            // Make & Model
                            Text("Make & Model")
                                .foregroundColor(.white)
                            TextField("Honda Brio", text: $viewModel.makeModel)
                                .textFieldStyle(CustomTextFieldStyle())
                            
                            // Plate Number
                            Text("Plate Number")
                                .foregroundColor(.white)
                            TextField("L 567 GX", text: $viewModel.plateNumber)
                                .textFieldStyle(CustomTextFieldStyle())
                                .textInputAutocapitalization(.characters)
                            
                            // Odometer
                            Text("Odometer (km)")
                                .foregroundColor(.white)
                            TextField("45000", text: $viewModel.odometer)
                                .textFieldStyle(CustomTextFieldStyle())
                                .keyboardType(.numberPad)
                        }
                        
                        // Tax Date
                        Text("Tax Due Date")
                            .foregroundColor(.white)
                        DatePicker("", selection: $viewModel.taxDueDate, displayedComponents: .date)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                        
                        // STNK
                        Text("STNK Due Date")
                            .foregroundColor(.white)
                        DatePicker("", selection: $viewModel.stnkDueDate, displayedComponents: .date)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                        
                        // Last Service Name
                        Text("Last Service Name")
                            .foregroundColor(.white)
                        TextField("Tune-Up", text: $viewModel.serviceName)
                            .textFieldStyle(CustomTextFieldStyle())
                        
                        // Last Service Date
                        Text("Last Service Date")
                            .foregroundColor(.white)
                        DatePicker("", selection: $viewModel.lastServiceDate, displayedComponents: .date)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                        
                        // Last Odometer
                        Text("Last Odometer (km)")
                            .foregroundColor(.white)
                        TextField("42000", text: $viewModel.lastOdometer)
                            .textFieldStyle(CustomTextFieldStyle())
                            .keyboardType(.numberPad)
                        
                    }
                    .padding()
                    .background(Color.blue.opacity(0.15))
                    .cornerRadius(15)
                    
                    // MARK: - Save Button
                    Button {
                        viewModel.updateVehicle()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            dismiss()
                        }
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
    struct CustomTextFieldStyle: TextFieldStyle {
        func _body(configuration: TextField<Self._Label>) -> some View {
            configuration
                .padding()
                .background(Color.white)
                .cornerRadius(10)
        }
    }
}
#Preview {
    
}
    

