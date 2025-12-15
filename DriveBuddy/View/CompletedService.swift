//
//  CompleteServiceView.swift - WITH IMPROVED SAVE AND NOTIFICATION
//  DriveBuddy
//

import SwiftUI
import CoreData

struct CompleteServiceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @ObservedObject var service: ServiceHistory
    @State private var actualOdometer: String = ""
    @State private var completionDate: Date = Date()
    @State private var notes: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    // ✅ Auto-create next service options
    @State private var autoCreateNext: Bool = true
    @State private var nextServiceInterval: Int = 5000 // Default 5000 km
    @State private var nextServiceMonths: Int = 6 // Default 6 months
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Header
                    Text("Complete Service")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
                    
                    // Service Info Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "wrench.and.screwdriver.fill")
                                .foregroundColor(.cyan)
                                .font(.title3)
                            Text(service.service_name ?? "Unknown Service")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.2))
                        
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .foregroundColor(.gray)
                                .font(.subheadline)
                            Text("Scheduled: \(formatDate(service.service_date))")
                                .foregroundColor(.gray)
                                .font(.subheadline)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.blue.opacity(0.15))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
                    )
                    
                    // Input Section
                    SectionBoxService(title: "Service Details", icon: "doc.text.fill") {
                        VStack(alignment: .leading, spacing: 15) {
                            
                            // Completion Date
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Completion Date")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                
                                DatePicker("", selection: $completionDate, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(10)
                            }
                            
                            // Actual Odometer
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Actual Odometer (km)")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                
                                TextField("Enter odometer reading", text: $actualOdometer)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(CustomTextFieldStyleService())
                            }
                            
                            // Notes (Optional)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Notes (Optional)")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                
                                TextEditor(text: $notes)
                                    .frame(height: 100)
                                    .padding(8)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                            }
                        }
                    }
                    
                    // ✅ Auto-create Next Service Section
                    SectionBoxService(title: "Next Service", icon: "arrow.clockwise.circle.fill") {
                        VStack(alignment: .leading, spacing: 15) {
                            
                            // Toggle for auto-create
                            Toggle(isOn: $autoCreateNext) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Auto-create next service")
                                        .foregroundColor(.white)
                                        .font(.headline)
                                    Text("Automatically schedule the next service")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                }
                            }
                            .tint(.cyan)
                            
                            if autoCreateNext {
                                Divider()
                                    .background(Color.white.opacity(0.2))
                                
                                // Interval in Months
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Or every (months)")
                                        .foregroundColor(.white)
                                        .font(.headline)
                                    
                                    HStack(spacing: 12) {
                                        ForEach([3, 6, 12], id: \.self) { months in
                                            Button(action: {
                                                nextServiceMonths = months
                                            }) {
                                                Text("\(months)m")
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(nextServiceMonths == months ? .white : .gray)
                                                    .padding(.vertical, 8)
                                                    .padding(.horizontal, 16)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .fill(nextServiceMonths == months ? Color.cyan : Color.white.opacity(0.1))
                                                    )
                                            }
                                        }
                                    }
                                }
                                
                                // Preview of next service
                                HStack(spacing: 8) {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(.cyan)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Next service will be scheduled:")
                                            .foregroundColor(.gray)
                                            .font(.caption)
                                        if let odometerValue = Double(actualOdometer) {
                                            Text("• \(Int(odometerValue + Double(nextServiceInterval))) km")
                                                .foregroundColor(.white)
                                                .font(.caption)
                                        }
                                        if let nextDate = Calendar.current.date(byAdding: .month, value: nextServiceMonths, to: completionDate) {
                                            Text("• \(formatDate(nextDate))")
                                                .foregroundColor(.white)
                                                .font(.caption)
                                        }
                                    }
                                }
                                .padding(12)
                                .background(Color.cyan.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                    
                    // Mark as Done Button
                    Button(action: markAsDone) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                            Text("Mark as Done")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green)
                        )
                        .shadow(color: .green.opacity(0.5), radius: 10)
                    }
                    
                    // Error Message
                    if showError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.subheadline)
                        }
                        .padding()
                        .background(Color.red.opacity(0.2))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // ✅ Pre-fill odometer with vehicle's current odometer if available
            if let vehicle = service.vehicle, vehicle.last_odometer > 0 {
                actualOdometer = String(Int(vehicle.last_odometer))
            }
        }
    }
    
    // MARK: - Functions
    private func markAsDone() {
        showError = false
        errorMessage = ""
        
        // Validation
        guard !actualOdometer.isEmpty,
              let odometerValue = Double(actualOdometer),
              odometerValue > 0 else {
            showError = true
            errorMessage = "Please enter a valid odometer reading"
            return
        }
        
        print("\n🔄 Marking service as done:")
        print("   Service: \(service.service_name ?? "Unknown")")
        print("   Before - Date: \(service.service_date?.description ?? "nil")")
        print("   After - Date: \(completionDate.description)")
        print("   Odometer: \(Int(odometerValue)) km")
        
        // ✅ Update the service date to completion date (move to past)
        service.service_date = completionDate
        service.odometer = odometerValue
        service.created_at = Date()
        
        // ✅ Update vehicle's last service info and odometer
        if let vehicle = service.vehicle {
            vehicle.last_service_date = completionDate
            vehicle.last_odometer = odometerValue
            vehicle.odometer = odometerValue // ✅ This is the key update!
            vehicle.service_name = service.service_name
            
            print("✅ Updated vehicle: \(vehicle.make_model ?? "Unknown")")
            print("   New odometer: \(Int(odometerValue)) km")
            
            // ✅ Auto-create next service
            if autoCreateNext {
                createNextService(for: vehicle, currentOdometer: odometerValue)
            }
        }
        
        // ✅ Save with proper context management
        do {
            try viewContext.save()
            
            // ✅ Force context to process changes immediately
            viewContext.processPendingChanges()
            viewContext.refreshAllObjects()
            
            print("✅ Service marked as done successfully")
            print("   Saved to Core Data")
            
            // ✅ Post notification to refresh all views
            NotificationCenter.default.post(
                name: NSNotification.Name.NSManagedObjectContextDidSave,
                object: viewContext
            )
            
            // ✅ Dismiss after a short delay to ensure save completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                dismiss()
            }
            
        } catch {
            showError = true
            errorMessage = "Failed to save: \(error.localizedDescription)"
            print("❌ Failed to mark service as done: \(error)")
        }
    }
    
    // ✅ Create next service automatically
    private func createNextService(for vehicle: Vehicles, currentOdometer: Double) {
        let nextService = ServiceHistory(context: viewContext)
        nextService.history_id = UUID()
        nextService.service_name = service.service_name
        nextService.vehicle = vehicle
        
        // Calculate next odometer
        let nextOdometer = currentOdometer + Double(nextServiceInterval)
        nextService.odometer = nextOdometer
        
        // Calculate next date
        if let nextDate = Calendar.current.date(byAdding: .month, value: nextServiceMonths, to: completionDate) {
            nextService.service_date = nextDate
        } else {
            nextService.service_date = Calendar.current.date(byAdding: .day, value: 180, to: completionDate)
        }
        
        nextService.created_at = Date()
        
        print("✅ Auto-created next service:")
        print("   Service: \(nextService.service_name ?? "Unknown")")
        print("   Date: \(nextService.service_date?.description ?? "nil")")
        print("   Target Odometer: \(Int(nextOdometer)) km")
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Preview
#Preview {
    let context = PersistenceController.preview.container.viewContext
    
    let vehicle = Vehicles(context: context)
    vehicle.make_model = "Honda Civic"
    vehicle.last_odometer = 45000
    
    let service = ServiceHistory(context: context)
    service.service_name = "Tune-Up"
    service.service_date = Calendar.current.date(byAdding: .day, value: 30, to: Date())
    service.odometer = 0
    service.vehicle = vehicle
    
    return NavigationView {
        CompleteServiceView(service: service)
            .environment(\.managedObjectContext, context)
    }
}
