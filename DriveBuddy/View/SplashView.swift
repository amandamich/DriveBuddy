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
	@State private var logoRevealProgress: CGFloat = -100
	@State private var logoOpacity: Double = 0

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

					// Logo dengan animasi naik
					VStack(spacing: 10) {
						Image("LogoDriveBuddy")
							.resizable()
							.scaledToFit()
							.frame(width: 300, height: 300)
							.shadow(radius: 10)
							.opacity(logoOpacity)
//							.offset(x: logoRevealProgress) 
					}
					.offset(y: logoOffset)

					Spacer()

					// MARK: - Buttons
					if showButtons {
						VStack(spacing: 20) {
							NavigationLink(
								destination: SignUpView(authVM: authVM)
							) {
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
												RoundedRectangle(
													cornerRadius: 12
												)
												.fill(Color.black.opacity(0.5))
											)
									)
									.shadow(color: .blue, radius: 10)
							}

							NavigationLink(
								destination: LoginView(authVM: authVM)
							) {
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
												RoundedRectangle(
													cornerRadius: 12
												)
												.fill(Color.black.opacity(0.5))
											)
									)
							}
						}
						.padding(.bottom, 20)
						.opacity(buttonOpacity)
						.offset(y: showButtons ? 0 : 50)
					}
				}
				.onAppear {
					// Animasi reveal logo dari kiri ke kanan (slide + fade)
					withAnimation(.easeOut(duration: 1.0)) {
						logoRevealProgress = 0
						logoOpacity = 1
					}
					// Animasi logo naik setelah 1.5 detik
					DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
						withAnimation(
							.spring(response: 0.8, dampingFraction: 1.0)
						) {
							logoOffset = -150
						}

						// Tampilkan buttons setelah logo mulai naik
						DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
							showButtons = true
							withAnimation(.easeOut(duration: 0.6)) {
								buttonOpacity = 1
							}
						}
					}
				}
			}
			.navigationTitle("")
			.navigationBarBackButtonHidden(true)
		}
	}
}

#Preview {
	SplashView()
}
