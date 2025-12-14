//
//  TaxDetailView.swift
//  DriveBuddy
//

import SwiftUI
import CoreData

struct TaxDetailView: View {
    let tax: TaxModel
    @StateObject private var taxManager = TaxHistoryVM.shared
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    @State private var showDeleteAlert = false
    @State private var showPayTaxSheet = false
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header Card with Status
                    VStack(spacing: 16) {
                        // Vehicle Icon
                        ZStack {
                            Circle()
                                .fill(statusColor.opacity(0.2))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "car.fill")
                                .font(.system(size: 44))
                                .foregroundColor(statusColor)
                        }
                        
                        // Plate Number
                        Text(tax.vehiclePlate)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(tax.vehicleName)
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                        
                        // Status Badge Large
                        HStack(spacing: 12) {
                            StatusBadge(status: tax.status)
                            
                            if tax.status == .expiringSoon {
                                Text("\(tax.daysUntilExpiry) days left")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.orange)
                            } else if tax.status == .expired {
                                Text("Expired \(abs(tax.daysUntilExpiry)) days ago")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.top, 20)
                    
                    // Tax Amount Card
                    VStack(spacing: 12) {
                        Text("Tax Amount")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        Text(tax.formattedAmount)
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.cyan)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.cyan.opacity(0.1))
                    )
                    
                    // Details Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Details")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        DetailRow(
                            icon: "calendar.badge.clock",
                            title: "Payment Date",
                            value: tax.paymentDate.formatted(date: .long, time: .omitted)
                        )
                        
                        Divider()
                            .background(Color.white.opacity(0.1))
                        
                        DetailRow(
                            icon: "calendar.badge.checkmark",
                            title: "Valid Until",
                            value: tax.validUntil.formatted(date: .long, time: .omitted),
                            valueColor: statusColor
                        )
                        
                        Divider()
                            .background(Color.white.opacity(0.1))
                        
                        DetailRow(
                            icon: "mappin.circle.fill",
                            title: "Payment Location",
                            value: tax.location
                        )
                        
                        if !tax.notes.isEmpty {
                            Divider()
                                .background(Color.white.opacity(0.1))
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    Image(systemName: "note.text")
                                        .foregroundColor(.cyan)
                                    Text("Notes")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.gray)
                                }
                                
                                Text(tax.notes)
                                    .font(.system(size: 15))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(white: 0.15))
                    )
                    
                    // Reminder Info
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "bell.badge.fill")
                                .foregroundColor(.cyan)
                            Text("Reminder Schedule")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        
                        VStack(spacing: 8) {
                            ReminderItem(days: 30, date: Calendar.current.date(byAdding: .day, value: -30, to: tax.validUntil)!)
                            ReminderItem(days: 7, date: Calendar.current.date(byAdding: .day, value: -7, to: tax.validUntil)!)
                            ReminderItem(days: 1, date: Calendar.current.date(byAdding: .day, value: -1, to: tax.validUntil)!)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(white: 0.15))
                    )
                    
                    // Pay Tax Button (for expired/expiring taxes)
                    if tax.status == .expired || tax.status == .expiringSoon {
                        Button(action: {
                            showPayTaxSheet = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "creditcard.fill")
                                    .font(.system(size: 16))
                                Text("Pay Tax")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.green.opacity(0.8))
                            )
                        }
                    }
                    
                    // Delete Button
                    Button(action: {
                        showDeleteAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Delete Record")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red.opacity(0.8))
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .alert("Delete Tax Record", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                taxManager.deleteTaxHistory(tax, context: viewContext)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this tax record? This action cannot be undone.")
        }
        .sheet(isPresented: $showPayTaxSheet) {
            NavigationView {
                PayTaxView(
                    existingTax: tax,
                    vehicle: Vehicle(
                        id: UUID(),
                        makeAndModel: tax.vehicleName,
                        vehicleType: "Car",
                        licensePlate: tax.vehiclePlate,
                        year: "",
                        odometer: "0",
                        taxDate: Date()
                    )
                )
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { showPayTaxSheet = false }) {
                            Image(systemName: "chevron.left")
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
    }
    
    var statusColor: Color {
        switch tax.status {
        case .valid: return .green
        case .expiringSoon: return .orange
        case .expired: return .red
        }
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    var valueColor: Color = .white
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.cyan)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray)
                Text(value)
                    .font(.system(size: 15))
                    .foregroundColor(valueColor)
            }
            
            Spacer()
        }
    }
}

// MARK: - Reminder Item
struct ReminderItem: View {
    let days: Int
    let date: Date
    
    var isPast: Bool {
        date < Date()
    }
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: isPast ? "checkmark.circle.fill" : "bell.fill")
                    .font(.system(size: 14))
                    .foregroundColor(isPast ? .green : .cyan)
                
                Text("\(days) days before")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Text(date.formatted(date: .abbreviated, time: .omitted))
                .font(.system(size: 13))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black)
        )
    }
}

// MARK: - Pay Tax View
struct PayTaxView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var taxManager = TaxHistoryVM.shared
    
    let existingTax: TaxModel
    let vehicle: Vehicle
    
    @State private var taxAmount = ""
    @State private var paymentDate = Date()
    @State private var validUntil: Date
    @State private var location = ""
    @State private var notes = ""
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    init(existingTax: TaxModel, vehicle: Vehicle) {
        self.existingTax = existingTax
        self.vehicle = vehicle
        
        _validUntil = State(initialValue: Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date())
        _taxAmount = State(initialValue: String(format: "%.0f", existingTax.taxAmount))
        _location = State(initialValue: existingTax.location)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    HStack {
                        Button(action: { dismiss() }) {
                            ZStack {
                                Circle()
                                    .fill(Color(white: 0.2))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.blue)
                            }
                        }
                        Spacer()
                    }
                    .padding(.bottom, 8)
                    
                    Text("Renew Tax Payment")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "car.fill")
                                .foregroundColor(.cyan)
                            Text("Vehicle Info")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(existingTax.vehiclePlate)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            Text(existingTax.vehicleName)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.15))
                    .cornerRadius(15)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.cyan)
                            Text("Tax Information")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 15) {
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
                            }
                            
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
                            }
                        }
                        .padding()
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(15)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "note.text")
                                .foregroundColor(.cyan)
                            Text("Notes (Optional)")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        
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
                    
                    Button(action: savePayment) {
                        Text("Save Payment")
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
    
    var isFormValid: Bool {
        !taxAmount.isEmpty &&
        Double(taxAmount) != nil &&
        !location.isEmpty &&
        validUntil > paymentDate
    }
    
    func savePayment() {
        guard let amount = Double(taxAmount) else { return }
        
        let newTax = TaxModel(
            vehiclePlate: existingTax.vehiclePlate,
            vehicleName: existingTax.vehicleName,
            taxAmount: amount,
            paymentDate: paymentDate,
            validUntil: validUntil,
            location: location,
            notes: notes
        )
        
        taxManager.addTaxHistory(newTax, context: viewContext)
        
        alertMessage = "Tax payment saved successfully!"
        showAlert = true
    }
}

#Preview {
    NavigationStack {
        TaxDetailView(tax: TaxModel.sampleData[0])
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
    .preferredColorScheme(.dark)
}
