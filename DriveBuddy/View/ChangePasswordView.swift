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
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // BACKGROUND (dark theme)
            Color.black.opacity(0.95)
                .ignoresSafeArea()
            
//            FlowingLinesView()
//                .opacity(0.25)
//                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    // TITLE
                    Text("Change Password")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 10)
                    
                    // SECTION HEADER
                    HStack(spacing: 8) {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.cyan)
                            .font(.system(size: 18))
                        Text("Security Settings")
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                    .padding(.leading, 4)
                    
                    // CARD (mirip Add Service Card)
                    VStack(spacing: 20) {
                        passwordField(
                            title: "Current Password",
                            placeholder: "Enter current password",
                            text: $currentPassword
                        )
                        passwordField(
                            title: "New Password",
                            placeholder: "Enter new password",
                            text: $newPassword
                        )
                        passwordField(
                            title: "Confirm New Password",
                            placeholder: "Re-enter new password",
                            text: $confirmPassword
                        )
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color("CardDark"))  // gunakan warna biru gelap
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        LinearGradient(
                                            colors: [.cyan.opacity(0.4), .blue.opacity(0.3)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    )
                    
                    // SAVE BUTTON (Updated to match Add Service button style)
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
                            .padding(.top, 10)
                }
                .padding(20)
            }
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
    }
    
    // MARK: - CUSTOM PASSWORD FIELD
    private func passwordField(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .foregroundColor(.white.opacity(0.9))
                .font(.subheadline)
            SecureField(placeholder, text: text)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.08))
                .foregroundColor(.white)
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
