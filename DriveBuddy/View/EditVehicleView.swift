//
//  EditVehicleView.swift
//  DriveBuddy
//

import SwiftUI

struct EditVehicleView: View {
    
    @ObservedObject var viewModel: VehicleDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.opacity(0.95).ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // MARK: - Vehicle Information Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Vehicle Information")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            // Make & Model
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Make & Model")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                TextField("e.g., Toyota Avanza", text: $viewModel.makeModel)
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(10)
                                    .foregroundColor(.white)
                            }
                            
                            // Plate Number
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Plate Number")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                TextField("e.g., B 1234 XYZ", text: $viewModel.plateNumber)
                                    .textInputAutocapitalization(.characters)
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(10)
                                    .foregroundColor(.white)
                            }
                            
                            // Odometer
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Current Odometer (km)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                TextField("e.g., 50000", text: $viewModel.odometer)
                                    .keyboardType(.numberPad)
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(10)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                        .background(Color(red: 17/255, green: 33/255, blue: 66/255))
                        .cornerRadius(18)
                        
                        // MARK: - Document Dates Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Document Dates")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            // Tax Due Date
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Tax Due Date")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                DatePicker("", selection: $viewModel.taxDueDate, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(10)
                            }
                            
                            // STNK Due Date
                            VStack(alignment: .leading, spacing: 8) {
                                Text("STNK Due Date")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                DatePicker("", selection: $viewModel.stnkDueDate, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(10)
                            }
                        }
                        .padding()
                        .background(Color(red: 17/255, green: 33/255, blue: 66/255))
                        .cornerRadius(18)
                        
                        // MARK: - Last Service Information Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Last Service Information")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            // Service Name
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Service Name")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                TextField("e.g., Oil Change", text: $viewModel.serviceName)
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(10)
                                    .foregroundColor(.white)
                            }
                            
                            // Last Service Date
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Service Date")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                DatePicker("", selection: $viewModel.lastServiceDate, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(10)
                            }
                            
                            // Last Service Odometer
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Odometer at Service (km)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                TextField("e.g., 48000", text: $viewModel.lastOdometer)
                                    .keyboardType(.numberPad)
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(10)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                        .background(Color(red: 17/255, green: 33/255, blue: 66/255))
                        .cornerRadius(18)
                        
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
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [Color.blue, Color.cyan],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(color: .cyan.opacity(0.4), radius: 8, x: 0, y: 4)
                        }
                        .padding(.top, 10)
                        
                        // MARK: - Delete Button
                        Button(action: {
                            viewModel.isShowingDeleteConfirmation = true
                        }) {
                            Text("Delete Vehicle")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.8))
                                .cornerRadius(12)
                        }
                        
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.cyan)
                }
            }
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
}
