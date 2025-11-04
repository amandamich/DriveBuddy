//
//  ChangePasswordView.swift
//  DriveBuddy
//
//  Created by Howie Homan on 04/11/25.
//

import SwiftUI

struct ChangePasswordView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmedPassword = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            // MARK: - Background
            Color.black.opacity(0.95)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Header with Back Button
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("Change Password")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Invisible spacer for centering
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.clear)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 40)
                
                // MARK: - Password Fields
                VStack(spacing: 24) {
                    // Current Password
                    SecureField("Current Password", text: $currentPassword)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                        )
                    
                    // New Password
                    SecureField("New Password", text: $newPassword)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                        )
                    
                    // Confirmed Password
                    SecureField("Confirmed Password", text: $confirmedPassword)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                        )
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
                
                // MARK: - Change Password Button
                Button(action: {
                    handlePasswordChange()
                }) {
                    Text("Change Password")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.blue]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                .padding(.horizontal, 32)
                
                // MARK: - Error Message
                if showError {
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(.top, 16)
                        .padding(.horizontal, 32)
                }
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Password Validation
    private func handlePasswordChange() {
        // Reset error
        showError = false
        errorMessage = ""
        
        // Validate fields
        guard !currentPassword.isEmpty else {
            showError = true
            errorMessage = "Please enter your current password"
            return
        }
        
        guard !newPassword.isEmpty else {
            showError = true
            errorMessage = "Please enter a new password"
            return
        }
        
        guard newPassword.count >= 6 else {
            showError = true
            errorMessage = "New password must be at least 6 characters"
            return
        }
        
        guard newPassword == confirmedPassword else {
            showError = true
            errorMessage = "Passwords do not match"
            return
        }
        
        // TODO: Implement actual password change logic with your backend
        // For now, simulate success
        print("Password changed successfully")
        dismiss()
    }
}

#Preview {
    NavigationStack {
        ChangePasswordView()
    }
}
