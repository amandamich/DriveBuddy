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
    @State private var fullName: String = ""
    @State private var phoneNumber: String = ""
    @State private var email: String = ""
    @State private var gender: String = ""
    
    // Custom DOB values
    @State private var selectedDay: Int = 1
    @State private var selectedMonth: Int = 1
    @State private var selectedYear: Int = 1990
    
    @Environment(\.dismiss) private var dismiss

    private let genderOptions = ["Male", "Female", "Prefer not to say"]

    private let days = Array(1...31)
    private let months = [
        (1, "Jan"), (2, "Feb"), (3, "Mar"), (4, "Apr"),
        (5, "May"), (6, "Jun"), (7, "Jul"), (8, "Aug"),
        (9, "Sep"), (10, "Oct"), (11, "Nov"), (12, "Dec")
    ]
    private let years = Array(1950...2025).reversed()

    private var composedDate: Date {
        let calendar = Calendar.current
        let components = DateComponents(year: selectedYear, month: selectedMonth, day: selectedDay)
        return calendar.date(from: components) ?? Date()
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [.black, .black.opacity(0.9)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {

                    Text("Edit Profile")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.top, 35)
                        .shadow(color: .cyan.opacity(0.7), radius: 8)

                    // Avatar
                    VStack(spacing: 16) {
                        avatarView

                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Text("Change Profile Photo")
                                .fontWeight(.semibold)
                                .foregroundColor(.cyan)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .stroke(Color.cyan.opacity(0.6), lineWidth: 1.5)
                                )
                        }
                    }
                    .padding(.bottom, 10)

                    VStack(spacing: 18) {
                        neonTextField("Full Name", text: $fullName)
                        neonTextField("Phone Number", text: $phoneNumber)
                            .keyboardType(.phonePad)
                        neonTextField("Email", text: $email)
                            .keyboardType(.emailAddress)

                        // GENDER DROPDOWN
                        neonDropdown("Gender", selection: $gender, options: genderOptions)

                        // CUSTOM DATE PICKER (Day / Month / Year)
                        dateOfBirthPicker

                        neonTextField("City", text: $profileVM.city)
                    }

                    // SAVE BUTTON
                    Button(action: {
                        profileVM.saveProfileChanges(
                            name: fullName,
                            phone: phoneNumber,
                            email: email,
                            gender: gender,
                            dateOfBirth: composedDate,
                            city: profileVM.city
                        )
                        dismiss()
                    }) {
                        Text("Save Changes")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.cyan, lineWidth: 2)
                                    .background(Color.black.opacity(0.5))
                            )
                            .shadow(color: .cyan.opacity(0.5), radius: 10)
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 30)
                }
            }
        }
        .onAppear {
            fullName = profileVM.username
            phoneNumber = profileVM.phoneNumber
            email = profileVM.email.isEmpty ? (profileVM.user?.email ?? "") : profileVM.email
            
            if let dob = profileVM.dateOfBirth {
                let calendar = Calendar.current
                selectedDay = calendar.component(.day, from: dob)
                selectedMonth = calendar.component(.month, from: dob)
                selectedYear = calendar.component(.year, from: dob)
            }
            
            gender = profileVM.gender
        }
        .onChange(of: selectedPhotoItem) { _, newValue in
            guard let newValue else { return }
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self) {
                    await MainActor.run { profileVM.updateAvatar(with: data) }
                }
            }
        }
    }

    // MARK: Custom Date Picker component
    private var dateOfBirthPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            neonLabel("Date of Birth")

            HStack(spacing: 12) {

                // DAY
                Picker("Day", selection: $selectedDay) {
                    ForEach(days, id: \.self) { d in
                        Text("\(d)").tag(d)
                    }
                }
                .pickerStyle(.menu)
                .modifier(neonBox())

                // MONTH
                Picker("Month", selection: $selectedMonth) {
                    ForEach(months, id: \.0) { value, title in
                        Text(title).tag(value)
                    }
                }
                .pickerStyle(.menu)
                .modifier(neonBox())

                // YEAR
                Picker("Year", selection: $selectedYear) {
                    ForEach(years, id: \.self) { y in
                        Text("\(y)").tag(y)
                    }
                }
                .pickerStyle(.menu)
                .modifier(neonBox())
            }
            .padding(.horizontal, 30)
        }
    }

    // MARK: Avatar
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
                .stroke(Color.cyan, lineWidth: 3)
                .shadow(color: .cyan.opacity(0.8), radius: 10)
        )
    }

    // MARK: Neon TextField
    private func neonTextField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            neonLabel(label)
            TextField(label, text: text)
                .padding()
                .foregroundColor(.white)
                .background(Color.black.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.cyan.opacity(0.6), lineWidth: 2)
                )
                .cornerRadius(12)
        }
        .padding(.horizontal, 30)
    }

    // MARK: Neon Dropdown
    private func neonDropdown(_ label: String, selection: Binding<String>, options: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            neonLabel(label)

            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option) { selection.wrappedValue = option }
                }
            } label: {
                HStack {
                    Text(selection.wrappedValue.isEmpty ? "Select \(label)" : selection.wrappedValue)
                        .foregroundColor(.white.opacity(0.9))
                    Spacer()
                    Image(systemName: "chevron.down").foregroundColor(.cyan)
                }
                .padding()
                .background(Color.black.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.cyan.opacity(0.6), lineWidth: 2)
                )
                .cornerRadius(12)
            }
        }
        .padding(.horizontal, 30)
    }

    // MARK: Neon Label
    private func neonLabel(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .foregroundColor(.white)
            .shadow(color: .cyan.opacity(0.6), radius: 6)
    }
}

// MARK: - Neon Box Modifier
struct neonBox: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(width: 85)
            .padding(8)
            .background(Color.black.opacity(0.5))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.cyan.opacity(0.6), lineWidth: 2)
            )
            .cornerRadius(10)
            .foregroundColor(.white)
    }
}

#Preview {
    let context = PersistenceController.shared.container.viewContext
    let mockUser = User(context: context)

    mockUser.email = "preview@drivebuddy.com"
    mockUser.add_to_calendar = false
    mockUser.is_dark_mode = true   // sesuaikan attribute entity kamu

    let vm = ProfileViewModel(context: context, user: mockUser)

    // Set data langsung ke ViewModel (karena INI YANG BENAR)
    vm.username = "Jessica"
    vm.gender = "Female"
    vm.phoneNumber = "08123456789"
    vm.city = "Surabaya"
    vm.dateOfBirth = Date()   // atau tanggal yang kamu mau

    return NavigationStack {
        EditProfileView(profileVM: vm)
    }
}
