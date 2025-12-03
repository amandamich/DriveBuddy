//
//  EditProfileView.swift
//  DriveBuddy
//
//  Created by student on 26/11/25.
//

import SwiftUI
import PhotosUI
import Foundation
import CoreData

struct EditProfileView: View {
    @ObservedObject var profileVM: ProfileViewModel

    @State private var selectedPhotoItem: PhotosPickerItem?
    
    // MARK: - State Properties
    @State private var fullName: String
    @State private var phoneNumber: String
    @State private var email: String
    @State private var gender: String
    
    @State private var selectedDay: Int
    @State private var selectedMonth: Int
    @State private var selectedYear: Int
    
    @State private var showingExitAlert = false
    @State private var showingDateValidationAlert = false
    @State private var dateValidationMessage = ""
    
    @Environment(\.dismiss) private var dismiss

    private let genderOptions = ["Male", "Female", "Prefer not to say"]

    private let days = Array(1...31)
    private let months = [
        (1, "Jan"), (2, "Feb"), (3, "Mar"), (4, "Apr"),
        (5, "May"), (6, "Jun"), (7, "Jul"), (8, "Aug"),
        (9, "Sep"), (10, "Oct"), (11, "Nov"), (12, "Dec")
    ]
    private let years = Array(1950...2025).reversed()

    // MARK: - Custom Initializer
    init(profileVM: ProfileViewModel) {
        self._profileVM = ObservedObject(initialValue: profileVM)
        
        let initialDOB = profileVM.dateOfBirth ?? Date()
        let calendar = Calendar.current
        
        self._fullName = State(initialValue: profileVM.username)
        self._phoneNumber = State(initialValue: profileVM.phoneNumber)
        self._email = State(initialValue: profileVM.email.isEmpty ? (profileVM.user?.email ?? "") : profileVM.email)
        self._gender = State(initialValue: profileVM.gender)
        
        self._selectedDay = State(initialValue: calendar.component(.day, from: initialDOB))
        self._selectedMonth = State(initialValue: calendar.component(.month, from: initialDOB))
        self._selectedYear = State(initialValue: calendar.component(.year, from: initialDOB))
    }
    
    // MARK: - Computed Property
    private var composedDate: Date {
        let calendar = Calendar.current
        let components = DateComponents(year: selectedYear, month: selectedMonth, day: selectedDay)
        return calendar.date(from: components) ?? Date()
    }
    
    // MARK: - ✅ Date Validation Function
    private func validateDateOfBirth() -> Bool {
        let today = Date()
        let calendar = Calendar.current
        
        // Check if date is in the future
        if composedDate > today {
            dateValidationMessage = "Date of birth cannot be in the future. Please select a valid date."
            return false
        }
        
        // Check if user is at least 13 years old
        if let thirteenYearsAgo = calendar.date(byAdding: .year, value: -13, to: today),
           composedDate > thirteenYearsAgo {
            dateValidationMessage = "You must be at least 13 years old to use this app."
            return false
        }
        
        // Check if the selected date is valid (e.g., Feb 31 doesn't exist)
        let components = DateComponents(year: selectedYear, month: selectedMonth, day: selectedDay)
        if calendar.date(from: components) == nil {
            dateValidationMessage = "Invalid date. Please check your selection (e.g., Feb 31 or Feb 30 doesn't exist)."
            return false
        }
        
        return true
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            LinearGradient(colors: [.black, .black.opacity(0.9)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {

                    VStack(spacing: 8) {
                        Text("Edit Profile")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .blue, radius: 10)
                    }
                    .padding(.horizontal)

                    // Avatar Section
                    VStack(spacing: 16) {
                        avatarView

                        // MARK: - Change Profile Photo Button (WHITE BORDER)
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Text("Change Profile Photo")
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white, lineWidth: 1.5)
                                )
                        }
                    }
                    .padding(.bottom, 10)

                    VStack(spacing: 18) {
                        textFieldWithBorder("Full Name", text: $fullName)
                        textFieldWithBorder("Phone Number", text: $phoneNumber)
                            .keyboardType(.phonePad)
                        textFieldWithBorder("Email", text: $email)
                            .keyboardType(.emailAddress)

                        // GENDER DROPDOWN
                        dropdownWithBorder("Gender", selection: $gender, options: genderOptions)

                        // CUSTOM DATE PICKER
                        dateOfBirthPicker
                        
                        textFieldWithBorder("City", text: $profileVM.city)
                    }

