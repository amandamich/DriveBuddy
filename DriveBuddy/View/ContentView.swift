//
//  ContentView.swift
//  DriveBuddy
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var authVM: AuthenticationViewModel

    var body: some View {
        NavigationStack {
            if authVM.isAuthenticated {
                // User ALREADY logged in → show LoginView (as you requested)
                LoginView(authVM: authVM)
            } else {
                // User NOT logged in → show Splash first
                SplashView()
            }
        }
    }
}

#Preview {
//    let context = PersistenceController.shared.container.viewContext
//    let mockAuth = AuthenticationViewModel(context: context)
//    return ContentView(authVM: mockAuth)
}
