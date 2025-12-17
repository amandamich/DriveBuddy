//
//  AuthenticationViewModel.swift
//  DriveBuddy
//

import Foundation
import CoreData
import SwiftUI
import Combine
import CryptoKit
import GoogleSignIn

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
    
    // ✅ NEW: Helper to get user-specific key
    private func userKey(_ baseKey: String, userId: String) -> String {
        return "\(userId).\(baseKey)"
    }

    // MARK: - Password Validation
    func validatePassword(_ password: String) -> (isValid: Bool, message: String?) {
        guard password.count >= 8 else {
            return (false, "Password must be at least 8 characters")
        }
        
        guard password.count <= 20 else {
            return (false, "Password must not exceed 20 characters")
        }
        
        let uppercaseRegex = ".*[A-Z]+.*"
        let uppercasePredicate = NSPredicate(format: "SELF MATCHES %@", uppercaseRegex)
        guard uppercasePredicate.evaluate(with: password) else {
            return (false, "Password must contain at least one uppercase letter")
        }
        
        let lowercaseRegex = ".*[a-z]+.*"
        let lowercasePredicate = NSPredicate(format: "SELF MATCHES %@", lowercaseRegex)
        guard lowercasePredicate.evaluate(with: password) else {
            return (false, "Password must contain at least one lowercase letter")
        }
        
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

    // MARK: - Sign Up
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
                
                // ✅ MODIFIED: Store phone number with user-specific key
                if !phoneNumber.isEmpty {
                    newUser.phone_number = phoneNumber
                    let userIdString = newUserID.uuidString
                    UserDefaults.standard.set(phoneNumber, forKey: userKey("profile.phoneNumber", userId: userIdString))
                }
                
                // ✅ MODIFIED: Mark as email sign-up user with user-specific key
                let userIdString = newUserID.uuidString
                UserDefaults.standard.set(false, forKey: userKey("profile.isGoogleUser", userId: userIdString))
                print("📧 Email sign-up user created with phone: \(phoneNumber) for user: \(userIdString)")

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

    // MARK: - Login (Manual)
    // ✅ 4. ENSURE YOUR LOGIN METHOD CALLS setCurrentUser()
    func login() {
        print("🟢 LOGIN CALLED (Manual)")
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
                    
                    // Mark as email user
                    if let userId = user.user_id?.uuidString {
                        UserDefaults.standard.set(false, forKey: "\(userId).profile.isGoogleUser")
                    }
                    
                    // ✅ CRITICAL: This saves the session
                    setCurrentUser(user)
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
            errorMessage = "Login failed: An internal error occurred."
            isAuthenticated = false
        }
    }
    // ✅ 5. ENSURE YOUR GOOGLE SIGN-IN METHOD CALLS setCurrentUser()
    func signInWithGoogle(email: String, name: String) {
        print("🟢 GOOGLE SIGN-IN CALLED for: \(email)")
        errorMessage = nil
        
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.predicate = NSPredicate(format: "email == %@", email.lowercased())
        
        do {
            let users = try viewContext.fetch(request)
            
            if let existingUser = users.first {
                print("🟢 Existing Google user found")
                viewContext.refresh(existingUser, mergeChanges: false)
                
                // Mark as Google user
                if let userId = existingUser.user_id?.uuidString {
                    UserDefaults.standard.set(true, forKey: "\(userId).profile.isGoogleUser")
                }
                
                // ✅ CRITICAL: This saves the session
                setCurrentUser(existingUser)
            } else {
                print("🟡 Creating new Google user")
                let newUser = User(context: viewContext)
                let newUserID = UUID()
                
                newUser.user_id = newUserID
                newUser.email = email.lowercased()
                newUser.password_hash = ""
                newUser.add_to_calendar = false
                newUser.created_at = Date()
                
                try viewContext.save()
                try viewContext.obtainPermanentIDs(for: [newUser])
                
                // Mark as Google user
                let userIdString = newUserID.uuidString
                UserDefaults.standard.set(true, forKey: "\(userIdString).profile.isGoogleUser")
                
                // ✅ CRITICAL: This saves the session
                setCurrentUser(newUser)
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.objectWillChange.send()
            }
            
        } catch {
            print("🔴 Google Sign-In Error: \(error)")
            errorMessage = "Google sign-in failed: \(error.localizedDescription)"
            isAuthenticated = false
        }
    }

    
    // ✅ 1. CENTRALIZED METHOD TO SET CURRENT USER (should already exist)
    private func setCurrentUser(_ user: User) {
        // Refresh the object from context to ensure it's not stale
        viewContext.refresh(user, mergeChanges: true)
        
        // Update all state properties
        self.currentUser = user
        self.currentUserID = user.user_id?.uuidString
        self.isAuthenticated = true
        self.errorMessage = nil
        
        // ✅ CRITICAL: Save to UserDefaults for session persistence
        if let userId = user.user_id?.uuidString {
            UserDefaults.standard.set(userId, forKey: "currentUserId")
            UserDefaults.standard.set(true, forKey: "isLoggedIn")
            UserDefaults.standard.synchronize()
            print("💾 Session saved to UserDefaults:")
            print("   - currentUserId: \(userId)")
            print("   - isLoggedIn: true")
        }
        
        // Post login notification
        NotificationCenter.default.post(name: .userDidLogin, object: nil)
        
        print("✅ User authenticated:")
        print("   - Email: \(user.email ?? "nil")")
        print("   - User ID: \(self.currentUserID ?? "nil")")
        print("   - isAuthenticated: \(self.isAuthenticated)")
    }
    // ✅ 2. RESTORE SESSION FROM USERDEFAULTS
    func restoreSession() {
        print("🔍 Attempting to restore session...")
        
        // Check if there's a saved user ID
        guard let savedUserId = UserDefaults.standard.string(forKey: "currentUserId") else {
            print("⚠️ No saved session found (no currentUserId)")
            self.isAuthenticated = false
            return
        }
        
        print("📱 Found saved userId: \(savedUserId)")
        
        guard let uuid = UUID(uuidString: savedUserId) else {
            print("❌ Invalid UUID format")
            self.isAuthenticated = false
            return
        }
        
        // Fetch user from Core Data
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.predicate = NSPredicate(format: "user_id == %@", uuid as CVarArg)
        
        do {
            if let user = try viewContext.fetch(request).first {
                print("✅ Session restored for: \(user.email ?? "unknown")")
                
                // Check if user has password (email user) or not (Google user)
                let isGoogleUser = user.password_hash?.isEmpty ?? true
                if let userId = user.user_id?.uuidString {
                    UserDefaults.standard.set(isGoogleUser, forKey: "\(userId).profile.isGoogleUser")
                    print("📱 Restored session - isGoogleUser: \(isGoogleUser)")
                }
                
                setCurrentUser(user)
            } else {
                print("⚠️ User not found in database, clearing session")
                UserDefaults.standard.removeObject(forKey: "currentUserId")
                UserDefaults.standard.removeObject(forKey: "isLoggedIn")
                self.isAuthenticated = false
            }
        } catch {
            print("❌ Failed to restore session: \(error)")
            self.isAuthenticated = false
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
    // ✅ 3. LOGOUT METHOD (update to clear session)
    func logout() {
        print("🔴 LOGOUT CALLED")
        print("🔴 Before logout - isAuthenticated: \(isAuthenticated)")
        
        let userToLogout = self.currentUser
        
        // Clear all authentication state
        self.isAuthenticated = false
        self.currentUser = nil
        self.currentUserID = nil
        self.email = ""
        self.password = ""
        self.errorMessage = nil
        
        // ✅ CRITICAL: Clear UserDefaults session data
        UserDefaults.standard.removeObject(forKey: "isLoggedIn")
        UserDefaults.standard.removeObject(forKey: "currentUserId")
        UserDefaults.standard.synchronize()
        
        print("💾 Session cleared from UserDefaults")
        
        // Refresh Core Data object
        if let user = userToLogout {
            viewContext.refresh(user, mergeChanges: false)
        }
        
        // Post logout notification
        NotificationCenter.default.post(name: .userDidLogout, object: nil)
        
        print("✅ User logged out successfully")
        
        // Force UI update
        DispatchQueue.main.async { [weak self] in
            self?.objectWillChange.send()
        }
    }
    
    // MARK: - Check Authentication
    func checkAuthenticationState() {
        print("🔍 Current Authentication State:")
        print("   - isAuthenticated: \(isAuthenticated)")
        print("   - currentUser: \(currentUser?.email ?? "nil")")
        print("   - currentUserID: \(currentUserID ?? "nil")")
        print("   - UserDefaults isLoggedIn: \(UserDefaults.standard.bool(forKey: "isLoggedIn"))")
        print("   - UserDefaults userId: \(UserDefaults.standard.string(forKey: "currentUserId") ?? "nil")")
        
        if let userId = currentUserID {
            let isGoogle = UserDefaults.standard.bool(forKey: userKey("profile.isGoogleUser", userId: userId))
            print("   - isGoogleUser: \(isGoogle)")
        }
    }
    
    // MARK: - Hashing
    private func hash(_ input: String) -> String {
        let data = Data(input.utf8)
        let hashed = SHA256.hash(data: data)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}
