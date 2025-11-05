//
//  AddServiceView.swift
//  DriveBuddy
//
//  Created by Jacqlyn on 05/11/25.
//

import SwiftUI

struct AddServiceView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var serviceName: String = ""
    @State private var selectedDate: Date = Date()
    @State private var odometer: String = ""
    @State private var reminder: String = "One month before"
    @State private var addToReminder: Bool = true
    
    let reminderOptions = ["One week before", "Two weeks before", "One month before"]
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // MARK: Header
                    Text("Add Service")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top)
                    
                    // MARK: Service Info Section
                    SectionBox(title: "Service Info", icon: "wrench.fill") {
                        VStack(alignment: .leading, spacing: 15) {
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Service Name")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                TextField("Oil Service", text: $serviceName)
                                    .textFieldStyle(CustomTextFieldStyle())
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Date")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                HStack {
                                    DatePicker("", selection: $selectedDate, displayedComponents: .date)
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
                                TextField("47901", text: $odometer)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(CustomTextFieldStyle())
                            }
                        }
                    }
                    
                    // MARK: Reminder Section
                    SectionBox(title: "Reminder Settings", icon: "bell.badge.fill") {
                        VStack(alignment: .leading, spacing: 15) {
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Reminders")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                Menu {
                                    ForEach(reminderOptions, id: \.self) { option in
                                        Button(option) { reminder = option }
                                    }
                                } label: {
                                    HStack {
                                        Text(reminder)
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
                            
                            HStack {
                                Text("Add to Reminder")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                Spacer()
                                Toggle("", isOn: $addToReminder)
                                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                            }
                            .padding(.top, 6)
                        }
                    }
                    
                    // MARK: Add Button
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Add Service")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.8))
                            .cornerRadius(20)
                            .padding(.top)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Shared Components
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

// MARK: - Preview
#Preview {
    AddServiceView()
}
