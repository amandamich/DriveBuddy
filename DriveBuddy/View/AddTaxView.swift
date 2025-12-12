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
    
    let vehicle: Vehicle // Pass the current vehicle directly
    
    @State private var taxAmount = ""
    @State private var paymentDate = Date()
    @State private var validUntil = Calendar.current.date(byAdding: .year, value: 2, to: Date()) ?? Date()
    @State private var location = ""
    @State private var notes = ""
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
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
                            // Header
                            Text("Add Tax Record")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Vehicle Info Section (Blue)
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 6) {
                                    Image(systemName: "car.fill")
                                        .foregroundColor(.cyan)
                                    Text("Vehicle Info")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 15) {
                                    // Display current vehicle (non-editable)
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Vehicle")
                                            .foregroundColor(.white)
                                            .font(.headline)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(vehicle.licensePlate)
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundColor(.white)
                                            Text(vehicle.makeAndModel)
                                                .font(.system(size: 14))
                                                .foregroundColor(.gray)
                                            Text("\(vehicle.vehicleType) • \(vehicle.year)")
                                                .font(.system(size: 13))
                                                .foregroundColor(.gray)
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.white.opacity(0.1))
                                        .cornerRadius(10)
                                    }
                                }
                                .padding()
                                .background(Color.blue.opacity(0.15))
                                .cornerRadius(15)
                            }
                            
                            // Tax Information Section (Blue)
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 6) {
                                    Image(systemName: "doc.text.fill")
                                        .foregroundColor(.cyan)
                                    Text("Tax Information")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 15) {
                                    // Tax Amount
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Tax Amount")
                                            .foregroundColor(.white)
                                            .font(.headline)
                                        
                                        HStack {
                                            Text("Rp")
                                                .foregroundColor(.gray)
                                            TextField("0", text: $taxAmount)
                                                .keyboardType(.numberPad)
                                                .foregroundColor(.black)
                                        }
                                        .padding()
                                        .background(Color.white)
                                        .cornerRadius(10)
                                    }
                                    
                                    // Payment Date
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Payment Date")
                                            .foregroundColor(.white)
                                            .font(.headline)
                                        
                                        DatePicker("", selection: $paymentDate, displayedComponents: .date)
                                            .labelsHidden()
                                            .datePickerStyle(.compact)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding()
                                            .background(Color.white)
                                            .cornerRadius(10)
                                    }
                                    
                                    // Valid Until
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Valid Until")
                                            .foregroundColor(.white)
                                            .font(.headline)
                                        
                                        DatePicker("", selection: $validUntil, displayedComponents: .date)
                                            .labelsHidden()
                                            .datePickerStyle(.compact)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding()
                                            .background(Color.white)
                                            .cornerRadius(10)
                                    }
                                    
                                    // Payment Location
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Payment Location")
                                            .foregroundColor(.white)
                                            .font(.headline)
                                        
                                        TextField("e.g., Samsat Jakarta Timur", text: $location)
                                            .padding()
                                            .background(Color.white)
                                            .cornerRadius(10)
                                            .autocorrectionDisabled(true)
                                    }
                                }
                                .padding()
                                .background(Color.blue.opacity(0.15))
                                .cornerRadius(15)
                            }
                            
                            // Notes Section (Blue)
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 6) {
                                    Image(systemName: "note.text")
                                        .foregroundColor(.cyan)
                                    Text("Notes (Optional)")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 15) {
                                    TextEditor(text: $notes)
                                        .frame(height: 100)
                                        .padding(8)
                                        .background(Color.white)
                                        .cornerRadius(10)
                                        .scrollContentBackground(.hidden)
                                }
                                .padding()
                                .background(Color.blue.opacity(0.15))
                                .cornerRadius(15)
                            }
                            
                            // Reminder Info (Blue)
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 6) {
                                    Image(systemName: "bell.badge.fill")
                                        .foregroundColor(.cyan)
                                    Text("Reminder Settings")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("You'll be notified:")
                                        .foregroundColor(.white)
                                        .font(.subheadline)
                                    Text("• 30 days before expiry")
                                        .foregroundColor(.gray)
                                        .font(.subheadline)
                                    Text("• 7 days before expiry")
                                        .foregroundColor(.gray)
                                        .font(.subheadline)
                                    Text("• 1 day before expiry")
                                        .foregroundColor(.gray)
                                        .font(.subheadline)
                                }
                                .padding()
                                .background(Color.blue.opacity(0.15))
                                .cornerRadius(15)
                            }
                            
                            // Add Button (Blue styled like AddServiceView)
                            Button(action: saveTaxHistory) {
                                Text("Add Tax Record")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(isFormValid ? Color.cyan : Color.gray, lineWidth: 2)
                                            .shadow(color: isFormValid ? .blue : .clear, radius: 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color.black.opacity(0.5))
                                            )
                                    )
                                    .shadow(color: isFormValid ? .blue : .clear, radius: 10)
                            }
                            .disabled(!isFormValid)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                    .padding(.top, 60)
                }
            }
            .preferredColorScheme(.dark)
            .navigationBarHidden(true)
            .alert("Success", isPresented: $showAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    var isFormValid: Bool {
        !taxAmount.isEmpty &&
        Double(taxAmount) != nil &&
        !location.isEmpty &&
        validUntil > paymentDate
    }
    
    func saveTaxHistory() {
        guard let amount = Double(taxAmount) else { return }
        
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
