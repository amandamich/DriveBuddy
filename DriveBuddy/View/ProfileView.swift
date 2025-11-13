//
//  ProfileView.swift
//  DriveBuddy
//

import SwiftUI
import CoreData

struct ProfileView: View {
    @ObservedObject var authVM: AuthenticationViewModel
    @StateObject private var profileVM: ProfileViewModel

    init(authVM: AuthenticationViewModel) {
        _authVM = ObservedObject(initialValue: authVM)

        // Create instance
        let vm = ProfileViewModel(
            context: authVM.viewContext,
            user: authVM.currentUser
        )

        // 🔥 Connect logout callback
        vm.onLogout = {
            authVM.logout()
        }

        _profileVM = StateObject(wrappedValue: vm)
    }

    var body: some View {
        NavigationStack {
            ZStack {

                // MARK: - Background
                Color("BackgroundPrimary")
                    .ignoresSafeArea()

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
                             (profileVM.user?.email?.components(separatedBy: "@").first ?? "User")
                             : profileVM.username
                        )
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(Color("TextPrimary"))

                        Text(profileVM.email.isEmpty ?
                             (profileVM.user?.email ?? "No email found")
                             : profileVM.email
                        )
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
                            NavigationLink {
                                ChangePasswordView()
                            } label: {
                                rowLabel("Change Password")
                            }

                            Divider()
                                .background(Color("TextPrimary").opacity(0.15))
                                .padding(.leading, 16)

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

                    // MARK: - Logout Button
                    Button {
                        profileVM.logout()     // 🔥 Now uses ViewModel logout()
                    } label: {
                        HStack {
                            Text("Logout")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.red)

                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color("CardBackground"))
                        )
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 20)

                    Spacer()
                }
                .onAppear {
                    profileVM.loadProfile()
                }
            }
            .preferredColorScheme(profileVM.isDarkMode ? .dark : .light)
        }
    }

    // MARK: - Row Label Component
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
