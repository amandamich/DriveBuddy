//
//  ChangePasswordView.swift
//  DriveBuddy
//
//  Created by Howie Homan on 04/11/25.
//
import SwiftUI
import CoreData

struct ChangePasswordView: View {
    @ObservedObject var authVM: AuthenticationViewModel
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var showingExitAlert = false
    @State private var showCurrentPassword = false
    @State private var showNewPassword = false
    @State private var showConfirmPassword = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // BACKGROUND - Matching Add Service style
            LinearGradient(colors: [.black, .black.opacity(0.9)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    // MARK: - Header
                    VStack(spacing: 8) {
                        Text("Change Password")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .blue, radius: 10)
                    }
                    .padding(.horizontal)

                    // SECTION HEADER - Matching Add Service style exactly
                    HStack(spacing: 10) {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 18))
                        Text("Security Settings")
                            .foregroundColor(.white)
                            .font(.system(size: 17, weight: .semibold))
                        Spacer()
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 1)
                    
                    // PASSWORD FIELDS - Matching Add Service Card style EXACTLY
                    VStack(spacing: 18) {
                        // Current Password
                        passwordFieldWithBorder(
                            title: "Current Password",
                            placeholder: "Enter current password",
                            text: $currentPassword,
                            showPassword: $showCurrentPassword
                        )
                        
                        // New Password with Requirements
                        VStack(alignment: .leading, spacing: 8) {
                            Text("New Password")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                            
                            HStack {
                                if showNewPassword {
                                    TextField("", text: $newPassword, prompt: Text("Enter new password").foregroundColor(.gray.opacity(0.5)))
                                        .foregroundColor(.black)
                                } else {
                                    SecureField("", text: $newPassword, prompt: Text("Enter new password").foregroundColor(.gray.opacity(0.5)))
                                        .foregroundColor(.black)
                                }
                                
                                Button(action: { showNewPassword.toggle() }) {
                                    Image(systemName: showNewPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .font(.system(size: 17))
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                            )
                            .cornerRadius(12)
                            
                            // ✅ Password Requirements Checklist
                            if !newPassword.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    PasswordRequirement(
                                        text: "8-20 characters",
                                        isMet: newPassword.count >= 8 && newPassword.count <= 20
                                    )
                                    PasswordRequirement(
                                        text: "At least one uppercase letter (A-Z)",
                                        isMet: newPassword.range(of: "[A-Z]", options: .regularExpression) != nil
                                    )
                                    PasswordRequirement(
                                        text: "At least one lowercase letter (a-z)",
                                        isMet: newPassword.range(of: "[a-z]", options: .regularExpression) != nil
                                    )
                                    PasswordRequirement(
                                        text: "At least one number (0-9)",
                                        isMet: newPassword.range(of: "[0-9]", options: .regularExpression) != nil
                                    )
                                }
                                .padding(.top, 8)
                            }
                        }
                        
                        // Confirm New Password with Match Indicator
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm New Password")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                            
                            HStack {
                                if showConfirmPassword {
                                    TextField("", text: $confirmPassword, prompt: Text("Re-enter new password").foregroundColor(.gray.opacity(0.5)))
                                        .foregroundColor(.black)
                                } else {
                                    SecureField("", text: $confirmPassword, prompt: Text("Re-enter new password").foregroundColor(.gray.opacity(0.5)))
                                        .foregroundColor(.black)
                                }
                                
                                Button(action: { showConfirmPassword.toggle() }) {
                                    Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .font(.system(size: 17))
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                            )
                            .cornerRadius(12)
                            
                            // ✅ Password Match Indicator
                            if !confirmPassword.isEmpty {
                                HStack {
                                    Image(systemName: newPassword == confirmPassword ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(newPassword == confirmPassword ? .green : .red)
                                    Text(newPassword == confirmPassword ? "Passwords match" : "Passwords do not match")
                                        .foregroundColor(newPassword == confirmPassword ? .green : .red)
                                        .font(.caption)
                                }
                                .padding(.top, 4)
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.blue.opacity(0.15))
                    )
                    .padding(.horizontal, 20)
                    
                    // SAVE BUTTON - Matching Edit Profile style
                    Button(action: handleChangePassword) {
                        Text("Save Password")
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
                    .padding(.top, 10)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showingExitAlert = true
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .semibold))
                }
            }
        }
        .alert("Confirm Exit", isPresented: $showingExitAlert) {
            Button("Stay on Page", role: .cancel) { }
            Button("Exit", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("Unsaved changes will be lost. Are you sure you want to exit?")
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Change Password"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    if alertMessage == "Password updated successfully." {
                        dismiss()
                    }
                }
            )
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - PASSWORD FIELD WITH BORDER (for Current Password only)
    private func passwordFieldWithBorder(title: String, placeholder: String, text: Binding<String>, showPassword: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
            
            HStack {
                if showPassword.wrappedValue {
                    TextField("", text: text, prompt: Text(placeholder).foregroundColor(.gray.opacity(0.5)))
                        .foregroundColor(.black)
                } else {
                    SecureField("", text: text, prompt: Text(placeholder).foregroundColor(.gray.opacity(0.5)))
                        .foregroundColor(.black)
                }
                
                Button(action: { showPassword.wrappedValue.toggle() }) {
                    Image(systemName: showPassword.wrappedValue ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .font(.system(size: 17))
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
            )
            .cornerRadius(12)
        }
    }
    
    // MARK: - ACTION
    private func handleChangePassword() {
        let success = authVM.changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
            confirmPassword: confirmPassword
        )
        if success {
            alertMessage = "Password updated successfully."
            currentPassword = ""
            newPassword = ""
            confirmPassword = ""
        } else {
            alertMessage = authVM.errorMessage ?? "Failed to change password."
        }
        showAlert = true
    }
}

// MARK: - PREVIEW
#Preview {
    let context = PersistenceController.preview.container.viewContext
    return ChangePasswordView(authVM: AuthenticationViewModel(context: context))
        .preferredColorScheme(.dark)
}
