// VehicleDetailView

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
    
    // Add onDismiss callback
    var onDismiss: (() -> Void)?

    // Init untuk menerima objek User Aktif
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
            // Always use dark background matching the theme
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
                    
                    // MARK: VEHICLE DROPDOWN
                    Menu {
                        ForEach(allVehicles, id: \.objectID) { v in
                            Button(v.make_model ?? "Unknown") {
                                withAnimation(.easeInOut) {
                                    if v.user == viewModel.activeUser {
                                        viewModel.activeVehicle = v
                                        viewModel.loadVehicleData()
                                    } else {
                                        print("User B coba pindah mobil ke milik User A")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "car.fill")
                                .foregroundColor(.cyan)
                                .imageScale(.medium)
                            
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
                    
                    
                    // MARK: UPCOMING SERVICE & TAX CLICKABLE SECTION
                    HStack(spacing: 16) {
                        
                        // UPCOMING SERVICES
                        Button(action: {
                            showMyService = true
                        }) {
                            ClickableCard(
                                icon: "wrench.and.screwdriver.fill",
                                title: "Upcoming Services",
                                subtitle: viewModel.serviceName.isEmpty ? "No service scheduled" : viewModel.serviceName,
                                date: viewModel.formatDate(viewModel.nextServiceDate)
                            )
                        }
                        .buttonStyle(CardButtonStyle())
                        .frame(maxWidth: .infinity)
                        
                        // TAX PAYMENT
                        Button(action: {
                            showMyTax = true
                        }) {
                            ClickableCard(
                                icon: "banknote.fill",
                                title: "Tax Payment",
                                subtitle: "Next Due",
                                date: viewModel.formatDate(viewModel.taxDueDate)
                            )
                        }
                        .buttonStyle(CardButtonStyle())
                        .frame(maxWidth: .infinity)
                    }
                    .frame(height: 140)
                    .padding(.horizontal)
                    
                    
                    // MARK: LAST SERVICE + BUTTON
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

                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(viewModel.serviceName.isEmpty ? "No service recorded" : viewModel.serviceName)
                            }
                            .foregroundColor(.white)

                            Spacer()

                            VStack(alignment: .trailing, spacing: 6) {
                                Text(viewModel.formatDate(viewModel.lastServiceDate))
                            }
                            .foregroundColor(.white.opacity(0.8))
                        }
                        .font(.subheadline)
                    }
                    .padding()
                    .background(Color(red: 17/255, green: 33/255, blue: 66/255))
                    .cornerRadius(18)
                    .shadow(color: .cyan.opacity(0.25), radius: 6, x: 0, y: 4)
                    .padding(.horizontal)

                    
                    Spacer(minLength: 60)
                }
            }
        }
        .onAppear {
            print("[Debug] VehicleDetailView Muncul")
            viewModel.loadVehicleData()
        }
        .onDisappear {
            // Call onDismiss when view disappears
            onDismiss?()
        }
        
        // MARK: - My Service Sheet
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
        
        // MARK: - Tax History Sheet
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
        
        // MARK: - Add Service Sheet
        .sheet(isPresented: $showAddService) {
            NavigationStack {
                AddServiceView(
                    vehicle: viewModel.activeVehicle,
                    context: viewContext,
                    profileVM: profileVM
                )
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            showAddService = false
                            viewModel.loadVehicleData() // Reload after adding service
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        
        // MARK: - Edit Vehicle Sheet
        .sheet(isPresented: $viewModel.isEditing) {
            // Refresh data when edit sheet is dismissed
            viewModel.loadVehicleData()
        } content: {
            EditVehicleView(viewModel: viewModel)
        }
        
        .navigationBarBackButtonHidden(false)
    }
}


// MARK: - Custom Button Style for Cards
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


// MARK: - Clickable Card Component
struct ClickableCard: View {
    var icon: String
    var title: String
    var subtitle: String
    var date: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            
            // Icon and title section
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(title)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .minimumScaleFactor(0.85)
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Text(subtitle)
                .lineLimit(1)
                .foregroundColor(.white.opacity(0.85))
                .font(.system(size: 13, weight: .regular))
            
            Spacer(minLength: 2)
            
            // Date section at bottom
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 10, weight: .medium))
                Text(date)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                
                Spacer()
                
                // Chevron indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.cyan.opacity(0.9))
            }
            .foregroundColor(.white.opacity(0.8))
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
        .shadow(color: .cyan.opacity(0.3), radius: 7, x: 0, y: 4)
    }
}
