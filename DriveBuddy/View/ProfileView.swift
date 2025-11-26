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
                // MARK: - Dark Background with Neon Theme
                Color.black.opacity(0.95)
                    .ignoresSafeArea()

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
                                .foregroundColor(.white)
                                .shadow(color: .cyan.opacity(0.5), radius: 5)

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
                                        .fill(Color.cyan.opacity(0.2))
                                )
                                .foregroundColor(.cyan)
                                .shadow(color: .cyan.opacity(0.5), radius: 5)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)

                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 24) {
                            // MARK: - Account Section
                            VStack(alignment: .leading, spacing: 0) {
                                VStack(spacing: 0) {
                                    // Edit Profile
                                    NavigationLink {
                                        EditProfileView(profileVM: profileVM)
                                    } label: {
                                        rowLabel("Edit Profile")
                                    }

                                    Divider()
                                        .background(Color.cyan.opacity(0.3))
                                        .padding(.leading, 16)

                                    // Favorite Workshops
                                    NavigationLink {
                                        FavoriteWorkshopsView()
                                    } label: {
                                        rowLabel("Favorite Workshops")
                                    }

                                    Divider()
                                        .background(Color.cyan.opacity(0.3))
                                        .padding(.leading, 16)

                                    // Change Password
                                    NavigationLink {
                                        ChangePasswordView(authVM: authVM)
                                    } label: {
                                        rowLabel("Change Password")
                                    }

                                    Divider()
                                        .background(Color.cyan.opacity(0.3))
                                        .padding(.leading, 16)

                                    // Privacy Policy
                                    NavigationLink {
                                        PrivacyPolicyView()
                                    } label: {
                                        rowLabel("Privacy Policy")
                                    }

                                    Divider()
                                        .background(Color.cyan.opacity(0.3))
                                        .padding(.leading, 16)

                                    // About Us
                                    NavigationLink {
                                        AboutUsView()
                                    } label: {
                                        rowLabel("About Us")
                                    }
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.black.opacity(0.6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
                                        )
                                        .shadow(color: .blue.opacity(0.3), radius: 10)
                                )
                                .padding(.horizontal)
                            }

                            // MARK: - Logout Button (Neon Style)
                            Button(action: {
                                authVM.logout()
                            }) {
                                Text("Log Out")
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

    // MARK: - Avatar View with Neon Glow
    @ViewBuilder
    private var avatarView: some View {
        if let img = profileVM.avatarImage {
            img
                .resizable()
                .scaledToFill()
                .frame(width: 64, height: 64)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.cyan, lineWidth: 2)
                        .shadow(color: .cyan.opacity(0.5), radius: 5)
                )
        } else {
            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(0.2))
                    .overlay(
                        Circle()
                            .stroke(Color.cyan, lineWidth: 2)
                            .shadow(color: .cyan.opacity(0.5), radius: 5)
                    )
                Text(initials.isEmpty ? "DB" : initials)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.cyan)
            }
            .frame(width: 64, height: 64)
        }
    }

    // MARK: - Row Label with Neon Style
    @ViewBuilder
    private func rowLabel(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.white)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.cyan)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Edit Profile Screen with Neon Theme

struct EditProfileView: View {
    @ObservedObject var profileVM: ProfileViewModel

    @State private var fullName: String = ""
    @State private var phoneNumber: String = ""
    @State private var email: String = ""
    @State private var gender: String = ""
    @State private var dateOfBirth: Date = Date()
    @State private var city: String = ""

    @Environment(\.dismiss) private var dismiss

    private let genderOptions = ["Male", "Female", "Prefer not to say"]

    var body: some View {
        ZStack {
            // Dark Background
            Color.black.opacity(0.95)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Title
                    Text("Edit Profile")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.white)
                        .shadow(color: .cyan.opacity(0.5), radius: 5)
                        .padding(.top, 40)

                    // Form Fields
                    VStack(spacing: 16) {
                        neonTextField("Full Name", text: $fullName)
                        neonTextField("Phone Number", text: $phoneNumber)
                            .keyboardType(.phonePad)
                        neonTextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                        
                        // Gender Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Gender")
                                .foregroundColor(.white)
                                .font(.headline)
                                .shadow(color: .cyan.opacity(0.5), radius: 5)
                            
                            Picker("Gender", selection: $gender) {
                                ForEach(genderOptions, id: \.self) { g in
                                    Text(g).tag(g)
                                }
                            }
                            .pickerStyle(.segmented)
                            .colorMultiply(.cyan)
                        }
                        .padding(.horizontal, 30)
                        
                        // Date Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date of Birth")
                                .foregroundColor(.white)
                                .font(.headline)
                                .shadow(color: .cyan.opacity(0.5), radius: 5)
                            
                            DatePicker("", selection: $dateOfBirth, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .colorMultiply(.cyan)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.cyan, lineWidth: 2)
                                        .shadow(color: .blue, radius: 8)
                                )
                                .shadow(color: .blue.opacity(0.3), radius: 10)
                        }
                        .padding(.horizontal, 30)
                        
                        neonTextField("City", text: $city)
                    }

                    // Save Button
                    Button(action: {
                        profileVM.saveProfileChanges(
                            name: fullName,
                            phone: phoneNumber,
                            email: email,
                            gender: gender,
                            dateOfBirth: dateOfBirth,
                            city: city
                        )
                        dismiss()
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
                    .padding(.top, 20)
                }
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
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
    
    // Neon TextField Component
    @ViewBuilder
    private func neonTextField(_ placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(placeholder)
                .foregroundColor(.white)
                .font(.headline)
                .shadow(color: .cyan.opacity(0.5), radius: 5)
            
            TextField(placeholder, text: text)
                .padding()
                .foregroundColor(.black)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.cyan, lineWidth: 2)
                        .shadow(color: .blue, radius: 8)
                )
                .cornerRadius(12)
                .shadow(color: .blue.opacity(0.3), radius: 10)
        }
        .padding(.horizontal, 30)
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

#Preview("Edit Profile") {
    let context = PersistenceController.shared.container.viewContext
    let authVM = AuthenticationViewModel(context: context)

    let mockUser = User(context: context)
    mockUser.email = "preview@drivebuddy.com"

    authVM.currentUser = mockUser
    
    let profileVM = ProfileViewModel(context: context, user: mockUser)

    return NavigationStack {
        EditProfileView(profileVM: profileVM)
    }
}
