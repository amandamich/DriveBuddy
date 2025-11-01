import SwiftUI
import CoreData
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
    @ObservedObject var authVM: AuthenticationViewModel
        @State private var email = ""
        @State private var password = ""
        @State private var isAnimating = false

	var body: some View {
        NavigationStack {
                    ZStack {
                        // Background gradient
                        //            LinearGradient(
                        //                gradient: Gradient(colors: [.black, .blue.opacity(0.25)]),
                        //                startPoint: .top,
                        //                endPoint: .bottom
                        //            )
                        //            .ignoresSafeArea()
                        Color.black.opacity(0.95).ignoresSafeArea()

                        VStack {
                            ZStack(alignment: .center) {
                                // Glowing circle background
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

                                // MARK: - Main Content
                                VStack(spacing: 30) {
                                    // Title
                                    Text("LOGIN")
                                        .font(.system(size: 36, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .shadow(color: .blue, radius: 10)

                                    // Email Field
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Email")
                                            .foregroundColor(.white)
                                            .font(.headline)
                                            .shadow(color: .blue, radius: 5)
                                        TextField("Enter your email", text: $email)
                                            .textFieldStyle(NeonTextFieldStyle())
                                            .autocapitalization(.none)
                                    }

                                    // Password Field
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Password")
                                            .foregroundColor(.white)
                                            .font(.headline)
                                            .shadow(color: .blue, radius: 5)
                                        SecureField("Enter your password", text: $password)
                                            .textFieldStyle(NeonTextFieldStyle())
                                    }
                                    .padding(.bottom, 20)

                                    // MARK: - Login Button
                                    Button(action: {
                                        authVM.email = email
                                        authVM.password = password
                                        authVM.login()
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

                                    // MARK: - Error Message
                                    if let error = authVM.errorMessage {
                                        Text(error)
                                            .foregroundColor(.red)
                                            .font(.caption)
                                            .padding(.top, 8)
                                    }

                                    // MARK: - Navigate to Sign Up
                                    NavigationLink("Don't have an account? Sign Up") {
                                        SignUpView(authVM: authVM)
                                    }
                                    .foregroundColor(.cyan)
                                    .padding(.top, 10)
                                }
                                .position(x: 160, y: 250)

                                // Mascot image
                                VStack {
                                    Image("MascotDriveBuddy")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 250)
                                        .padding(.top, 450)
                                        .offset(x: 80, y: 85)
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

                    // ✅ Auto-navigation to HomeView after login
                    .navigationDestination(isPresented: $authVM.isAuthenticated) {
                        HomeView(authVM: authVM)
                    }

                    .navigationTitle("") // remove default title
                    .navigationBarBackButtonHidden(false)
                }
            }
}

#Preview {
    LoginView(authVM: AuthenticationViewModel(context: PersistenceController.shared.container.viewContext))
}
