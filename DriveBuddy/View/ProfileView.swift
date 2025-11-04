//
//  ProfileView.swift
//  DriveBuddy
//
//  Created by Howie Homan on 04/11/25.
//

import SwiftUI

struct ProfileView: View {
    @State private var addToCalendar = true
    @State private var isDarkMode = false
    
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
                        Text("Jonny Suh")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("jonny@gmail.com")
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
                                
                                Toggle("", isOn: $addToCalendar)
                                    .labelsHidden()
                                    .tint(.green)
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
                                
                                Toggle("", isOn: $isDarkMode)
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
                                PrivacyPolicyView()
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
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Placeholder Views
//struct ChangePasswordView: View {
//    var body: some View {
//        ZStack {
//            Color.black.opacity(0.95)
//                .ignoresSafeArea()
//            
//            VStack {
//                Text("Change Password")
//                    .font(.title)
//                    .foregroundColor(.white)
//            }
//        }
//        .navigationBarTitleDisplayMode(.inline)
//    }
//}

// MARK: - Placeholder Views
struct PrivacyPolicyView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.95)
                .ignoresSafeArea()
            
            VStack {
                Text("Privacy Policy")
                    .font(.title)
                    .foregroundColor(.white)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ProfileView()
}
