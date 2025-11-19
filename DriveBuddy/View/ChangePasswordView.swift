//
//  ChangePasswordView.swift
//  DriveBuddy
//
//  Created by Howie Homan on 04/11/25.
//

import SwiftUI
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
            Color("BackgroundPrimary")
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                Text("Change Password")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color("TextPrimary"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)

                VStack(spacing: 16) {
                    passwordField(
                        title: "Current Password",
                        text: $currentPassword
                    )

                    passwordField(
                        title: "New Password",
                        text: $newPassword
                    )

                    passwordField(
                        title: "Confirm New Password",
                        text: $confirmPassword
                    )
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color("CardBackground"))
                )

                Spacer()

                // Save Button (glow style seperti Add Service / Login)
                Button(action: {
                    let success = authVM.changePassword(
                        currentPassword: currentPassword,
                        newPassword: newPassword,
                        confirmPassword: confirmPassword
                    )

                    if success {
                        alertMessage = "Password updated successfully."
                        // reset field
                        currentPassword = ""
                        newPassword = ""
                        confirmPassword = ""
                    } else {
                        alertMessage = authVM.errorMessage ?? "Failed to change password."
                    }

                    showAlert = true
                }) {
                    Text("Save Password")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.cyan, lineWidth: 2)
                                .shadow(color: .blue, radius: 8)             // outline glow
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.black.opacity(0.5))      // inner fill
                                )
                        )
                        .shadow(color: .blue, radius: 10)                    // outer glow
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Change Password"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    // Kalau sukses, balik ke previous screen
                    if alertMessage == "Password updated successfully." {
                        dismiss()
                    }
                }
            )
        }
    }

    // MARK: - Reusable Password Field
    private func passwordField(
        title: String,
        text: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(Color("TextPrimary"))

            SecureField("Enter \(title.lowercased())", text: text)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.9))
                        .shadow(color: Color.cyan.opacity(0.4), radius: 6)
                )
        }
    }
}

// MARK: - Preview

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let authVM = AuthenticationViewModel(context: context)
    return ChangePasswordView(authVM: authVM)
}
