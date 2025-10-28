//
//  SignUpView.swift
//  DriveBuddy
//

import SwiftUI

struct SignUpView: View {
	@State private var email = ""
	@State private var phoneNumber = ""
	@State private var password = ""
	@State private var confirmpassword = ""
	@State private var isAnimating = false
    var body: some View {
		ZStack {
			
			Color.black.opacity(0.95).ignoresSafeArea()

			VStack{
				ZStack(alignment: .center){
					Circle()
						.fill(Color.blue.opacity(0.5))
						.position(x: 150, y: -270)
						.frame(width: 300, height: 300)
						.blur(radius: 80)
						.offset(y: isAnimating ? 30 : 30)
						.animation(
							Animation.easeInOut(duration: 1)
								.repeatForever(autoreverses: true),
							value: isAnimating
						)
					VStack(spacing: 30){
					// Title text in front
					Text("Sign Up")
						.font(.system(size: 36, weight: .bold, design: .rounded))
//						.position()
						.foregroundColor(.white)
						.shadow(color: .blue, radius: 10)
					
						// Email field
						VStack(alignment: .leading, spacing: 8) {
							Text("Email")
								.foregroundColor(.white)
								.font(.headline)
								.shadow(color: .blue, radius: 5)
							TextField("Enter your email", text: $email)
								.textFieldStyle(NeonTextFieldStyle())
						}

						// Phone Number field
						VStack(alignment: .leading, spacing: 8) {
							  Text("Phone Number")
								  .foregroundColor(.white)
								  .font(.headline)
								  .shadow(color: .blue, radius: 5)
							  SecureField("+62", text: $phoneNumber)
								.textFieldStyle(NeonTextFieldStyle())
						}
						
						// Password field
						VStack(alignment: .leading, spacing: 8) {
							  Text("Create a Password")
								  .foregroundColor(.white)
								  .font(.headline)
								  .shadow(color: .blue, radius: 5)
							  SecureField("Enter your password", text: $password)
								.textFieldStyle(NeonTextFieldStyle())
						}
						
						VStack(alignment: .leading, spacing: 8) {
							  Text("Confirm Password")
								  .foregroundColor(.white)
								  .font(.headline)
								  .shadow(color: .blue, radius: 5)
							  SecureField("Repeat your password", text: $confirmpassword)
								.textFieldStyle(NeonTextFieldStyle())
						}.padding(.bottom, 20)

						// Login button
						Button(action: {
							withAnimation(.easeInOut(duration: 0.3)) {
								isAnimating.toggle()
							}
						}) {
							Text("SIGN UP")
								.font(.headline)
								.foregroundColor(.white)
								.padding()
								.frame(maxWidth: .infinity)
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
						.padding(0)

					}
					
					
					
				}
				
				
			}
			.padding(.horizontal, 40)
		}
		.onAppear {
			withAnimation {
				isAnimating = true
			}
		}
	}
    
}

#Preview {
    SignUpView()
}
