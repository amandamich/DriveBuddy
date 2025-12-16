import Foundation
import GoogleSignIn
import SwiftUI
import Combine

class GoogleSignInViewModel: ObservableObject {
    @Published var isSignedIn = false
    @Published var errorMessage = ""
    @Published var userProfile: GIDProfileData?
    @Published var userEmail: String = ""
    @Published var userName: String = ""
    
    init() {
        checkSignInStatus()
    }
    
    func checkSignInStatus() {
        if let currentUser = GIDSignIn.sharedInstance.currentUser {
            isSignedIn = true
            userProfile = currentUser.profile
            userEmail = currentUser.profile?.email ?? ""
            userName = currentUser.profile?.name ?? ""
            print("✅ Found existing Google session: \(userName)")
        }
    }
    
    func signIn() {
        print("🔵 GoogleSignInViewModel.signIn() called")
        
        // ✅ CRITICAL: Reset state before signing in
        self.isSignedIn = false
        self.errorMessage = ""
        
        guard let presentingViewController = getRootViewController() else {
            errorMessage = "Unable to get root view controller"
            print("🔴 Error: \(errorMessage)")
            return
        }
        
        // Get client ID from GoogleService-Info.plist
        guard let clientID = getClientID() else {
            errorMessage = "Unable to get client ID from GoogleService-Info.plist"
            print("🔴 Error: \(errorMessage)")
            return
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { [weak self] result, error in
            guard let self = self else { return }
            
            // ✅ Ensure updates happen on main thread
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.isSignedIn = false
                    print("🔴 Google Sign-In Error: \(error.localizedDescription)")
                    return
                }
                
                guard let user = result?.user else {
                    self.errorMessage = "Unable to get user"
                    self.isSignedIn = false
                    print("🔴 Error: No user returned")
                    return
                }
                
                // ✅ Update all properties
                self.userProfile = user.profile
                self.userEmail = user.profile?.email ?? ""
                self.userName = user.profile?.name ?? ""
                self.errorMessage = ""
                
                print("✅ Successfully signed in as: \(self.userName)")
                print("📧 Email: \(self.userEmail)")
                
                // ✅ NEW: Clear phone number for Google sign-in users
                UserDefaults.standard.removeObject(forKey: "profile.phoneNumber")
                print("📱 Phone number cleared for Google user")
                
                // ✅ CRITICAL: Set isSignedIn LAST to trigger onChange
                self.isSignedIn = true
                print("🟢 isSignedIn set to: \(self.isSignedIn)")
            }
        }
    }
    
    func signOut() {
        print("🔴 GoogleSignInViewModel.signOut() called")
        GIDSignIn.sharedInstance.signOut()
        
        // ✅ Reset all state
        isSignedIn = false
        userProfile = nil
        userEmail = ""
        userName = ""
        errorMessage = ""
        
        print("👋 Google user signed out completely")
    }
    
    private func getRootViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = scene.windows.first?.rootViewController else {
            return nil
        }
        return rootViewController
    }
    
    private func getClientID() -> String? {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientID = plist["CLIENT_ID"] as? String else {
            print("❌ Failed to get CLIENT_ID from GoogleService-Info.plist")
            return nil
        }
        print("✅ CLIENT_ID loaded successfully")
        return clientID
    }
}
