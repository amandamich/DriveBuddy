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

    private let viewContext: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.viewContext = context
        checkExistingSession()
    }
    // Sign Up
    func signUp() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password"
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

                currentUser = newUser
                isAuthenticated = true
                saveSession(user: newUser)
            } else {
                errorMessage = "Email already registered"
            }
        } catch {
            errorMessage = "Error creating account: \(error.localizedDescription)"
        }
    }

    // Login
    func login() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill all fields"
            return
        }

        let request: NSFetchRequest<User> = User.fetchRequest()
        request.predicate = NSPredicate(format: "email == %@", email.lowercased())

        do {
            let users = try viewContext.fetch(request)
            if let user = users.first, user.password_hash == hash(password) {
                currentUser = user
                isAuthenticated = true
                saveSession(user: user)
            } else {
                errorMessage = "Invalid email or password"
            }
        } catch {
            errorMessage = "Login failed: \(error.localizedDescription)"
        }
    }

    //Hashing (for demo only)
    private func hash(_ input: String) -> String {
        let data = Data(input.utf8)
        let hashed = SHA256.hash(data: data)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }

    // Session Handling
    private func saveSession(user: User) {
        UserDefaults.standard.set(user.user_id?.uuidString, forKey: "currentUserID")
    }

    private func checkExistingSession() {
        if let idString = UserDefaults.standard.string(forKey: "currentUserID"),
           let uuid = UUID(uuidString: idString) {
            let request: NSFetchRequest<User> = User.fetchRequest()
            request.predicate = NSPredicate(format: "user_id == %@", uuid as CVarArg)
            if let user = try? viewContext.fetch(request).first {
                currentUser = user
                isAuthenticated = true
            }
        }
    }
}
