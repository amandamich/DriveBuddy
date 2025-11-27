//
//  AddTaxView.swift
//  DriveBuddy
//
//  Created by Timothy on 26/11/25.
//

import SwiftUI

struct AddTaxView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var taxManager = TaxHistoryVM.shared
    @StateObject private var vehicleManager = VehicleManagerVM.shared
    
    @State private var selectedVehicle: Vehicle?
    @State private var showVehicleDropdown = false
    @State private var taxAmount = ""
    @State private var paymentDate = Date()
    @State private var validUntil = Calendar.current.date(byAdding: .year, value: 2, to: Date()) ?? Date()
    @State private var location = ""
    @State private var notes = ""
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showNoVehicleAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Navigation Bar with Back Button
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.cyan)
                                .frame(width: 44, height: 44)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        Text("Add Tax Record")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                        
                        // Header Icon
                        ZStack {
                            Circle()
                                .fill(Color.cyan.opacity(0.2))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.cyan)
                        }
                        .padding(.bottom, 20)
                        
                        VStack(alignment: .leading, spacing: 20) {
                            // Vehicle Selection Dropdown
                            VStack(alignment: .leading, spacing: 8) {
                                Label {
                                    Text("Select Vehicle")
                                        .foregroundColor(.white)
                                } icon: {
                                    Image(systemName: "car.fill")
                                        .foregroundColor(.cyan)
                                }
                                
                                if vehicleManager.vehicles.isEmpty {
                                    // No vehicles available
                                    Button(action: {
                                        showNoVehicleAlert = true
                                    }) {
                                        HStack {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .foregroundColor(.orange)
                                            Text("No vehicles registered")
                                                .foregroundColor(.gray)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.gray)
                                        }
                                        .padding()
                                        .background(Color(white: 0.15))
                                        .cornerRadius(12)
                                    }
                                } else {
                                    // Vehicle dropdown
                                    Menu {
                                        ForEach(vehicleManager.vehicles) { vehicle in
                                            Button(action: {
                                                selectedVehicle = vehicle
                                            }) {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(vehicle.licensePlate)
                                                        .font(.system(size: 16, weight: .semibold))
                                                    Text(vehicle.makeAndModel)
                                                        .font(.system(size: 14))
                                                        .foregroundColor(.gray)
                                                }
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            if let vehicle = selectedVehicle {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(vehicle.licensePlate)
                                                        .font(.system(size: 16, weight: .semibold))
                                                        .foregroundColor(.white)
                                                    Text(vehicle.makeAndModel)
                                                        .font(.system(size: 14))
                                                        .foregroundColor(.gray)
                                                }
                                            } else {
                                                Text("Select a vehicle")
                                                    .foregroundColor(.gray)
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.down")
                                                .foregroundColor(.cyan)
                                        }
                                        .padding()
                                        .background(Color(white: 0.15))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                            
                            // Display selected vehicle details
                            if let vehicle = selectedVehicle {
                                HStack(spacing: 12) {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(.cyan)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Vehicle Details")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text("\(vehicle.vehicleType) • \(vehicle.year)")
                                            .font(.system(size: 13))
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.cyan.opacity(0.1))
                                )
                            }
                            
                            // Tax Amount
                            VStack(alignment: .leading, spacing: 8) {
                                Label {
                                    Text("Tax Amount")
                                        .foregroundColor(.white)
                                } icon: {
                                    Image(systemName: "banknote.fill")
                                        .foregroundColor(.cyan)
                                }
                                
                                HStack {
                                    Text("Rp")
                                        .foregroundColor(.gray)
                                    TextField("0", text: $taxAmount)
                                        .keyboardType(.numberPad)
                                        .foregroundColor(.white)
                                }
                                .padding()
                                .background(Color(white: 0.15))
                                .cornerRadius(12)
                            }
                            
                            // Payment Date
                            VStack(alignment: .leading, spacing: 8) {
                                Label {
                                    Text("Payment Date")
                                        .foregroundColor(.white)
                                } icon: {
                                    Image(systemName: "calendar.badge.clock")
                                        .foregroundColor(.cyan)
                                }
                                
                                DatePicker("", selection: $paymentDate, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .tint(.cyan)
                                    .padding()
                                    .background(Color(white: 0.15))
                                    .cornerRadius(12)
                                    .colorScheme(.dark)
                            }
                            
                            // Valid Until
                            VStack(alignment: .leading, spacing: 8) {
                                Label {
                                    Text("Valid Until")
                                        .foregroundColor(.white)
                                } icon: {
                                    Image(systemName: "calendar.badge.checkmark")
                                        .foregroundColor(.cyan)
                                }
                                
                                DatePicker("", selection: $validUntil, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .tint(.cyan)
                                    .padding()
                                    .background(Color(white: 0.15))
                                    .cornerRadius(12)
                                    .colorScheme(.dark)
                            }
                            
                            // Location
                            FormField(
                                title: "Payment Location",
                                icon: "mappin.circle.fill",
                                placeholder: "e.g., Samsat Jakarta Timur",
                                text: $location
                            )
                            
                            // Notes
                            VStack(alignment: .leading, spacing: 8) {
                                Label {
                                    Text("Notes (Optional)")
                                        .foregroundColor(.white)
                                } icon: {
                                    Image(systemName: "note.text")
                                        .foregroundColor(.cyan)
                                }
                                
                                TextEditor(text: $notes)
                                    .frame(height: 100)
                                    .padding(8)
                                    .background(Color(white: 0.15))
                                    .cornerRadius(12)
                                    .foregroundColor(.white)
                                    .scrollContentBackground(.hidden)
                            }
                        }
                        
                        // Reminder Info Card
                        HStack(spacing: 12) {
                            Image(systemName: "bell.badge.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.cyan)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Auto Reminder")
                                    .foregroundColor(.white)
                                Text("You'll be notified 30, 7, and 1 day before expiry")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.cyan.opacity(0.1))
                        )
                        
                        // Save Button
                        Button(action: saveTaxHistory) {
                            Text("Save Tax Record")
                                .font(.headline)
                                .foregroundColor(isFormValid ? .white : .gray)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isFormValid ? Color.cyan : Color.gray.opacity(0.5), lineWidth: 2)
                                        .shadow(color: isFormValid ? .blue : .clear, radius: 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.black.opacity(0.5))
                                        )
                                )
                                .shadow(color: isFormValid ? .blue : .clear, radius: 10)
                        }
                        .disabled(!isFormValid)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .padding(.top, 60) // Add padding for custom nav bar
                }
            }
            .preferredColorScheme(.dark)
            .navigationBarHidden(true) // Hide default navigation bar
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                vehicleManager.refresh() // Refresh vehicles when view appears
            }
            .alert("Success", isPresented: $showAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text(alertMessage)
            }
            .alert("No Vehicles Registered", isPresented: $showNoVehicleAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please register a vehicle first before adding a tax record.")
            }
        }
    }
    
    var isFormValid: Bool {
        selectedVehicle != nil &&
        !taxAmount.isEmpty &&
        Double(taxAmount) != nil &&
        !location.isEmpty &&
        validUntil > paymentDate
    }
    
    func saveTaxHistory() {
        guard let vehicle = selectedVehicle,
              let amount = Double(taxAmount) else { return }
        
        let newTax = TaxModel(
            vehiclePlate: vehicle.licensePlate,
            vehicleName: vehicle.makeAndModel,
            taxAmount: amount,
            paymentDate: paymentDate,
            validUntil: validUntil,
            location: location,
            notes: notes
        )
        
        // Add to database through TaxHistoryManager
        taxManager.addTaxHistory(newTax)
        
        alertMessage = "Tax record saved successfully! Reminders have been set."
        showAlert = true
    }
}

// MARK: - Form Field Component
struct FormField: View {
    let title: String
    let icon: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text(title)
                    .foregroundColor(.white)
            } icon: {
                Image(systemName: icon)
                    .foregroundColor(.cyan)
            }
            
            TextField(placeholder, text: $text)
                .padding()
                .background(Color(white: 0.15))
                .cornerRadius(12)
                .foregroundColor(.white)
                .autocorrectionDisabled(true)
        }
    }
}
