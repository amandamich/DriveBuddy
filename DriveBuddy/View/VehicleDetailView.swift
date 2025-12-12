//
//  VehicleDetailView.swift - ENHANCED VERSION
//  DriveBuddy
//

import SwiftUI
import CoreData

struct VehicleDetailView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject var viewModel: VehicleDetailViewModel
    let allVehicles: FetchedResults<Vehicles>
    
    @State private var showAddService = false
    @State private var showMyService = false
    @State private var showMyTax = false
    @ObservedObject var profileVM: ProfileViewModel
    
    @State private var refreshTrigger = UUID()
    @State private var upcomingServicesRefreshID = UUID()
    
    var onDismiss: (() -> Void)?

    init(initialVehicle: Vehicles,
         allVehicles: FetchedResults<Vehicles>,
         context: NSManagedObjectContext,
         activeUser: User,
         profileVM: ProfileViewModel,
         onDismiss: (() -> Void)? = nil) {

        self.allVehicles = allVehicles
        self.profileVM = profileVM
        self.onDismiss = onDismiss

        _viewModel = StateObject(wrappedValue:
            VehicleDetailViewModel(
                context: context,
                vehicle: initialVehicle,
                activeUser: activeUser
            )
        )
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // MARK: HEADER
                    HStack {
                        Image("LogoDriveBuddy")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 180, height: 40)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
//                    // Add after the LogoDriveBuddy Image
//                    VStack(spacing: 8) {
//                        Button(action: {
//                            viewModel.debugAllServices()
//                        }) {
//                            Text("🔍 Debug All Services")
//                                .font(.caption)
//                                .foregroundColor(.white)
//                                .padding(.horizontal, 12)
//                                .padding(.vertical, 6)
//                                .background(Color.red.opacity(0.8))
//                                .cornerRadius(8)
//                        }
//                        
//                        Button(action: {
//                            viewModel.deleteAllScheduledMaintenance()
//                        }) {
//                            Text("🗑️ Clean Old Services")
//                                .font(.caption)
//                                .foregroundColor(.white)
//                                .padding(.horizontal, 12)
//                                .padding(.vertical, 6)
//                                .background(Color.orange.opacity(0.8))
//                                .cornerRadius(8)
//                        }
//                    }
//                    .padding(.horizontal)
                    // MARK: VEHICLE DROPDOWN
                    Menu {
                        ForEach(allVehicles, id: \.objectID) { v in
                            Button(v.make_model ?? "Unknown") {
                                withAnimation(.easeInOut) {
                                    if v.user == viewModel.activeUser {
                                        viewModel.activeVehicle = v
                                        viewModel.loadVehicleData()
                                        refreshTrigger = UUID()
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "car.fill")
                                .foregroundColor(.cyan)
                            
                            Text(viewModel.makeModel.isEmpty ? "Nama Kosong" : viewModel.makeModel)
                                .font(.title3)
                                .bold()
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.down")
                                .foregroundColor(.cyan.opacity(0.9))
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 18)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.3),
                                    Color.blue.opacity(0.25)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
                        )
                        .cornerRadius(16)
                        .shadow(color: .cyan.opacity(0.3), radius: 7, x: 0, y: 4)
                        .padding(.horizontal)
                    }
                    
                    // MARK: VEHICLE INFO BOX
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 20) {
                            Image(viewModel.activeVehicle.vehicle_type == "Car" ? "Car" : "Motorbike")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 70)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text(viewModel.activeVehicle.make_model ?? "")
                                    .font(.title3)
                                    .bold()
                                    .foregroundColor(.white)
                                
                                Text(viewModel.plateNumber.isEmpty ? "No Plat" : viewModel.plateNumber)
                                    .foregroundColor(.gray)
                                
                                Text("\(viewModel.formattedOdometer)")
                                    .foregroundColor(.white)
                                    .font(.headline)
                            }
                            
                            Spacer()
                            
                            Button(action: { viewModel.startEditing() }) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding()
                    .background(Color(red: 17/255, green: 33/255, blue: 66/255))
                    .cornerRadius(18)
                    .shadow(color: .cyan.opacity(0.25), radius: 6, x: 0, y: 4)
                    .padding(.horizontal)
                    
                    HStack(spacing: 16) {
                        
                        // UPCOMING SERVICES - Pass viewModel instead of array
                        Button(action: { showMyService = true }) {
                            UpcomingServicesCard(viewModel: viewModel) // ✅ Changed to pass viewModel
                        }
                        .buttonStyle(CardButtonStyle())
                        .frame(maxWidth: .infinity)
                        
                        // TAX PAYMENT
                        Button(action: { showMyTax = true }) {
                            TaxPaymentCard(
                                hasTaxDate: viewModel.hasTaxDate,
                                taxDate: viewModel.taxDueDate,
                                formatDate: viewModel.formatDate
                            )
                        }
                        .buttonStyle(CardButtonStyle())
                        .frame(maxWidth: .infinity)
                    }
                    .frame(height: 140)
                    .padding(.horizontal)
                    .id(refreshTrigger)
                    
                    // MARK: LAST 3 SERVICES
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Last Service")
                                .foregroundColor(.white)
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: { showAddService = true }) {
                                Text("Add a service")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 22)
                                    .background(Color.blue)
                                    .cornerRadius(25)
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Divider().background(Color.white.opacity(0.2))
                        
                        // Show last 3 services
                        let lastServices = viewModel.getLastServices(limit: 3)
                        
                        if lastServices.isEmpty {
                            HStack {
                                Image(systemName: "wrench.and.screwdriver")
                                    .foregroundColor(.gray)
                                Text("No service history yet")
                                    .foregroundColor(.gray)
                                    .font(.subheadline)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 8)
                        } else {
                            ForEach(Array(lastServices.enumerated()), id: \.element.history_id) { index, service in
                                VStack(spacing: 0) {
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(service.service_name ?? "Unknown Service")
                                                .foregroundColor(.white)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            
                                            if service.odometer > 0 {
                                                Text("\(Int(service.odometer)) km")
                                                    .foregroundColor(.cyan.opacity(0.8))
                                                    .font(.caption)
                                            }
                                        }
                                        
                                        Spacer()
                                        Text(viewModel.formatDate(service.service_date))
                                            .foregroundColor(.white.opacity(0.7))
                                            .font(.subheadline)
                                    }
                                    .padding(.vertical, 8)
                                    
                                    if index < lastServices.count - 1 {
                                        Divider()
                                            .background(Color.white.opacity(0.1))
                                    }
                                }
                            }
                            
                            // View All button if there are more than 3 services
                            if viewModel.getTotalCompletedServices() > 3 {
                                Button(action: { showMyService = true }) {
                                    HStack {
                                        Text("View all (\(viewModel.getTotalCompletedServices()))")
                                            .font(.caption)
                                            .foregroundColor(.cyan)
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.cyan)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.top, 8)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(red: 17/255, green: 33/255, blue: 66/255))
                    .cornerRadius(18)
                    .shadow(color: .cyan.opacity(0.25), radius: 6, x: 0, y: 4)
                    .padding(.horizontal)
                    .id(refreshTrigger)
                }
                    Spacer(minLength: 60)
                }
        }
        .onAppear {
            viewModel.loadVehicleData()
        }
        .onDisappear {
            onDismiss?()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
            Task { @MainActor in
                viewModel.loadVehicleData()
                refreshTrigger = UUID()
            }
        }
        
        // MARK: - Sheets
        .sheet(isPresented: $showMyService) {
            NavigationView {
                MyServiceView(
                    vehicle: viewModel.activeVehicle,
                    context: viewContext,
                    activeUser: viewModel.activeUser
                )
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { showMyService = false }) {
                            Image(systemName: "chevron.left")
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        
        .sheet(isPresented: $showMyTax) {
            NavigationView {
                TaxHistoryView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: { showMyTax = false }) {
                                Image(systemName: "chevron.left")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
            }
        }
        // Sheet Add Service
        .sheet(isPresented: $showAddService, onDismiss: {
            print("🔄 AddService sheet dismissed - reloading data")
            viewModel.loadVehicleData()
            refreshTrigger = UUID()
            upcomingServicesRefreshID = UUID() // ✅ ADDED: Refresh upcoming card
        }) {
            NavigationView {
                AddServiceView(
                    vehicle: viewModel.activeVehicle,
                    context: viewContext,
                    profileVM: profileVM
                )
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { showAddService = false }) {
                            Image(systemName: "chevron.left")
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        
        .sheet(isPresented: $viewModel.isEditing, onDismiss: {
            viewModel.loadVehicleData()
            refreshTrigger = UUID()
        }) {
            NavigationView {
                EditVehicleView(viewModel: viewModel)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: { viewModel.isEditing = false }) {
                                Image(systemName: "chevron.left")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
            }
        }
        
        .navigationBarBackButtonHidden(false)
    }
}


// MARK: - Upcoming Services Card (FIXED with ObservableObject)
struct UpcomingServicesCard: View {
    @ObservedObject var viewModel: VehicleDetailViewModel
    
    var body: some View {
        let upcomingServices = viewModel.getUpcomingServices()
        
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Upcoming Services")
                    .lineLimit(1)
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .semibold))
            }
            
            if upcomingServices.isEmpty {
                Text("No upcoming services")
                    .foregroundColor(.white.opacity(0.6))
                    .font(.system(size: 12))
                    .padding(.vertical, 4)
                
                Spacer()
            } else {
                // Sort by date to show nearest service first
                let sortedServices = upcomingServices.sorted { $0.date < $1.date }
                
                // Show first 2 upcoming services (nearest first)
                ForEach(Array(sortedServices.prefix(2).enumerated()), id: \.offset) { index, service in
                    Text(service.name.trimmingCharacters(in: .whitespaces)) // ✅ Trim spaces
                        .lineLimit(1)
                        .foregroundColor(.white.opacity(0.85))
                        .font(.system(size: 13, weight: .regular))
                        .padding(.vertical, 2)
                }
                
                Spacer()
                
                // Show the NEAREST service date
                if let nearestService = sortedServices.first {
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 10))
                            Text(formatDateShort(nearestService.date))
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.6))
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.cyan.opacity(0.9))
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color.black.opacity(0.3),
                    Color.blue.opacity(0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
        )
        .cornerRadius(16)
    }
    
    private func formatDateShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Tax Payment Card
