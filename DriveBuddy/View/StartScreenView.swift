//
//  StartScreen.swift
//  DriveBuddy
//
//  Created by Timothy on 30/10/25.
//

import SwiftUI

struct StartScreen: View {
	@State private var isActive = false
	@State private var fadeOut = false
	@State private var isAnimating = false
	
	var body: some View {
		ZStack {
			Image("bgSplash")
				.resizable()
				.scaledToFill()
				.ignoresSafeArea()
				.overlay(Color.black.opacity(0.6))
				.opacity(fadeOut ? 0 : 1)
				.animation(.easeIn(duration: 1), value: fadeOut)
			
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
				
				VStack (spacing: 20){
					Button(action: {
						withAnimation(.easeInOut(duration: 0.3)) {
							isAnimating.toggle()
						}
					}) {
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
					
					Button(action: {
						withAnimation(.easeInOut(duration: 0.3)) {
							isAnimating.toggle()
						}
					}) {
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
//							.shadow(color: .blue, radius: 10)
					}
				}
			}
			
		
		
		}
		
	}
}

#Preview {
    StartScreen()
}
