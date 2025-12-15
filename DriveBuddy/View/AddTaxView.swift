//
//  AddTaxView.swift
//  DriveBuddy
//

import SwiftUI
import CoreData

struct AddTaxView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var taxManager = TaxHistoryVM.shared
    
    let vehicle: Vehicle
    
    @State private var taxAmount = ""
    @State private var paymentDate = Date()
    @State private var validUntil = Calendar.current.date(byAdding: .year, value: 2, to: Date()) ?? Date()
    @State private var location = ""
    @State private var notes = ""
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    Text("Add Tax Record")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 20)
                    
                    // Vehicle Info Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "car.fill")
                                .foregroundColor(.cyan)
                            Text("Vehicle Info")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 15) {
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
                                    
                                    // Display year and type
                                    HStack(spacing: 4) {
                                        Text(vehicle.vehicleType)
                                            .font(.system(size: 13))
                                            .foregroundColor(.gray)
                                        
                                        if !vehicle.year.isEmpty && vehicle.year != "N/A" {
                                            Text("•")
                                                .foregroundColor(.gray)
                                            Text(vehicle.year)
                                                .font(.system(size: 13))
                                                .foregroundColor(.gray)
                                        }
                                    }
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
                    
                    // Tax Information Section
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
                                        .foregroundColor(.black)
                                    TextField("0", text: $taxAmount)
                                        .keyboardType(.numberPad)
                                        .foregroundColor(.black)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                
                                if taxAmount.isEmpty {
                                    HStack(spacing: 4) {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .foregroundColor(.red)
                                            .font(.system(size: 12))
                                        Text("Tax amount is required")
                                            .foregroundColor(.red)
                                            .font(.system(size: 12))
                                    }
                                } else if Double(taxAmount) == nil {
                                    HStack(spacing: 4) {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .foregroundColor(.red)
                                            .font(.system(size: 12))
                                        Text("Please enter a valid number")
                                            .foregroundColor(.red)
                                            .font(.system(size: 12))
                                    }
                                }
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
                                
                                if validUntil <= paymentDate {
                                    HStack(spacing: 4) {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .foregroundColor(.red)
                                            .font(.system(size: 12))
                                        Text("Valid until must be after payment date")
                                            .foregroundColor(.red)
                                            .font(.system(size: 12))
                                    }
                                }
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
                                    .foregroundColor(.black)
                                
                                if location.isEmpty {
                                    HStack(spacing: 4) {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .foregroundColor(.red)
                                            .font(.system(size: 12))
                                        Text("Payment location is required")
                                            .foregroundColor(.red)
                                            .font(.system(size: 12))
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(15)
                    }
                    
                    // Notes Section
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
                                .foregroundColor(.black)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(15)
                    }
                    
                    // Reminder Info
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
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.15))
                    .cornerRadius(15)
                    
                    // Add Button
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
                    
                    // Overall validation message
                    if !isFormValid {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.orange)
                            Text("Please fill in all required fields to continue")
                                .foregroundColor(.orange)
                                .font(.system(size: 14))
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.orange.opacity(0.15))
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .preferredColorScheme(.dark)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .alert("Success", isPresented: $showAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text(alertMessage)
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
        
        taxManager.addTaxHistory(newTax, context: viewContext)
        
        alertMessage = "Tax record saved successfully! Reminders have been set."
        showAlert = true
    }
}

#Preview {
    NavigationStack {
        AddTaxView(vehicle: Vehicle(
            id: UUID(),
            makeAndModel: "Mitsubishi Pajero Sport",
            vehicleType: "SUV",
            licensePlate: "L 1111 E",
            year: "2020",
            odometer: "85000",
            taxDate: Date()
        ))
        .preferredColorScheme(.dark)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
