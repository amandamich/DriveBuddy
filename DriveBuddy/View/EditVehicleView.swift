//
//  EditVehicleView.swift
//  DriveBuddy
//

import SwiftUI

struct EditVehicleView: View {
    
    @ObservedObject var viewModel: VehicleDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Header
                    Text("Edit Vehicle")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 8)
                    
                    // MARK: - Vehicle Information Section
                    SectionBoxEdit(title: "Vehicle Information", icon: "car.fill") {
                        VStack(alignment: .leading, spacing: 15) {
                            // Make & Model
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Make & Model")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                TextField("e.g., Toyota Avanza", text: $viewModel.makeModel)
                                    .textFieldStyle(CustomTextFieldStyleEdit())
                            }
                            
                            // Plate Number
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Plate Number")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                TextField("e.g., B 1234 XYZ", text: $viewModel.plateNumber)
                                    .textInputAutocapitalization(.characters)
                                    .textFieldStyle(CustomTextFieldStyleEdit())
                            }
                            
                            // Odometer
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Current Odometer (km)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                TextField("e.g., 50000", text: $viewModel.odometer)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(CustomTextFieldStyleEdit())
                            }
                        }
                    }
                    
                    // MARK: - Document Dates Section
                    SectionBoxEdit(title: "Document Dates", icon: "doc.text.fill") {
                        VStack(alignment: .leading, spacing: 15) {
                            // Tax Due Date
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Tax Due Date")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                HStack {
                                    DatePicker("", selection: $viewModel.taxDueDate, displayedComponents: .date)
                                        .labelsHidden()
                                        .datePickerStyle(.compact)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                            }
                            
                            // STNK Due Date
                            VStack(alignment: .leading, spacing: 6) {
                                Text("STNK Due Date")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                HStack {
                                    DatePicker("", selection: $viewModel.stnkDueDate, displayedComponents: .date)
                                        .labelsHidden()
                                        .datePickerStyle(.compact)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                            }
                        }
                    }
                    
                    // MARK: - Last Service Information Section
                    SectionBoxEdit(title: "Last Service Information", icon: "wrench.and.screwdriver.fill") {
                        VStack(alignment: .leading, spacing: 15) {
                            // Service Name
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Service Name")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                TextField("e.g., Oil Change", text: $viewModel.serviceName)
                                    .textFieldStyle(CustomTextFieldStyleEdit())
                            }
                            
                            // Last Service Date
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Service Date")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                HStack {
                                    DatePicker("", selection: $viewModel.lastServiceDate, displayedComponents: .date)
                                        .labelsHidden()
                                        .datePickerStyle(.compact)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                            }
                            
                            // Last Service Odometer
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Odometer at Service (km)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                TextField("e.g., 48000", text: $viewModel.lastOdometer)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(CustomTextFieldStyleEdit())
                            }
                        }
                    }
                    
                    // MARK: - Save Button
                    Button(action: {
                        viewModel.updateVehicle()
                        if viewModel.errorMessage == nil {
                            dismiss()
                        }
                    }) {
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
                    
                    // MARK: - Delete Button
                    Button(action: {
                        viewModel.isShowingDeleteConfirmation = true
                    }) {
                        Text("Delete Vehicle")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red.opacity(0.8), lineWidth: 2)
                                    .shadow(color: .red.opacity(0.4), radius: 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.black.opacity(0.5))
                                    )
                            )
                            .shadow(color: .red.opacity(0.4), radius: 10)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .alert("Delete Vehicle?", isPresented: $viewModel.isShowingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteVehicle()
                dismiss()
            }
        } message: {
            Text("This action cannot be undone. All service history for this vehicle will also be deleted.")
        }
        .alert("Success", isPresented: .constant(viewModel.successMessage != nil)) {
            Button("OK") {
                viewModel.successMessage = nil
            }
        } message: {
            if let success = viewModel.successMessage {
                Text(success)
            }
        }
    }
}

// MARK: - Shared Components
struct SectionBoxEdit<Content: View>: View {
    var title: String
    var icon: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(.cyan)
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

struct CustomTextFieldStyleEdit: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.white)
            .cornerRadius(10)
    }
}
