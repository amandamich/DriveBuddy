//
//  StartScreen.swift
//  DriveBuddy
//

import SwiftUI
import CoreData

struct StartScreen: View {
    @State private var isActive = false
    @State private var fadeOut = false
    @State private var isAnimating = false

    // Create Core Data context and Authentication ViewModel
    private let viewContext = PersistenceController.shared.container.viewContext
    @StateObject private var authVM = AuthenticationViewModel(context: PersistenceController.shared.container.viewContext)

    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Background
                Image("bgSplash")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .overlay(Color.black.opacity(0.6))
                    .opacity(fadeOut ? 0 : 1)
                    .animation(.easeIn(duration: 1), value: fadeOut)

                // MARK: - Content
                VStack {
                    Spacer()

                    // Logo
                    VStack(spacing: 10) {
                        Image("LogoDriveBuddy")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300, height: 300)
                            .foregroundColor(.white)
                            .shadow(radius: 10)
                    }

                    Spacer()

                    // MARK: - Buttons
                    VStack(spacing: 20) {
                        NavigationLink(destination: SignUpView(authVM: authVM)) {
                            Text("Sign Up")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(width: 350)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.cyan, lineWidth: 2)
                                        .shadow(color: .blue, radius: 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.black.opacity(0.5))
                                        )
                                )
                                .shadow(color: .blue, radius: 10)
                        }

                        NavigationLink(destination: LoginView(authVM: authVM)) {
                            Text("Log In")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(width: 350)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white, lineWidth: 2)
                                        .shadow(color: .blue, radius: 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.black.opacity(0.5))
                                        )
                                )
						}.padding(.bottom, 20)
                    }
                }
                .onAppear {
                    withAnimation {
                        isAnimating = true
                    }
                }
            }
            .navigationTitle("")
            .navigationBarBackButtonHidden(true)
        }
    }
}

#Preview {
    StartScreen()
}

