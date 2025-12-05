//
//  AuthenticationViewModel.swift
//  DriveBuddy
//

import Foundation
import CoreData
import SwiftUI
import Combine
import CryptoKit

@MainActor
final class AuthenticationViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isAuthenticated: Bool = false
    @Published var errorMessage: String?
    @Published var currentUser: User?
    @Published var currentUserID: String?
    
    let viewContext: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }

    // MARK: - Password Validation
    func validatePassword(_ password: String) -> (isValid: Bool, message: String?) {
        // Check length (8-20 characters)
        guard password.count >= 8 else {
            return (false, "Password must be at least 8 characters")
        }
        
        guard password.count <= 20 else {
            return (false, "Password must not exceed 20 characters")
        }
        
        // Check for uppercase letter
        let uppercaseRegex = ".*[A-Z]+.*"
        let uppercasePredicate = NSPredicate(format: "SELF MATCHES %@", uppercaseRegex)
        guard uppercasePredicate.evaluate(with: password) else {
            return (false, "Password must contain at least one uppercase letter")
        }
        
        // Check for lowercase letter
        let lowercaseRegex = ".*[a-z]+.*"
        let lowercasePredicate = NSPredicate(format: "SELF MATCHES %@", lowercaseRegex)
        guard lowercasePredicate.evaluate(with: password) else {
            return (false, "Password must contain at least one lowercase letter")
        }
        
        // Check for number
        let numberRegex = ".*[0-9]+.*"
        let numberPredicate = NSPredicate(format: "SELF MATCHES %@", numberRegex)
        guard numberPredicate.evaluate(with: password) else {
            return (false, "Password must contain at least one number")
        }
        
        return (true, nil)
    }
    
    // MARK: - Get Password Strength
    func getPasswordStrength(_ password: String) -> (strength: String, color: Color) {
        var score = 0
        
        if password.count >= 8 { score += 1 }
        if password.count >= 12 { score += 1 }
        if password.range(of: "[A-Z]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[a-z]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[0-9]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil { score += 1 }
        
        switch score {
        case 0...2:
            return ("Weak", .red)
        case 3...4:
            return ("Medium", .orange)
        case 5...6:
            return ("Strong", .green)
        default:
            return ("Weak", .red)
        }
    }

    // MARK: - Sign Up (UPDATED)
    func signUp(phoneNumber: String = "") {
        errorMessage = nil

        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password."
            return
        }
        
        guard validateEmail(email) else {
            errorMessage = "Invalid email format."
            return
        }
        
        let passwordValidation = validatePassword(password)
        guard passwordValidation.isValid else {
            errorMessage = passwordValidation.message
            return
        }

        let request: NSFetchRequest<User> = User.fetchRequest()
        request.predicate = NSPredicate(format: "email == %@", email.lowercased())

        do {
            let users = try viewContext.fetch(request)
            if users.isEmpty {
                let newUser = User(context: viewContext)
                let newUserID = UUID()
                
                newUser.user_id = newUserID
                newUser.email = email.lowercased()
                newUser.password_hash = hash(password)
                newUser.add_to_calendar = false
                newUser.created_at = Date()
                
                // ✅ NEW: Save phone number
                if !phoneNumber.isEmpty {
                    newUser.phone_number = phoneNumber
                }

                try viewContext.save()

                errorMessage = "Registration successful! Please login."
                
                currentUser = nil
                isAuthenticated = false
                currentUserID = nil
            } else {
                errorMessage = "Email already registered."
            }
        } catch {
            errorMessage = "Error creating account: \(error.localizedDescription)"
        }
    }

    // MARK: - Login
    func login() {
        print("🟢 LOGIN CALLED")
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
                    print("🟢 Login successful for: \(user.email ?? "unknown")")
                    
                    self.currentUser = user
                    self.currentUserID = user.user_id?.uuidString
                    self.isAuthenticated = true
                    self.errorMessage = nil
                    
                    print("🟢 isAuthenticated set to: \(self.isAuthenticated)")
                    print("🟢 currentUser: \(self.currentUser?.email ?? "nil")")
                    
                    self.objectWillChange.send()
                    
                } else {
                    print("🔴 Password incorrect")
                    errorMessage = "Invalid email or password."
                    isAuthenticated = false
                }
            } else {
                print("🔴 User not found")
                errorMessage = "User not found. Please sign up first."
                isAuthenticated = false
            }
        } catch {
            print("🔴 Core Data Fetch Error: \(error)")
            errorMessage = "Login failed: An internal error occurred. Please try again later."
            isAuthenticated = false
        }
    }
    
    // MARK: - Validate Email
    func validateEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    // MARK: - Change Password
    func changePassword(
        currentPassword: String,
        newPassword: String,
        confirmPassword: String
    ) -> Bool {
        errorMessage = nil

        guard let user = currentUser else {
            errorMessage = "No user is logged in."
            return false
        }

        guard !currentPassword.isEmpty,
              !newPassword.isEmpty,
              !confirmPassword.isEmpty else {
            errorMessage = "Please fill in all fields."
            return false
        }

        let currentHash = hash(currentPassword)
        guard user.password_hash == currentHash else {
            errorMessage = "Current password is incorrect."
            return false
        }

        guard newPassword == confirmPassword else {
            errorMessage = "New password and confirmation do not match."
            return false
        }

        // ✅ Validate new password with enhanced rules
        let passwordValidation = validatePassword(newPassword)
        guard passwordValidation.isValid else {
            errorMessage = passwordValidation.message
            return false
        }

        user.password_hash = hash(newPassword)

        do {
            try viewContext.save()
            password = ""
            return true
        } catch {
            errorMessage = "Failed to update password: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Logout
    func logout() {
        print("🔴 LOGOUT CALLED")
        print("🔴 Before logout - isAuthenticated: \(isAuthenticated)")
        print("🔴 Before logout - currentUser: \(currentUser?.email ?? "nil")")
        
        self.isAuthenticated = false
        self.currentUser = nil
        self.currentUserID = nil
        self.email = ""
        self.password = ""
        self.errorMessage = nil
        
        UserDefaults.standard.removeObject(forKey: "isLoggedIn")
        UserDefaults.standard.removeObject(forKey: "currentUserId")
        UserDefaults.standard.synchronize()
        
        print("🔴 After logout - isAuthenticated: \(isAuthenticated)")
        print("🔴 After logout - currentUser: \(currentUser?.email ?? "nil")")
        print("✅ User logged out successfully")
        
        objectWillChange.send()
    }

    // MARK: - Hashing
    private func hash(_ input: String) -> String {
        let data = Data(input.utf8)
        let hashed = SHA256.hash(data: data)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}
