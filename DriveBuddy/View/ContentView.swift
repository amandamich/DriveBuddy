//
//  ContentView.swift
//  DriveBuddy
//

import SwiftUI
import CoreData

struct ContentView: View {
    @ObservedObject var authVM: AuthenticationViewModel
    @StateObject private var appState = AppState()
    
    // ✅ Track if we've checked for saved session
    @State private var hasCheckedSession = false

    var body: some View {
        Group {
            if !hasCheckedSession {
                // ✅ Show loading while checking session
                ZStack {
                    Color.black.ignoresSafeArea()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .cyan))
                        .scaleEffect(1.5)
                }
            } else if authVM.isAuthenticated {
                // ✅ User IS logged in → show HomeView (your actual TabView)
                HomeView(authVM: authVM)
                    .environmentObject(appState)
            } else {
                // ✅ User NOT logged in → show StartScreen
                NavigationStack {
                    StartScreen()
                        .environmentObject(authVM)
                }
            }
        }
        .onAppear {
            // ✅ CRITICAL: Restore session when app launches
            if !hasCheckedSession {
                print("📱 ContentView appeared - checking for saved session...")
                authVM.restoreSession()
                print("✅ Session check complete - isAuthenticated: \(authVM.isAuthenticated)")
                
                // Small delay to ensure state is updated
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    hasCheckedSession = true
                }
            }
        }
        .onChange(of: authVM.isAuthenticated) { oldValue, newValue in
            print("🔄 ContentView detected auth change: \(oldValue) -> \(newValue)")
        }
    }
}

#Preview {
    let context = PersistenceController.shared.container.viewContext
    let mockAuth = AuthenticationViewModel(context: context)
    return ContentView(authVM: mockAuth)
}
