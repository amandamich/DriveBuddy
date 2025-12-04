//
//  GoogleSign-InVM.swift
//  DriveBuddy
//
//  Created by student on 04/12/25.
//

import Foundation
import GoogleSignIn
import SwiftUI
import Combine
//TESTTTTTTTTTTT
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
        }
    }
    
    func signIn() {
        guard let presentingViewController = getRootViewController() else {
            errorMessage = "Unable to get root view controller"
            return
        }
        
        // Get client ID from GoogleService-Info.plist
        guard let clientID = getClientID() else {
            errorMessage = "Unable to get client ID from GoogleService-Info.plist"
            return
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                print("Google Sign-In Error: \(error.localizedDescription)")
                return
            }
            
            guard let user = result?.user else {
                self.errorMessage = "Unable to get user"
                return
            }
            
            self.isSignedIn = true
            self.userProfile = user.profile
            self.userEmail = user.profile?.email ?? ""
            self.userName = user.profile?.name ?? ""
            self.errorMessage = ""
            
            print("✅ Successfully signed in as: \(self.userName)")
            print("📧 Email: \(self.userEmail)")
        }
    }
    
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        isSignedIn = false
        userProfile = nil
        userEmail = ""
        userName = ""
        errorMessage = ""
        print("👋 User signed out")
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
