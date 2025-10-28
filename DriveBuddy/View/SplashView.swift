//
//  SplashView.swift
//  DriveBuddy
//
//  Created by Timothy on 28/10/25.
//


import SwiftUI

struct SplashView: View {
    @State private var isActive = false
	@State private var fadeOut = false
    
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
                    
//                    Text("DriveBuddy")
//                        .font(.system(size: 28, weight: .semibold))
//                        .foregroundColor(.white)
//                        .shadow(color: .blue.opacity(0.4), radius: 5)
                }
                
                Spacer()
            }
			.opacity(fadeOut ? 0 : 1)
						.animation(.easeIn(duration: 0.8), value: fadeOut)
        }
        .onAppear {
			// Delay sebelum berpindah
		   DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
			   withAnimation(.easeIn(duration: 0.8)) {
				   fadeOut = true
			   }
			   DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
				   isActive = true
			   }
		   }
        }
        // Navigasi ke LoginView
        .fullScreenCover(isPresented: $isActive) {
            LoginView() .transition(.opacity.animation(.easeOut(duration: 0.8)))
        }
    }
}

#Preview {
    SplashView()
}
