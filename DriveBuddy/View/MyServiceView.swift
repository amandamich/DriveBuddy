//
//  MyServiceView.swift
//  DriveBuddy
//
//  Created by Antonius Trimaryono on 09/11/25.
//

import SwiftUI
import CoreData

struct MyServiceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    // MARK: - ViewModel
    @StateObject private var viewModel: MyServiceViewModel

    // MARK: - Init
    init(vehicle: Vehicles, context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: MyServiceViewModel(context: context, vehicle: vehicle))
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {

                    // MARK: - HEADER (Tanpa Back Button)
                    Text("My Service")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 10)

                    Spacer(minLength: 5)

                    // MARK: - Upcoming Services
                    if !viewModel.upcomingServices.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Upcoming Service")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)

                            ForEach(viewModel.upcomingServices, id: \.objectID) { service in
                                ServiceCard(
                                    title: service.service_name ?? "Unknown",
                                    date: formatted(service.service_date),
                                    detail: "\(Int(service.odometer)) km | Next Service",
                                    type: .upcoming
                                )
                            }
                        }
                        .padding(.horizontal)
                    }

                    // MARK: - Completed Services
                    if !viewModel.completedServices.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Completed Service")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)

                            ForEach(viewModel.completedServices, id: \.objectID) { service in
                                ServiceCard(
                                    title: service.service_name ?? "Unknown",
                                    date: formatted(service.service_date),
                                    detail: "\(Int(service.odometer)) km",
                                    type: .completed
                                )
                            }
                        }
                        .padding(.horizontal)
                    }

                    // MARK: - Empty State
                    if viewModel.completedServices.isEmpty && viewModel.upcomingServices.isEmpty {
                        VStack(spacing: 16) {
                            Text("No services yet")
                                .foregroundColor(.gray)
                                .font(.headline)
                            Text("Add a new service to see it here.")
                                .foregroundColor(.gray.opacity(0.7))
                                .font(.subheadline)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 60)
                    }
                }
                .padding(.bottom, 80)
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Helper
    private func formatted(_ date: Date?) -> String {
        guard let date else { return "Unknown Date" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Enum
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
}

// MARK: - Service Card Component
struct ServiceCard: View {
    var title: String
    var date: String
    var detail: String
    var type: ServiceType

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(detail)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.top, 2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text(date)
                        .foregroundColor(.white.opacity(0.9))

                    Text(type.title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(type.color)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color(red: 17/255, green: 33/255, blue: 66/255))
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.5), radius: 6, x: 0, y: 4)
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let sampleVehicle = Vehicles(context: context)
    sampleVehicle.make_model = "Honda Brio"
    return NavigationView {
        MyServiceView(vehicle: sampleVehicle, context: context)
            .environment(\.managedObjectContext, context)
    }
}
