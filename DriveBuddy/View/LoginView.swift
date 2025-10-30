import SwiftUI

// MARK: - Custom Neon TextField Style
struct NeonTextFieldStyle: TextFieldStyle {
	func _body(configuration: TextField<Self._Label>) -> some View {
		configuration
			.padding()
			.foregroundColor(.black)
			.background(Color.white)
			.overlay(
				RoundedRectangle(cornerRadius: 12)
					.stroke(Color.cyan, lineWidth: 2)
					.shadow(color: .blue, radius: 8)
			)
			.cornerRadius(12)
			.shadow(color: .blue.opacity(0.3), radius: 10)
	}
}

// MARK: - Main Login View
struct LoginView: View {
	@State private var email = ""
	@State private var password = ""
	@State private var isAnimating = false

	var body: some View {
		ZStack {
			// Background gradient
//			LinearGradient(
//				gradient: Gradient(colors: [.black, .blue.opacity(0.25)]),
//				startPoint: .top,
//				endPoint: .bottom
//			)
//			.ignoresSafeArea()
			
			
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
						Text("LOGIN")
							.font(.system(size: 36, weight: .bold, design: .rounded))
//							.position(x:160, y:150)
							.foregroundColor(.white)
							.shadow(color: .blue, radius: 10)
						// Username field
						VStack(alignment: .leading, spacing: 8) {
							Text("Email")
								.foregroundColor(.white)
								.font(.headline)
								.shadow(color: .blue, radius: 5)
							TextField("Enter your email", text: $email)
								.textFieldStyle(NeonTextFieldStyle())
						}

						// Password field
						VStack(alignment: .leading, spacing: 8) {
							  Text("Password")
								  .foregroundColor(.white)
								  .font(.headline)
								  .shadow(color: .blue, radius: 5)
							  SecureField("Enter your password", text: $password)
								.textFieldStyle(NeonTextFieldStyle())
						}.padding(.bottom, 20)

						// Login button
						Button(action: {
							withAnimation(.easeInOut(duration: 0.3)) {
								isAnimating.toggle()
							}
						}) {
							Text("LOGIN")
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

					}.position(x: 160, y: 250)
					
					VStack{
						Image("MascotDriveBuddy").resizable().scaledToFit().frame(width: 250).padding(.top, 450).offset(x:80, y:85)
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
	LoginView()
}
