//
//  EditProfileView.swift
//  DriveBuddy
//
//  Created by student on 26/11/25.
//

import SwiftUI
import PhotosUI
import Foundation
import CoreData // Pastikan Anda mengimpor CoreData jika CoreData digunakan di ViewModel

struct EditProfileView: View {
    @ObservedObject var profileVM: ProfileViewModel

    @State private var selectedPhotoItem: PhotosPickerItem?
    
    // MARK: - State Properties
    // Tidak lagi diberi nilai default, nilainya akan diisi di init
    @State private var fullName: String
    @State private var phoneNumber: String
    @State private var email: String
    @State private var gender: String
    
    // Custom DOB values
    @State private var selectedDay: Int
    @State private var selectedMonth: Int
    @State private var selectedYear: Int
    
    @Environment(\.dismiss) private var dismiss

    private let genderOptions = ["Male", "Female", "Prefer not to say"]

    private let days = Array(1...31)
    private let months = [
        (1, "Jan"), (2, "Feb"), (3, "Mar"), (4, "Apr"),
        (5, "May"), (6, "Jun"), (7, "Jul"), (8, "Aug"),
        (9, "Sep"), (10, "Oct"), (11, "Nov"), (12, "Dec")
    ]
    private let years = Array(1950...2025).reversed()

    // MARK: - Custom Initializer untuk Inisialisasi Data Awal
    init(profileVM: ProfileViewModel) {
        self._profileVM = ObservedObject(initialValue: profileVM)
        
        // Dapatkan data awal dari ViewModel
        let initialDOB = profileVM.dateOfBirth ?? Date()
        let calendar = Calendar.current
        
        // Inisialisasi semua properti @State agar tidak terjadi lag/flickering
        self._fullName = State(initialValue: profileVM.username)
        self._phoneNumber = State(initialValue: profileVM.phoneNumber)
        // Jika email di VM kosong, ambil dari user Core Data, jika tidak, pakai email di VM
        self._email = State(initialValue: profileVM.email.isEmpty ? (profileVM.user?.email ?? "") : profileVM.email)
        self._gender = State(initialValue: profileVM.gender)
        
        // Inisialisasi Date of Birth components
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

    // MARK: - Body
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
                        // Menggunakan $fullName, $phoneNumber, $email yang sudah diinisialisasi
                        neonTextField("Full Name", text: $fullName)
                        neonTextField("Phone Number", text: $phoneNumber)
                            .keyboardType(.phonePad)
                        neonTextField("Email", text: $email)
                            .keyboardType(.emailAddress)

                        // GENDER DROPDOWN
                        neonDropdown("Gender", selection: $gender, options: genderOptions)

                        // CUSTOM DATE PICKER (Day / Month / Year)
                        dateOfBirthPicker

                        // Menggunakan $profileVM.city karena ini adalah data yang perlu di-save
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
        // Hapus blok .onAppear karena inisialisasi sudah dilakukan di init
        /* .onAppear {
            fullName = profileVM.username
            // ... (dan inisialisasi lainnya)
        } */
        
        .onChange(of: selectedPhotoItem) { _, newValue in
            guard let newValue else { return }
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self) {
                    await MainActor.run { profileVM.updateAvatar(with: data) }
                }
            }
        }
    }

    // MARK: Custom View Components (Diambil dari kode sebelumnya)
    
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

#Preview{
    
}
// MARK: - Preview (Jika Preview Anda menggunakan Core Data)
/* Hapus atau sesuaikan kode Preview Anda jika ada error kompilasi di sini. */
/* #Preview {
    let context = PersistenceController.shared.container.viewContext
    let mockUser = User(context: context)
    // ... setup mockUser ...

    let vm = ProfileViewModel(context: context, user: mockUser)

    NavigationStack {
        EditProfileView(profileVM: vm)
    }
} */
