//
//  ProfileView.swift
//  DriveBuddy
//
//  Created by Howie Homan on 04/11/25.
//

import SwiftUI
import CoreData

struct ProfileView: View {
    @ObservedObject var authVM: AuthenticationViewModel
    @StateObject private var profileVM: ProfileViewModel

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
                    .preferredColorScheme(profileVM.isDarkMode ? .dark : .light) // ✅ Dynamic Theme

                VStack(alignment: .leading, spacing: 0) {
                    // MARK: - Header
                    Image("LogoDriveBuddy")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 40)
                        .padding(.bottom)

                    // MARK: - Profile Title
                    Text("Profile")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(Color("TextPrimary"))
                        .padding(.horizontal)
                        .padding(.bottom, 8)

                    // MARK: - User Info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(profileVM.username.isEmpty ?
                             (profileVM.user?.email?.components(separatedBy: "@").first ?? "User") :
                                profileVM.username)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(Color("TextPrimary"))

                        Text(profileVM.email.isEmpty ? (profileVM.user?.email ?? "No email found") : profileVM.email)
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)

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
                    .padding(.bottom, 24)

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
                            // Change Password
                            NavigationLink {
                                ChangePasswordView()
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
                    .padding(.bottom, 24)

                    Spacer()
                }
                .onAppear {
                    profileVM.loadProfile() // ✅ Refresh data when screen appears
                }
            }
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

//#Preview("Light Mode") {
//    let context = PersistenceController.shared.container.viewContext
//    let mockUser = User(context: context)
//    mockUser.email = "preview@drivebuddy.com"
//    mockUser.add_to_calendar = true
//    mockUser.is_dark_mode = false
//    let mockAuthVM = AuthenticationViewModel(context: context)
//    mockAuthVM.currentUser = mockUser
//    return ProfileView(authVM: mockAuthVM)
//        .preferredColorScheme(.light)
//}
//
//#Preview("Dark Mode") {
//    let context = PersistenceController.shared.container.viewContext
//    let mockUser = User(context: context)
//    mockUser.email = "preview@drivebuddy.com"
//    mockUser.add_to_calendar = true
//    mockUser.is_dark_mode = true
//    let mockAuthVM = AuthenticationViewModel(context: context)
//    mockAuthVM.currentUser = mockUser
//    return ProfileView(authVM: mockAuthVM)
//        .preferredColorScheme(.dark)
//}

