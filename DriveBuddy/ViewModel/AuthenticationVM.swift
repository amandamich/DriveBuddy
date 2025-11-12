//
//  AuthenticationVM.swift
//  DriveBuddy
//

import Foundation
import CoreData
import SwiftUI
import Combine
import CryptoKit

@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    @Published var errorMessage: String?

    let viewContext: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }

    // MARK: - Sign Up
    func signUp() {
        errorMessage = nil

        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password."
            return
        }

        let request: NSFetchRequest<User> = User.fetchRequest()
        request.predicate = NSPredicate(format: "email == %@", email.lowercased())

        do {
            let users = try viewContext.fetch(request)
            if users.isEmpty {
                let newUser = User(context: viewContext)
                newUser.user_id = UUID()
                newUser.email = email.lowercased()
                newUser.password_hash = hash(password)
                newUser.add_to_calendar = false
                newUser.created_at = Date()

                try viewContext.save()

                // ✅ Tidak langsung login:
                currentUser = nil
                isAuthenticated = false
                errorMessage = nil
            } else {
                errorMessage = "Email already registered."
            }
        } catch {
            errorMessage = "Error creating account: \(error.localizedDescription)"
        }
    }


    // MARK: - Login
    func login() {
        errorMessage = nil

        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }

        let request: NSFetchRequest<User> = User.fetchRequest()
        request.predicate = NSPredicate(format: "email == %@", email.lowercased())

        do {
            let users = try viewContext.fetch(request)
            if let user = users.first {
                if user.password_hash == hash(password) {
                    currentUser = user
                    isAuthenticated = true
                    errorMessage = nil
                } else {
                    errorMessage = "Invalid email or password."
                }
            } else {
                errorMessage = "Invalid email or password."
            }
        } catch {
            errorMessage = "Login failed: \(error.localizedDescription)"
        }
    }
    // Validate Email
    func validateEmail(_ email: String) -> Bool {
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
            let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
            return emailPredicate.evaluate(with: email)
        }

    // MARK: - Logout
    func logout() {
        isAuthenticated = false
        currentUser = nil
        email = ""
        password = ""
    }

    // MARK: - Hashing
    private func hash(_ input: String) -> String {
        let data = Data(input.utf8)
        let hashed = SHA256.hash(data: data)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}
