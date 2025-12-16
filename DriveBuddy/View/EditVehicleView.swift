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
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // MARK: - Header
                    VStack(spacing: 8) {
                        Text("Edit Vehicle")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .blue, radius: 10)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
                    
                    // MARK: - Vehicle Information Section
                    SectionBoxEdit(title: "Vehicle Information", icon: "car.fill") {
                        VStack(alignment: .leading, spacing: 15) {
                            // Make & Model
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Make & Model")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                TextField("", text: $viewModel.makeModel, prompt: Text("e.g., Toyota Avanza").foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4)))
                                    .textFieldStyle(CustomTextFieldStyleEdit())
                            }
                            
                            // Plate Number
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Plate Number")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                TextField("", text: $viewModel.plateNumber, prompt: Text("e.g., B 1234 XYZ").foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4)))
                                    .textInputAutocapitalization(.characters)
                                    .textFieldStyle(CustomTextFieldStyleEdit())
                            }
                            
                            // Odometer
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Current Odometer (km)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                TextField("", text: $viewModel.odometer, prompt: Text("e.g., 50000").foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4)))
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(CustomTextFieldStyleEdit())
                            }
                        }
                    }
                    
                    // MARK: - Save Button
                    Button(action: {
                        viewModel.updateVehicle()
                        
                        // Notify dashboard to refresh
                        NotificationCenter.default.post(
                            name: NSNotification.Name("VehicleUpdated"),
                            object: nil
                        )
                        
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
                .padding(.bottom, 100)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .tint(.blue)
        .preferredColorScheme(.dark)
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
            .foregroundColor(.black)
    }
}