                    // MARK: - ✅ SAVE BUTTON WITH VALIDATION
                    Button(action: {
                        // Validate date before saving
                        if validateDateOfBirth() {
                            profileVM.saveProfileChanges(
                                name: fullName,
                                phone: phoneNumber,
                                email: email,
                                gender: gender,
                                dateOfBirth: composedDate,
                                city: profileVM.city
                            )
                            dismiss()
                        } else {
                            showingDateValidationAlert = true
                        }
                    }) {
                        Text("Save Changes")
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
                    .padding(.horizontal, 30)
                    .padding(.top, 10)
                    .padding(.bottom, 30)
                }
            }
        }
        .onChange(of: selectedPhotoItem) { _, newValue in
            guard let newValue else { return }
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self) {
                    await MainActor.run { profileVM.updateAvatar(with: data) }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showingExitAlert = true
                } label: {
                    // MARK: WHITE BACK BUTTON
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .semibold))
                }
            }
        }
        .alert("Confirm Exit", isPresented: $showingExitAlert) {
            Button("Stay on Page", role: .cancel) { }
            Button("Exit", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("Unsaved changes will be lost. Are you sure you want to exit?")
        }
        // MARK: - ✅ Date Validation Alert
        .alert("Invalid Date of Birth", isPresented: $showingDateValidationAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(dateValidationMessage)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: Custom View Components
    
    // MARK: - Date of Birth Picker (Aligned with textfields)
    private var dateOfBirthPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Date of Birth")
                .padding(.horizontal, 30)

            HStack(spacing: 12) {
                // DAY
                Picker("Day", selection: $selectedDay) {
                    ForEach(days, id: \.self) { d in
                        Text("\(d)").tag(d)
                    }
                }
                .pickerStyle(.menu)
                .modifier(DatePickerBoxStyle())

                // MONTH
                Picker("Month", selection: $selectedMonth) {
                    ForEach(months, id: \.0) { value, title in
                        Text(title).tag(value)
                    }
                }
                .pickerStyle(.menu)
                .modifier(DatePickerBoxStyle())

                // YEAR
                Picker("Year", selection: $selectedYear) {
                    ForEach(years, id: \.self) { y in
                        Text(String(y)).tag(y)
                    }
                }
                .pickerStyle(.menu)
                .modifier(DatePickerBoxStyle())
            }
            .padding(.horizontal, 30)
        }
    }

    private var avatarView: some View {
        Group {
            if let img = profileVM.avatarImage {
                img.resizable().scaledToFill()
            } else {
                ZStack {
                    Circle().fill(Color.cyan.opacity(0.15))
                    Text(profileVM.username.isEmpty ? "DB" : String(profileVM.username.prefix(1)))
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.cyan)
                }
            }
        }
        .frame(width: 110, height: 110)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Color.white, lineWidth: 3) // WHITE BORDER
                .shadow(color: .white.opacity(0.5), radius: 10)
        )
    }

    // MARK: - TextField WITH GRAY BORDER (White background, Black text, Gray border, Gray placeholder)
    private func textFieldWithBorder(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel(label)
            TextField("", text: text, prompt: Text(label).foregroundColor(.gray.opacity(0.5)))
                .padding()
                .foregroundColor(.black) // BLACK TEXT for readability
                .background(Color.white) // WHITE BACKGROUND
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.4), lineWidth: 1) // GRAY BORDER
                )
                .cornerRadius(12)
        }
        .padding(.horizontal, 30)
    }

    // MARK: - Dropdown WITH GRAY BORDER
    private func dropdownWithBorder(_ label: String, selection: Binding<String>, options: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel(label)

            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option) { selection.wrappedValue = option }
                }
            } label: {
                HStack {
                    Text(selection.wrappedValue.isEmpty ? "Select \(label)" : selection.wrappedValue)
                        .foregroundColor(.black) // BLACK TEXT
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white) // WHITE BACKGROUND
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.4), lineWidth: 1) // GRAY BORDER
                )
                .cornerRadius(12)
            }
        }
        .padding(.horizontal, 30)
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .foregroundColor(.white)
            .shadow(color: .cyan.opacity(0.6), radius: 6)
    }
}

// MARK: - Date Picker Box Style WITH GRAY BORDER (Black text like "20 Nov 2025")
struct DatePickerBoxStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(width: 85)
            .padding(8)
            .background(Color.white) // WHITE BACKGROUND
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.4), lineWidth: 1) // GRAY BORDER
            )
            .cornerRadius(10)
            .foregroundColor(.black) // BLACK TEXT (like "20 Nov 2025")
            .tint(.black) // Ensures picker text is black
    }
}
