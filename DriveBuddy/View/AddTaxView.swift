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
    @State private var validUntil = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var location = ""
    @State private var notes = ""
    
    // ✅ NEW: History tracking
    @State private var isHistoryRecord = false
    @State private var actualPaymentDate = Date()
    
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
                    
                    // ✅ NEW: History Checkbox Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(.cyan)
                            Text("Record Type")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 15) {
                            Toggle(isOn: $isHistoryRecord) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Add Payment Date (History)")
                                        .foregroundColor(.white)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text("Enable this to add a past tax payment record")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                }
                            }
                            .tint(.cyan)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                            
                            // ✅ Show actual payment date picker if history is enabled
                            if isHistoryRecord {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Actual Payment Date")
                                        .foregroundColor(.white)
                                        .font(.headline)
                                    
                                    Text("Select when you actually paid this tax")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                    
                                    DatePicker(
                                        "",
                                        selection: $actualPaymentDate,
                                        in: ...Date(),  // ✅ Only allow past dates and today
                                        displayedComponents: .date
                                    )
                                    .labelsHidden()
                                    .datePickerStyle(.compact)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .colorScheme(.light)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(10)
                                }
                                .padding()
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                )
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
                                        .fontWeight(.medium)
                                    TextField("", text: $taxAmount, prompt: Text("Enter amount (e.g., 500000)").foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4)))
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
                            
                            // Payment Due Date (when tax was due)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Tax Due Date")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                
                                Text("When the tax was originally due")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                                
                                ZStack {
                                    DatePicker("", selection: $paymentDate, displayedComponents: .date)
                                        .labelsHidden()
                                        .datePickerStyle(.compact)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .colorScheme(.light)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                            }
                            
                            // Valid Until
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Valid Until")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                
                                Text("When this tax expires")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                                
                                ZStack {
                                    DatePicker("", selection: $validUntil, displayedComponents: .date)
                                        .labelsHidden()
                                        .datePickerStyle(.compact)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .colorScheme(.light)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                
                                if validUntil <= paymentDate {
                                    HStack(spacing: 4) {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .foregroundColor(.red)
                                            .font(.system(size: 12))
                                        Text("Valid until must be after due date")
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
                                
                                TextField("", text: $location, prompt: Text("e.g., Samsat Jakarta Timur").foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4)))
                                    .padding()
                                    .foregroundColor(.black)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .autocorrectionDisabled(true)
                                
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
                            ZStack(alignment: .topLeading) {
                                if notes.isEmpty {
                                    Text("Add any additional notes here...")
                                        .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 16)
                                }
                                TextEditor(text: $notes)
                                    .frame(height: 100)
                                    .padding(8)
                                    .scrollContentBackground(.hidden)
                                    .foregroundColor(.black)
                            }
                            .background(Color.white)
                            .cornerRadius(10)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(15)
                    }
                    
                    // Reminder Info
                    if !isHistoryRecord {
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
                    }
                    
                    // Add Button
                    Button(action: saveTaxHistory) {
                        Text(isHistoryRecord ? "Add History Record" : "Add Tax Record")
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
            notes: notes,
            receiptImagePath: nil,
            isPaid: isHistoryRecord,
            actualPaymentDate: isHistoryRecord ? actualPaymentDate : nil,
            isHistoryRecord: isHistoryRecord
        )
        
        // ✅ Add with context to trigger sync
        taxManager.addTaxHistory(newTax, context: viewContext)
        
        // ✅ Force save Core Data
        do {
            try viewContext.save()
            print("✅ Core Data saved after adding tax")
        } catch {
            print("❌ Failed to save Core Data: \(error)")
        }
        
        // Calendar sync if needed
        if let profileVM = try? viewContext.fetch(User.fetchRequest()).first,
           profileVM.add_to_calendar {
            Task {
                let profileVM = ProfileViewModel(context: viewContext, user: profileVM)
                await profileVM.syncAllVehiclesToCalendar()
            }
        }
        
        alertMessage = isHistoryRecord
        ? "Tax history record saved successfully!"
        : "Tax record saved successfully! Reminders have been set."
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
