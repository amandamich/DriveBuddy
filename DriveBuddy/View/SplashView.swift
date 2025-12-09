//
//  SplashView.swift
//  DriveBuddy
//

import CoreData
import SwiftUI

struct SplashView: View {
    @State private var logoOffset: CGFloat = 0
    @State private var showButtons = false
    @State private var buttonOpacity: Double = 0
    @State private var logoOpacity: Double = 0
    @State private var logoScale: CGFloat = 0.8
    
    // Create Core Data context and Authentication ViewModel
    private let viewContext = PersistenceController.shared.container.viewContext
    @StateObject private var authVM = AuthenticationViewModel(
        context: PersistenceController.shared.container.viewContext
    )
    
    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Background
                Image("bgSplash")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .overlay(Color.black.opacity(0.6))
                
                // MARK: - Content
                VStack {
                    Spacer()
                    
                    // Logo with animations
                    VStack(spacing: 10) {
                        Image("LogoDriveBuddy")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300, height: 300)
                            .shadow(color: .blue.opacity(0.5), radius: 20)
                            .opacity(logoOpacity)
                            .scaleEffect(logoScale)
                    }
                    .offset(y: logoOffset)
                    
                    Spacer()
                    
                    // MARK: - Buttons
                    if showButtons {
                        VStack(spacing: 20) {
                            // Sign Up Button
                            NavigationLink(
                                destination: SignUpView(authVM: authVM)
                            ) {
                                Text("Sign Up")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(width: 350)
                                    .background(
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.black.opacity(0.5))
                                            
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.cyan, lineWidth: 2)
                                        }
                                    )
                                    .shadow(color: .cyan.opacity(0.5), radius: 10)
                            }
                            
                            // Sign In Button
                            NavigationLink(
                                destination: LoginView(authVM: authVM)
                            ) {
                                Text("Sign In")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(width: 350)
                                    .background(
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.black.opacity(0.5))
                                            
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white, lineWidth: 2)
                                        }
                                    )
                                    .shadow(color: .white.opacity(0.3), radius: 8)
                            }
                        }
                        .padding(.bottom, 40)
                        .opacity(buttonOpacity)
                        .offset(y: showButtons ? 0 : 50)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarBackButtonHidden(true)
        }
        .task {
            // Using task instead of onAppear for more reliable animation triggering
            startAnimations()
        }
    }
    
    // MARK: - Animation Logic
    private func startAnimations() {
        // Small initial delay to ensure view is rendered
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Step 1: Fade in and scale up logo
            withAnimation(.easeOut(duration: 1.0)) {
                logoOpacity = 1
                logoScale = 1.0
            }
            
            // Step 2: Move logo up after 1.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                    logoOffset = -150
                }
                
                // Step 3: Show buttons with delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    showButtons = true
                    withAnimation(.easeOut(duration: 0.6)) {
                        buttonOpacity = 1
                    }
                }
            }
        }
    }
}

#Preview {
    SplashView()
}
