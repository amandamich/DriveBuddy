//
//  AddServiceView.swift
//  DriveBuddy
//
//  Created by Jacqlyn on 05/11/25.
//

import SwiftUI
import CoreData

struct AddServiceView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    @StateObject private var viewModel: AddServiceViewModel
    @ObservedObject var profileVM: ProfileViewModel

    // MARK: - Init
    init(vehicle: Vehicles, context: NSManagedObjectContext, profileVM: ProfileViewModel) {
        self.profileVM = profileVM
        _viewModel = StateObject(
            wrappedValue: AddServiceViewModel(
                context: context,
                vehicle: vehicle,
                profileVM: profileVM
            )
        )
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()

            VStack(spacing: 0) {

                // ==============================
                //       FIXED HEADER
                // ==============================
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.15))
                            )
                    }

                    Spacer()

                    Text("Add Service")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)


                    // Make title centered
                    Color.clear.frame(width: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 16)
                .background(Color.black.opacity(0.95))
                .zIndex(1)

                // ==============================
                //           CONTENT
                // ==============================
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        serviceInfoSection
                        reminderSection
                        addButtonSection
                        messageSection
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar) // Hapus back button default
    }
}

//
// MARK: - FORM SECTIONS
//

extension AddServiceView {

    // SECTION: Service Info
    private var serviceInfoSection: some View {
        SectionBoxService(title: "Service Info", icon: "wrench.fill") {
            VStack(alignment: .leading, spacing: 15) {

                VStack(alignment: .leading, spacing: 6) {
                    Text("Service Name")
                        .foregroundColor(.white)
                        .font(.headline)
                    TextField("Oil Service", text: $viewModel.serviceName)
                        .textFieldStyle(CustomTextFieldStyleService())
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Date")
                        .foregroundColor(.white)
                        .font(.headline)
                    HStack {
                        DatePicker(
                            "",
                            selection: $viewModel.selectedDate,
                            displayedComponents: .date
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Current Odometer (km)")
                        .foregroundColor(.white)
                        .font(.headline)
                    TextField("47901", text: $viewModel.odometer)
                        .keyboardType(.numberPad)
                        .textFieldStyle(CustomTextFieldStyleService())
                }
            }
        }
    }

    // SECTION: Reminder
    private var reminderSection: some View {
        SectionBoxService(title: "Reminder Settings", icon: "bell.badge.fill") {
            VStack(alignment: .leading, spacing: 15) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Reminders")
                        .foregroundColor(.white)
                        .font(.headline)

                    Menu {
                        ForEach(viewModel.reminderOptions, id: \.self) { opt in
                            Button(opt) { viewModel.reminder = opt }
                        }
                    } label: {
                        HStack {
                            Text(viewModel.reminder)
                                .foregroundColor(.black)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                    }
                }
                .padding(.top, 6)
            }
        }
    }

    // SECTION: Add Button
    private var addButtonSection: some View {
        Button(action: {
            viewModel.addService()
            if viewModel.successMessage != nil { dismiss() }
        }) {
            Text("Add Service")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.cyan, lineWidth: 2)
                        .shadow(color: .blue, radius: 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.5))
                        )
                )
                .shadow(color: .blue, radius: 10)
        }
    }

    // SECTION: Messages
    private var messageSection: some View {
        Group {
            if let message = viewModel.errorMessage {
                Text(message)
                    .foregroundColor(.red)
                    .font(.subheadline)
            } else if let message = viewModel.successMessage {
                Text(message)
                    .foregroundColor(.green)
                    .font(.subheadline)
            }
        }
    }
}

//
// MARK: - Shared Components
//

struct SectionBoxService<Content: View>: View {
    var title: String
    var icon: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
            }

            VStack(spacing: 12) {
                content
            }
            .padding()
            .background(Color.blue.opacity(0.15))
            .cornerRadius(15)
        }
    }
}

struct CustomTextFieldStyleService: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.white)
            .cornerRadius(10)
    }
}

//
// MARK: - Preview
//

#Preview {
    let previewContext = PersistenceController.preview.container.viewContext
    let sampleVehicle = Vehicles(context: previewContext)
    sampleVehicle.make_model = "Honda Civic"

    let dummyProfileVM = ProfileViewModel(context: previewContext)

    return NavigationView {
        AddServiceView(
            vehicle: sampleVehicle,
            context: previewContext,
            profileVM: dummyProfileVM
        )
    }
}
