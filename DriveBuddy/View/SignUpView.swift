import SwiftUI
import CoreData

struct SignUpView: View {
    @ObservedObject var authVM: AuthenticationViewModel
    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var password = ""
    @State private var confirmpassword = ""
    @State private var isAnimating = false
    @State private var goToLogin = false // ✅ Tambahan

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.opacity(0.95).ignoresSafeArea()
                FlowingLinesView().ignoresSafeArea()

                VStack {
                    ZStack(alignment: .center) {
                        Circle()
                            .fill(Color.blue.opacity(0.5))
                            .position(x: 150, y: -270)
                            .frame(width: 300, height: 300)
                            .blur(radius: 80)
                            .offset(y: isAnimating ? 50 : 100)
                            .animation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true),
                                value: isAnimating
                            )

                        VStack(spacing: 30) {
                            Text("Sign Up")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(color: .blue, radius: 10)

                            // Email
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                    .shadow(color: .blue, radius: 5)
                                TextField("Enter your email", text: $email)
                                    .textFieldStyle(NeonTextFieldStyle())
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled(true)
                            }

                            // Phone Number
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Phone Number")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                    .shadow(color: .blue, radius: 5)
                                TextField("+62", text: $phoneNumber)
                                    .textFieldStyle(NeonTextFieldStyle())
                                    .keyboardType(.phonePad)
                            }

                            // Password
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Create a Password")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                    .shadow(color: .blue, radius: 5)
                                SecureField("Enter your password", text: $password)
                                    .textFieldStyle(NeonTextFieldStyle())
                            }

                            // Confirm Password
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                    .shadow(color: .blue, radius: 5)
                                SecureField("Confirm your password", text: $confirmpassword)
                                    .textFieldStyle(NeonTextFieldStyle())
                            }
                            .padding(.bottom, 20)

                            // MARK: - Sign Up Button
                            Button(action: {
                                authVM.errorMessage = nil
                                guard !email.isEmpty, !password.isEmpty else {
                                    authVM.errorMessage = "Please fill all fields"
                                    return
                                }
                                guard password == confirmpassword else {
                                    authVM.errorMessage = "Passwords do not match"
                                    return
                                }
                                // Validate email format
                                guard authVM.validateEmail(email) else {
                                authVM.errorMessage = "Invalid email format"
                                                                   return
                                                               }

                                authVM.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
                                authVM.password = password
                                authVM.signUp()

                                // ✅ Setelah Sign Up, arahkan ke login view
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    goToLogin = true
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

                            // Feedback Messages
                            if let error = authVM.errorMessage, !error.isEmpty {
                                Text(error)
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .padding(.top, 8)
                            }

                            // Back to Login
                            NavigationLink("Already have an account? Login") {
                                LoginView(authVM: authVM)
                            }
                            .foregroundColor(.cyan)
                            .padding(.top, 10)
                        }
                    }
                }
                .padding(.horizontal, 40)
            }
            .onAppear {
                withAnimation { isAnimating = true }
                authVM.errorMessage = nil
            }
            // ✅ Sekarang navigasi ke LoginView, bukan Home
            .navigationDestination(isPresented: $goToLogin) {
                LoginView(authVM: authVM)
            }
            .navigationTitle("")
            .navigationBarBackButtonHidden(false)
        }
    }
}
