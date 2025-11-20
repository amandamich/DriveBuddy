//
//  ProfileView.swift
//  DriveBuddy
//
//  Created by Howie Homan on 04/11/25.
//

import SwiftUI
import CoreData
import PhotosUI
import UIKit

struct ProfileView: View {
    @ObservedObject var authVM: AuthenticationViewModel
    @StateObject private var profileVM: ProfileViewModel

    @State private var selectedPhotoItem: PhotosPickerItem?

    init(authVM: AuthenticationViewModel) {
        _authVM = ObservedObject(initialValue: authVM)
        _profileVM = StateObject(
            wrappedValue: ProfileViewModel(
                context: authVM.viewContext,
                user: authVM.currentUser
            )
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Background
                Color("BackgroundPrimary")
                    .ignoresSafeArea()
                    .preferredColorScheme(profileVM.isDarkMode ? .dark : .light)

                VStack(alignment: .leading, spacing: 0) {
                    // MARK: - Header Logo
                    Image("LogoDriveBuddy")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 40)
                        .padding(.bottom)
                        .padding(.horizontal)

                    // MARK: - Profile Header (Avatar + Info + Edit Photo)
                    HStack(alignment: .center, spacing: 16) {
                        avatarView

                        VStack(alignment: .leading, spacing: 4) {
                            Text(displayName)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(Color("TextPrimary"))

                            Text(displayEmail)
                                .font(.system(size: 15))
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Text("Edit")
                                .font(.system(size: 14, weight: .semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color("AccentNeon").opacity(0.15))
                                )
                                .foregroundColor(Color("AccentNeon"))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)

                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 24) {
                            // MARK: - Settings Section
                            VStack(alignment: .leading, spacing: 0) {
                                HStack(spacing: 12) {
                                    Image(systemName: "gearshape.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(Color("AccentNeon"))

                                    Text("Settings")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(Color("TextPrimary"))
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 16)

                                VStack(spacing: 0) {
                                    // Add to Calendar Toggle
                                    HStack {
                                        Text("Add to Calendar")
                                            .font(.system(size: 16))
                                            .foregroundColor(Color("TextPrimary"))

                                        Spacer()

                                        Toggle("", isOn: $profileVM.addToCalendar)
                                            .labelsHidden()
                                            .tint(Color("AccentNeon"))
                                            .onChange(of: profileVM.addToCalendar) {
                                                profileVM.toggleAddToCalendar(profileVM.addToCalendar)
                                            }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)

                                    Divider()
                                        .background(Color("TextPrimary").opacity(0.15))
                                        .padding(.leading, 16)

                                    // Theme Toggle
                                    HStack {
                                        Text("Theme")
                                            .font(.system(size: 16))
                                            .foregroundColor(Color("TextPrimary"))

                                        Spacer()

                                        Toggle("", isOn: $profileVM.isDarkMode)
                                            .labelsHidden()
                                            .tint(Color("AccentNeon"))
                                            .onChange(of: profileVM.isDarkMode) {
                                                profileVM.toggleDarkMode(profileVM.isDarkMode)
                                            }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color("CardBackground"))
                                )
                                .padding(.horizontal)
                            }

                            // MARK: - Account Section
                            VStack(alignment: .leading, spacing: 0) {
                                HStack(spacing: 12) {
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(Color("AccentNeon"))

                                    Text("Account")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(Color("TextPrimary"))
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 16)

                                VStack(spacing: 0) {
                                    // Edit Profile
                                    NavigationLink {
                                        EditProfileView(profileVM: profileVM)
                                    } label: {
                                        rowLabel("Edit Profile")
                                    }

                                    Divider()
                                        .background(Color("TextPrimary").opacity(0.15))
                                        .padding(.leading, 16)

                                    // 🆕 Favorite Workshops
                                    NavigationLink {
                                        FavoriteWorkshopsView()
                                    } label: {
                                        rowLabel("Favorite Workshops")
                                    }

                                    Divider()
                                        .background(Color("TextPrimary").opacity(0.15))
                                        .padding(.leading, 16)

                                    // Change Password
                                    NavigationLink {
                                        ChangePasswordView(authVM: authVM)
                                    } label: {
                                        rowLabel("Change Password")
                                    }

                                    Divider()
                                        .background(Color("TextPrimary").opacity(0.15))
                                        .padding(.leading, 16)

                                    // Privacy Policy
                                    NavigationLink {
                                        PrivacyPolicyView()
                                    } label: {
                                        rowLabel("Privacy Policy")
                                    }
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color("CardBackground"))
                                )
                                .padding(.horizontal)
                            }

                            // MARK: - Logout Button
                            Button(action: {
                                authVM.logout()
                            }) {
                                Text("Log Out")
                                    .font(.system(size: 16, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .foregroundColor(profileVM.isDarkMode ? .white : .black)
                                    .background(
                                        Group {
                                            if profileVM.isDarkMode {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.cyan, lineWidth: 4)
                                                    .shadow(color: Color.blue.opacity(0.6), radius: 8)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .fill(Color.black.opacity(0.5))
                                                    )
                                                    .shadow(color: Color.blue.opacity(0.5), radius: 6)
                                            } else {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color.white)
                                                    .stroke(Color.cyan, lineWidth: 4)
                                                    .shadow(color: Color.cyan.opacity(0.5), radius: 6)
                                            }
                                        }
                                    )
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 20)
                        }
                        .padding(.bottom, 100)
                    }
                }
                .onAppear {
                    profileVM.loadProfile()
                }
                .onChange(of: selectedPhotoItem, initial: false) { _, newValue in
                    guard let newValue else { return }
                    Task {
                        if let data = try? await newValue.loadTransferable(type: Data.self) {
                            await MainActor.run {
                                profileVM.updateAvatar(with: data)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Computed helpers
    private var displayName: String {
        if !profileVM.username.isEmpty {
            return profileVM.username
        }
        return profileVM.user?.email?
            .components(separatedBy: "@").first ?? "User"
    }

    private var displayEmail: String {
        if !profileVM.email.isEmpty {
            return profileVM.email
        }
        return profileVM.user?.email ?? "No email found"
    }

    private var initials: String {
        let components = displayName.split(separator: " ")
        let first = components.first?.first.map(String.init) ?? ""
        let last  = components.dropFirst().first?.first.map(String.init) ?? ""
        return (first + last).uppercased()
    }

    // MARK: - Avatar View
    @ViewBuilder
    private var avatarView: some View {
        if let img = profileVM.avatarImage {
            img
                .resizable()
                .scaledToFill()
                .frame(width: 64, height: 64)
                .clipShape(Circle())
        } else {
            ZStack {
                Circle()
                    .fill(Color("AccentNeon").opacity(0.15))
                Text(initials.isEmpty ? "DB" : initials)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color("AccentNeon"))
            }
            .frame(width: 64, height: 64)
        }
    }

    // MARK: - Row Label Reusable Component
    @ViewBuilder
    private func rowLabel(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(Color("TextPrimary"))

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Edit Profile Screen

struct EditProfileView: View {
    @ObservedObject var profileVM: ProfileViewModel

    @State private var fullName: String = ""
    @State private var phoneNumber: String = ""
    @State private var email: String = ""
    @State private var gender: String = ""
    @State private var dateOfBirth: Date = Date()
    @State private var city: String = ""

    @Environment(\.dismiss) private var dismiss

    // Simple gender options
    private let genderOptions = ["Male", "Female", "Prefer not to say"]

    var body: some View {
        Form {
            Section(header: Text("Personal Info")) {
                TextField("Full Name", text: $fullName)
                TextField("Phone Number", text: $phoneNumber)
                    .keyboardType(.phonePad)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)

                Picker("Gender", selection: $gender) {
                    ForEach(genderOptions, id: \.self) { g in
                        Text(g).tag(g)
                    }
                }

                DatePicker("Date of Birth",
                           selection: $dateOfBirth,
                           displayedComponents: .date)
                TextField("City", text: $city)
            }

            Section {
                Button {
                    profileVM.saveProfileChanges(
                        name: fullName,
                        phone: phoneNumber,
                        email: email,
                        gender: gender,
                        dateOfBirth: dateOfBirth,
                        city: city
                    )
                    dismiss()
                } label: {
                    Text("Save Changes")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .navigationTitle("Edit Profile")
        .onAppear {
            fullName    = profileVM.username
            phoneNumber = profileVM.phoneNumber
            email       = profileVM.email.isEmpty
                ? (profileVM.user?.email ?? "")
                : profileVM.email
            gender      = profileVM.gender
            city        = profileVM.city
            dateOfBirth = profileVM.dateOfBirth ?? Date()
        }
    }
}

// MARK: - Preview

#Preview {
    let context = PersistenceController.shared.container.viewContext
    let authVM = AuthenticationViewModel(context: context)

    let mockUser = User(context: context)
    mockUser.email = "preview@drivebuddy.com"
    mockUser.add_to_calendar = true

    authVM.currentUser = mockUser

    return ProfileView(authVM: authVM)
        .environment(\.managedObjectContext, context)
}

#Preview("Dark Mode") {
    let context = PersistenceController.shared.container.viewContext
    let authVM = AuthenticationViewModel(context: context)

    let mockUser = User(context: context)
    mockUser.email = "preview@drivebuddy.com"
    mockUser.add_to_calendar = true

    authVM.currentUser = mockUser

    return ProfileView(authVM: authVM)
        .preferredColorScheme(.dark)
        .environment(\.managedObjectContext, context)
}

#Preview("Light Mode") {
    let context = PersistenceController.shared.container.viewContext
    let authVM = AuthenticationViewModel(context: context)

    let mockUser = User(context: context)
    mockUser.email = "preview@drivebuddy.com"
    mockUser.add_to_calendar = true

    authVM.currentUser = mockUser

    return ProfileView(authVM: authVM)
        .preferredColorScheme(.light)
        .environment(\.managedObjectContext, context)
}
