//
//  ContentView.swift
//  DriveBuddy
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var authVM: AuthenticationViewModel
    
    var body: some View {
        if authVM.isAuthenticated {
            // Show main app (Dashboard, etc.)
            DashboardView(authVM: authVM)
        } else {
            // Show login screen
            LoginView(authVM: authVM)
        }
    }
}

#Preview {
//    ContentView()
}
