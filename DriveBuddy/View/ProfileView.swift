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
                Color.black.opacity(0.95)
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    // MARK: - Header
                    HStack(spacing: 12) {
                        Image(systemName: "car.fill")
                            .font(.title2)
                            .foregroundColor(.white)

                        Text("DriveBuddy")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)

                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .padding(.bottom, 40)

                    // MARK: - Profile Title
                    Text("Profile")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .padding(.bottom, 8)

                    // MARK: - User Info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(profileVM.user?.email?.components(separatedBy: "@").first ?? "User")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white)

                        Text(profileVM.user?.email ?? "No email found")
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
                                .foregroundColor(.white)

                            Text("Settings")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 16)

                        VStack(spacing: 0) {
                            // Add to Calendar Toggle
                            HStack {
                                Text("Add to Calendar")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)

                                Spacer()

                                Toggle("", isOn: $profileVM.addToCalendar)
                                    .labelsHidden()
                                    .tint(.green)
                                    .onChange(of: profileVM.addToCalendar) {
                                        profileVM.toggleAddToCalendar(profileVM.addToCalendar)
                                    }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)

                            Divider()
                                .background(Color.white.opacity(0.15))
                                .padding(.leading, 16)

                            // Theme Toggle
                            HStack {
                                Text("Theme")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)

                                Spacer()

                                Toggle("", isOn: $profileVM.isDarkMode)
                                    .labelsHidden()
                                    .tint(.blue)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 0.08, green: 0.16, blue: 0.32))
                        )
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 24)
                    // MARK: - Account Section
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 12) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                            
                            Text("Account")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                        
                        VStack(spacing: 0) {
                            // Change Password
                            NavigationLink {
                                ChangePasswordView()
                            } label: {
                                HStack {
                                    Text("Change Password")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.gray)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                            
                            Divider()
                                .background(Color.white.opacity(0.15))
                                .padding(.leading, 16)
                            
                            // Privacy Policy
                            NavigationLink {
                                
                            } label: {
                                HStack {
                                    Text("Privacy Policy")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.gray)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 0.08, green: 0.16, blue: 0.32))
                        )
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 24)

                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }
}


#Preview {
    let context = PersistenceController.shared.container.viewContext
    let mockUser = User(context: context)
    mockUser.email = "preview@drivebuddy.com"
    mockUser.add_to_calendar = true
    let mockAuthVM = AuthenticationViewModel(context: context)
    mockAuthVM.currentUser = mockUser
    return ProfileView(authVM: mockAuthVM)
    
}

