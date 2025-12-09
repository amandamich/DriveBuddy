//
//  ProfileView.swift
//  DriveBuddy
//

import SwiftUI
import CoreData
//YAURRRRR
struct ProfileView: View {
    @ObservedObject var authVM: AuthenticationViewModel
    @StateObject private var profileVM: ProfileViewModel

    init(authVM: AuthenticationViewModel) {
        self._authVM = ObservedObject(wrappedValue: authVM)
        self._profileVM = StateObject(
            wrappedValue: ProfileViewModel(
                context: authVM.viewContext,
                user: authVM.currentUser
            )
        )
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {

                // Logo
                Image("LogoDriveBuddy")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 40)
                    .padding(.bottom)
                    .padding(.horizontal)

                // MARK: - Header: Avatar + Info + Edit Btn
                HStack(spacing: 16) {

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

                    NavigationLink {
                        EditProfileView(profileVM: profileVM)
                    } label: {
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

                // MARK: - Body
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

                        accountSection

                        // MARK: Logout Button - ✅ FIXED WITH DEBUG
                        Button(action: {
                            print("🔴 LOGOUT BUTTON TAPPED")
                            print("🔴 BEFORE - isAuthenticated: \(authVM.isAuthenticated)")
                            print("🔴 BEFORE - currentUser: \(authVM.currentUser?.email ?? "nil")")
                            
                            authVM.logout()
                            
                            print("🔴 AFTER - isAuthenticated: \(authVM.isAuthenticated)")
                            print("🔴 AFTER - currentUser: \(authVM.currentUser?.email ?? "nil")")
                        }) {
                            Text("Log Out")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.cyan, lineWidth: 2)
                                        .background(Color.black.opacity(0.5))
                                )
                                .shadow(color: .blue, radius: 10)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                    .padding(.bottom, 80)
                }
            }
            .onAppear {
                print("👤 ProfileView appeared")
                print("👤 isAuthenticated: \(authVM.isAuthenticated)")
                print("👤 currentUser: \(authVM.currentUser?.email ?? "nil")")
                profileVM.loadProfile()
            }
        }
    }

    // MARK: - Display Helpers
    private var displayName: String {
        profileVM.username.isEmpty
        ? (profileVM.user?.email?.components(separatedBy: "@").first ?? "User")
        : profileVM.username
    }

    private var displayEmail: String {
        profileVM.email.isEmpty
        ? (profileVM.user?.email ?? "No email found")
        : profileVM.email
    }

    private var initials: String {
        let parts = displayName.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let last  = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (first + last).uppercased()
    }

    // MARK: - Avatar
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
                        .stroke(.cyan, lineWidth: 2)
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

    // MARK: - Section
    private var accountSection: some View {
        VStack(spacing: 0) {

            linkRow("Favorite Workshops", destination: FavoriteWorkshopsView())

            divider

            linkRow("Notification Settings", destination: NotificationSettingsView(profileVM:profileVM))

            divider

            linkRow("Change Password", destination: ChangePasswordView(authVM: authVM))

            divider

            linkRow("Privacy Policy", destination: PrivacyPolicyView())

            divider

            linkRow("About Us", destination: AboutUsView())
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

    // MARK: - Reusable Row
    private func linkRow<Destination: View>(_ title: String, destination: Destination) -> some View {
        NavigationLink {
            destination
        } label: {
            HStack {
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.cyan)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private var divider: some View {
        Divider()
            .background(Color.cyan.opacity(0.3))
            .padding(.leading, 16)
    }
}

// MARK: - Preview
#Preview {
    ProfileView(authVM: AuthenticationViewModel(context: PersistenceController.shared.container.viewContext))
}
