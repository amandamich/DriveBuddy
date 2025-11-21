import SwiftUI
import CoreData

struct SignUpView: View {
    @ObservedObject var authVM: AuthenticationViewModel
    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var password = ""
    @State private var confirmpassword = ""
    @State private var isAnimating = false
    @State private var goToLogin = false
    
    // ✅ Computed property to check if form is valid
    private var isFormValid: Bool {
        !email.isEmpty &&
        !phoneNumber.isEmpty &&
        !password.isEmpty &&
        !confirmpassword.isEmpty &&
        password == confirmpassword &&
        authVM.validateEmail(email)
    }

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

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Phone Number")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                    .shadow(color: .blue, radius: 5)
                                
                                HStack(spacing: 0) {
                                    // Fixed +62 prefix
                                    Text("+62")
                                        .foregroundColor(.black)
                                        .font(.body)
                                        .padding(.leading, 16)
                                        .padding(.trailing, 12)
                                    
                                    // Divider line
                                    Rectangle()
                                        .fill(Color.cyan.opacity(0.3))
                                        .frame(width: 1)
                                        .padding(.vertical, 10)
                                    
                                    // Phone Number Input
                                    HStack {
                                        TextField("812-3456-7890", text: $phoneNumber)
                                            .foregroundColor(.black)
                                            .keyboardType(.phonePad)
                                            .padding(.leading, 16)
                                            .padding(.trailing, 16)
                                            .onChange(of: phoneNumber) { newValue in
                                                phoneNumber = formatPhoneNumber(newValue)
                                            }
                                    }
                                }
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white)
                                )
                                .shadow(color: .blue, radius: 8)
                            }
                            .padding(.bottom, 2)

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
                                
                                authVM.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
                                authVM.password = password
                                authVM.signUp()

                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    goToLogin = true
                                }
                            }) {
                                Text("Sign Up")
                                    .font(.headline)
                                    .foregroundColor(isFormValid ? .white : .gray)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(isFormValid ? Color.cyan : Color.gray.opacity(0.5), lineWidth: 2)
                                            .shadow(color: isFormValid ? .blue : .clear, radius: 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color.black.opacity(0.5))
                                            )
                                    )
                                    .shadow(color: isFormValid ? .blue : .clear, radius: 10)
                            }
                            .disabled(!isFormValid) // ✅ Disable button when form is invalid

                            // Feedback Messages
                            if let error = authVM.errorMessage, !error.isEmpty {
                                Text(error)
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .padding(.top, 8)
                            }

                            // Back to Login
                            NavigationLink("Already have an account? Sign In") {
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
            .navigationDestination(isPresented: $goToLogin) {
                LoginView(authVM: authVM)
            }
            .navigationTitle("")
            .navigationBarBackButtonHidden(false)
        }
    }
    
    private func formatPhoneNumber(_ value: String) -> String {
        let cleaned = value.filter { $0.isNumber }
        
        // Limit to 12 digits
        let limited = String(cleaned.prefix(12))
        
        // Format: XXX-XXXX-XXXX
        if limited.count <= 3 {
            return limited
        } else if limited.count <= 7 {
            let index = limited.index(limited.startIndex, offsetBy: 3)
            return "\(limited[..<index])-\(limited[index...])"
        } else {
            let index1 = limited.index(limited.startIndex, offsetBy: 3)
            let index2 = limited.index(limited.startIndex, offsetBy: 7)
            return "\(limited[..<index1])-\(limited[index1..<index2])-\(limited[index2...])"
        }
    }
}

#Preview{
    SignUpView(authVM: AuthenticationViewModel(context: PersistenceController.shared.container.viewContext))
}
