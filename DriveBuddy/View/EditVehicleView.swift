//
//  EditVehicleView.swift
//  DriveBuddy
//

import SwiftUI
import CoreData

struct EditVehicleView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: VehicleDetailViewModel
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    // Back Button
                    Button(action: {dismiss()}) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 5)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                    
                    // Title
                    Text("Edit Vehicle")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding()
                    
                    Spacer()
                }
                
                Divider()
                    .background(Color.cyan.opacity(0.3))
                
                // MARK: - Scrollable Content
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // MARK: - Vehicle Info Section
                        VStack(alignment: .leading, spacing: 12) {
                            
                            Group {
                                // Make & Model
                                Text("Make & Model")
                                    .foregroundColor(.white)
                                    .font(.system(size: 15, weight: .medium))
                                TextField("Honda Brio", text: $viewModel.makeModel)
                                    .textFieldStyle(CustomTextFieldStyle())
                                
                                // Plate Number
                                Text("Plate Number")
                                    .foregroundColor(.white)
                                    .font(.system(size: 15, weight: .medium))
                                TextField("L 567 GX", text: $viewModel.plateNumber)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .textInputAutocapitalization(.characters)
                                
                                // Odometer
                                Text("Odometer (km)")
                                    .foregroundColor(.white)
                                    .font(.system(size: 15, weight: .medium))
                                TextField("45000", text: $viewModel.odometer)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .keyboardType(.numberPad)
                            }
                            
//                            // Tax Date
//                            Text("Tax Due Date")
//                                .foregroundColor(.white)
//                                .font(.system(size: 15, weight: .medium))
//                            HStack {
//                                DatePicker("", selection: $viewModel.taxDueDate, displayedComponents: .date)
//                                    .labelsHidden()
//                                    .datePickerStyle(.compact)
//                                    .frame(maxWidth: .infinity, alignment: .leading)
//                            }
//                            .padding()
//                            .background(Color.white)
//                            .cornerRadius(10)
                            
//                            // STNK
//                            Text("STNK Due Date")
//                                .foregroundColor(.white)
//                                .font(.system(size: 15, weight: .medium))
//                            HStack {
//                                DatePicker("", selection: $viewModel.stnkDueDate, displayedComponents: .date)
//                                    .labelsHidden()
//                                    .datePickerStyle(.compact)
//                                    .frame(maxWidth: .infinity, alignment: .leading)
//                            }
//                            .padding()
//                            .background(Color.white)
//                            .cornerRadius(10)
                            
                            // Last Service Name
                            Text("Last Service Name")
                                .foregroundColor(.white)
                                .font(.system(size: 15, weight: .medium))
                            TextField("Tune-Up", text: $viewModel.serviceName)
                                .textFieldStyle(CustomTextFieldStyle())
                            
                            // Last Service Date
                            Text("Last Service Date")
                                .foregroundColor(.white)
                                .font(.system(size: 15, weight: .medium))
                            HStack {
                                DatePicker("", selection: $viewModel.lastServiceDate, displayedComponents: .date)
                                    .labelsHidden()
                                    .datePickerStyle(.compact)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            
                            // Last Odometer
                            Text("Last Odometer (km)")
                                .foregroundColor(.white)
                                .font(.system(size: 15, weight: .medium))
                            TextField("42000", text: $viewModel.lastOdometer)
                                .textFieldStyle(CustomTextFieldStyle())
                                .keyboardType(.numberPad)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                        )
                        
                        // MARK: - Save Button
                        Button {
                            viewModel.updateVehicle()
                            viewModel.addServiceHistoryEntry()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                dismiss()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                                Text("Save Changes")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.cyan.opacity(0.8))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.cyan, lineWidth: 2)
                            )
                            .shadow(color: .cyan.opacity(0.5), radius: 10)
                        }
                        .padding(.top, 10)
                        
                        // MARK: - Cancel Button (Optional)
                        Button {
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "xmark.circle")
                                    .font(.system(size: 18))
                                Text("Cancel")
                                    .font(.headline)
                            }
                            .foregroundColor(.gray)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 2)
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true) // Hide default navigation bar
    }
    
    struct CustomTextFieldStyle: TextFieldStyle {
        func _body(configuration: TextField<Self._Label>) -> some View {
            configuration
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .foregroundColor(.black)
        }
    }
}

// MARK: - Preview
#Preview {
    PreviewWrapper()
}
struct PreviewWrapper: View {
    let context = PersistenceController.shared.container.viewContext
    
    var body: some View {
        let mockUser = User(context: context)
        mockUser.user_id = UUID()
        mockUser.email = "preview@drivebuddy.com"
        
        let mockVehicle = Vehicles(context: context)
        mockVehicle.vehicles_id = UUID()
        mockVehicle.make_model = "Toyota Fortuner"
        mockVehicle.vehicle_type = "Car"
        mockVehicle.plate_number = "L 1990 ZZH"
        mockVehicle.tax_due_date = Calendar.current.date(byAdding: .day, value: 10, to: Date())
        mockVehicle.stnk_due_date = Calendar.current.date(byAdding: .month, value: 2, to: Date())
        mockVehicle.last_service_date = Calendar.current.date(byAdding: .month, value: -3, to: Date())
        mockVehicle.odometer = 324422
        mockVehicle.user = mockUser
        
        let mockVM = VehicleDetailViewModel(
            context: context,
            vehicle: mockVehicle,
            activeUser: mockUser
        )
        
        return EditVehicleView(viewModel: mockVM)
    }
}