struct TaxPaymentCard: View {
    let hasTaxDate: Bool
    let taxDate: Date
    let formatDate: (Date?) -> String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "banknote.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Tax Payment")
                    .lineLimit(1)
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .semibold))
            }
            
            if !hasTaxDate {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                        Text("Not set")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.orange)
                    }
                    
                    Text("Tap to add tax due date")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.vertical, 4)
            } else {
                Text("Next Due")
                    .foregroundColor(.white.opacity(0.85))
                    .font(.system(size: 13, weight: .regular))
                
                Spacer()
                
                // ✅ Date and arrow on the same line at the bottom
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10, weight: .medium))
                        Text(formatDate(taxDate))
                            .font(.system(size: 10, weight: .medium))
                            .lineLimit(1)
                    }
                    .foregroundColor(.white.opacity(0.6))
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.cyan.opacity(0.9))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: hasTaxDate ? [
                    Color.black.opacity(0.3),
                    Color.blue.opacity(0.25)
                ] : [
                    Color.black.opacity(0.3),
                    Color.orange.opacity(0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(hasTaxDate ? Color.cyan.opacity(0.5) : Color.orange.opacity(0.6), lineWidth: 1)
        )
        .cornerRadius(16)
    }
}

// MARK: - Button Styles
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .brightness(configuration.isPressed ? 0.08 : 0)
            .shadow(
                color: .cyan.opacity(configuration.isPressed ? 0.5 : 0.3),
                radius: configuration.isPressed ? 12 : 10,
                x: 0,
                y: configuration.isPressed ? 3 : 5
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
