//
//  ContentView.swift
//  DriveBuddy
//

import SwiftUI
import CoreData

struct ContentView: View {

    @StateObject private var authVM: AuthenticationViewModel

    init() {
        let context = PersistenceController.shared.container.viewContext
        _authVM = StateObject(wrappedValue: AuthenticationViewModel(context: context))
    }

    var body: some View {
        Group {
            if authVM.isAuthenticated {
                
                HomeView(authVM: authVM)
            } else {
            
                SplashView(authVM: authVM)
            }
        }
    }
}

        
        #Preview {
            ContentView()
        }

