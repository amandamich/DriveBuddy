//
//  GoogleSignInView.swift
//  DriveBuddy
//
//  Created by student on 04/12/25.
//

import SwiftUI
import GoogleSignIn

struct GoogleSignInView: View {
    @StateObject private var viewModel = GoogleSignInViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.95).ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // App Logo/Title
                VStack(spacing: 15) {
                    Image(systemName: "car.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.cyan)
                    
                    Text("DriveBuddy")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Track your vehicle maintenance")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Sign In Section
                if viewModel.isSignedIn {
                    // User is signed in - Show profile
                    VStack(spacing: 20) {
                        if let profileImageURL = viewModel.userProfile?.imageURL(withDimension: 120) {
                            AsyncImage(url: profileImageURL) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.cyan, lineWidth: 3)
                            )
                        }
                        
                        Text("Welcome!")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        Text(viewModel.userName)
                            .font(.headline)
                            .foregroundColor(.cyan)
                        
                        Text(viewModel.userEmail)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        // Continue Button
                        Button(action: {
                            // Navigate to main app
                            dismiss()
                        }) {
                            Text("Continue to App")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.cyan, lineWidth: 2)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.cyan.opacity(0.2))
                                        )
                                )
                        }
                        .padding(.horizontal, 40)
                        .padding(.top, 20)
                        
                        // Sign Out Button
                        Button(action: {
                            viewModel.signOut()
                        }) {
                            Text("Sign Out")
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                        .padding(.top, 10)
                    }
                } else {
                    // User not signed in - Show sign in button
                    VStack(spacing: 20) {
                        Text("Sign in to get started")
                            .font(.title3)
                            .foregroundColor(.white)
                        
                        // Google Sign-In Button
                        Button(action: {
                            viewModel.signIn()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "g.circle.fill")
                                    .font(.system(size: 24))
                                
                                Text("Sign in with Google")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.cyan, lineWidth: 2)
                                    .shadow(color: .cyan.opacity(0.5), radius: 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.black.opacity(0.5))
                                    )
                            )
                            .shadow(color: .cyan.opacity(0.3), radius: 10)
                        }
                        .padding(.horizontal, 40)
                        
                        // Error Message
                        if !viewModel.errorMessage.isEmpty {
                            Text(viewModel.errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        
                        // Privacy note
                        Text("By signing in, you agree to our Terms of Service and Privacy Policy")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding(.top, 20)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    GoogleSignInView()
}
