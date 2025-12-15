//
//  ContentView.swift
//  DriveBuddy
//

import SwiftUI
import CoreData
struct ContentView: View {
    @ObservedObject var authVM: AuthenticationViewModel
    @StateObject private var appState = AppState()

    var body: some View {
        Group {
            if authVM.isAuthenticated {
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
        .onChange(of: authVM.isAuthenticated) { oldValue, newValue in
            print("🔄 ContentView detected auth change: \(oldValue) -> \(newValue)")
            if !newValue {
                print("🔄 Switching to StartScreen...")
            } else {
                print("🔄 Switching to HomeView...")
            }
        }
    }
}

#Preview {
    let context = PersistenceController.shared.container.viewContext
    let mockAuth = AuthenticationViewModel(context: context)
    return ContentView(authVM: mockAuth)
}
