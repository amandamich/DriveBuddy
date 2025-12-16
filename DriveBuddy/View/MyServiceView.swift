//
//  MyServiceView.swift
//  DriveBuddy
//

import CoreData
import SwiftUI

struct MyServiceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    @StateObject private var viewModel: MyServiceViewModel
    @State private var selectedService: ServiceHistory?
    @State private var showCompleteService = false
    @State private var showDeleteAlert = false
    @State private var serviceToDelete: ServiceHistory?
    var activeUser: User?

    init(vehicle: Vehicles, context: NSManagedObjectContext, activeUser: User?) {
        self.activeUser = activeUser
        _viewModel = StateObject(wrappedValue: MyServiceViewModel(context: context, vehicle: vehicle))
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // MARK: - Header
                    VStack(spacing: 8) {
                        Text("Service History")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .blue, radius: 10)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
                    
                    // MARK: - Upcoming Services
                    if !viewModel.upcomingServices.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "calendar.badge.clock")
                                    .foregroundColor(.cyan)
                                    .font(.title3)
                                Text("Upcoming Services")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                            
                            List {
                                ForEach(viewModel.upcomingServices, id: \.objectID) { service in
                                    Button {
                                        selectedService = service
                                        showCompleteService = true
                                    } label: {
                                        ServiceCard(
                                            title: service.service_name?.isEmpty == false ? service.service_name! : "Scheduled Service",
                                            date: formatted(service.service_date),
                                            detail: service.odometer > 0 ? "\(Int(service.odometer)) km" : "Tap to complete",
                                            type: .upcoming
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)) // ✅ REMOVE padding
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            serviceToDelete = service
                                            showDeleteAlert = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        .tint(.red)
                                    }
                                }
                            }
                            .listStyle(.plain)
                            .frame(height: CGFloat(viewModel.upcomingServices.count * 120))
                        }
                        .padding(.horizontal)
                    }
                    
                    // MARK: - Completed Services
                    if !viewModel.completedServices.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title3)
                                Text("Completed Services")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                            List {
                                ForEach(viewModel.completedServices, id: \.objectID) { service in
                                    Button {
                                        selectedService = service
                                        showCompleteService = true   // ✅ edit completed service
                                    } label: {
                                        ServiceCard(
                                            title: service.service_name?.isEmpty == false ? service.service_name! : "Service Record",
                                            date: formatted(service.service_date),
                                            detail: service.odometer > 0 ? "\(Int(service.odometer)) km" : "Completed",
                                            type: .completed
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)) // ✅ REMOVE padding
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            serviceToDelete = service
                                            showDeleteAlert = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        .tint(.red)
                                    }
                                }
                            }
                            .listStyle(.plain)
                            .frame(height: CGFloat(viewModel.completedServices.count * 120))
                        }
                        .padding(.horizontal)
                    }
                    
                    // MARK: - Empty State
                    if viewModel.completedServices.isEmpty && viewModel.upcomingServices.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "wrench.and.screwdriver")
                                .font(.system(size: 60))
                                .foregroundColor(.gray.opacity(0.5))
                            
                            Text("No service history yet")
                                .foregroundColor(.gray)
                                .font(.headline)
                            
                            Text("Add a service to see it here.")
                                .foregroundColor(.gray.opacity(0.7))
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                    }
                }
                .padding(.bottom, 100)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.refreshServices()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                viewModel.refreshServices()
            }
        }
        .sheet(isPresented: $showCompleteService, onDismiss: {
            viewModel.refreshServices()
        }) {
            if let service = selectedService {
                NavigationView {
                    CompleteServiceView(service: service)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button {
                                    showCompleteService = false
                                } label: {
                                    Image(systemName: "xmark")
                                .foregroundColor(.white)
                                }
                            }
                        }
                }
            }
        }
        .alert("Delete Service",
               isPresented: $showDeleteAlert,
               presenting: serviceToDelete) { service in
            Button("Delete", role: .destructive) {
                viewModel.deleteService(service)
                serviceToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                serviceToDelete = nil
            }
        } message: { service in
            Text("Are you sure you want to delete \"\(service.service_name ?? "this service")\"?")
        }

    
    }
        private func formatted(_ date: Date?) -> String {
        guard let date else { return "Unknown Date" }
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date)
    }
}


// MARK: - Enum & Card Components
enum ServiceType {
    case upcoming
    case completed

    var title: String {
        switch self {
        case .upcoming: return "Upcoming"
        case .completed: return "Completed"
        }
    }

    var color: Color {
        switch self {
        case .upcoming: return .orange
        case .completed: return .green
        }
    }
    
    var icon: String {
        switch self {
        case .upcoming: return "calendar.badge.clock"
        case .completed: return "checkmark.circle.fill"
        }
    }
}

struct ServiceCard: View {
    var title: String
    var date: String
    var detail: String
    var type: ServiceType
    var showEditIcon: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Left side - Icon
            Image(systemName: type.icon)
                .font(.system(size: 28))
                .foregroundColor(type.color)
                .frame(width: 40, height: 40)
            
            // Middle - Content
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(date)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "gauge.with.dots.needle.67percent")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(detail)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            Spacer()
            HStack(spacing: 8) {
                if showEditIcon {
                    Image(systemName: "pencil")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.system(size: 14, weight: .semibold))
                }

                Text(type.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(type.color.opacity(0.9))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 17/255, green: 33/255, blue: 66/255))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(type.color.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: type.color.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Preview
#Preview {
    let context = PersistenceController.preview.container.viewContext
    
    let user = User(context: context)
    user.user_id = UUID()
    user.email = "test@user.com"

    let sampleVehicle = Vehicles(context: context)
    sampleVehicle.make_model = "Honda Brio"
    sampleVehicle.user = user
    
    let pastService = ServiceHistory(context: context)
    pastService.history_id = UUID()
    pastService.service_name = "Oil Change"
    pastService.service_date = Calendar.current.date(byAdding: .day, value: -30, to: Date())
    pastService.odometer = 45000
    pastService.vehicle = sampleVehicle
    
    let futureService = ServiceHistory(context: context)
    futureService.history_id = UUID()
    futureService.service_name = "Tire Rotation"
    futureService.service_date = Calendar.current.date(byAdding: .day, value: 30, to: Date())
    futureService.odometer = 50000
    futureService.vehicle = sampleVehicle

    return NavigationView {
        MyServiceView(
            vehicle: sampleVehicle,
            context: context,
            activeUser: user
        )
        .environment(\.managedObjectContext, context)
    }
}
