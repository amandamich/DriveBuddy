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
                        passwordFieldWithBorder(
                            title: "Current Password",
                            placeholder: "Enter current password",
                            text: $currentPassword
                        )
                        passwordFieldWithBorder(
                            title: "New Password",
                            placeholder: "Enter new password",
                            text: $newPassword
                        )
                        passwordFieldWithBorder(
                            title: "Confirm New Password",
                            placeholder: "Re-enter new password",
                            text: $confirmPassword
                        )
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.blue.opacity(0.15)) // EXACT same as Add Service
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
    
    // MARK: - PASSWORD FIELD WITH BORDER (Matching Add Service font sizes exactly)
    private func passwordFieldWithBorder(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
            
            SecureField("", text: text, prompt: Text(placeholder).foregroundColor(.gray.opacity(0.5)))
                .padding()
                .font(.system(size: 17))
                .foregroundColor(.black) // Black text for readability
                .background(Color.white) // White background
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.4), lineWidth: 1) // Gray border
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
