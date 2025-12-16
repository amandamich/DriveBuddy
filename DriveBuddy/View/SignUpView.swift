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
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, phone, password, confirmPassword
    }
    
    // ✅ Enhanced form validation with password requirements
    private var isFormValid: Bool {
        !email.isEmpty &&
        !phoneNumber.isEmpty &&
        !password.isEmpty &&
        !confirmpassword.isEmpty &&
        password == confirmpassword &&
        authVM.validateEmail(email) &&
        authVM.validatePassword(password).isValid
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.opacity(0.95).ignoresSafeArea()
                FlowingLinesView().ignoresSafeArea()

                ScrollView {
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

                            VStack(spacing: 25) {
                                Text("Sign Up")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .shadow(color: .blue, radius: 10)
                                    .padding(.top, 40)

                                // Email
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Email")
                                        .foregroundColor(.white)
                                        .font(.headline)
                                        .shadow(color: .blue, radius: 5)
                                    
                                    TextField("", text: $email, prompt: Text("Enter your email").foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4)))
                                        .foregroundColor(.black)
                                        .padding()
                                        .background(Color.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.cyan, lineWidth: 2)
                                                .shadow(color: .blue, radius: 8)
                                        )
                                        .cornerRadius(12)
                                        .shadow(color: .blue.opacity(0.3), radius: 10)
                                        .keyboardType(.emailAddress)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled(true)
                                        .focused($focusedField, equals: .email)
                                        .submitLabel(.next)
                                        .onSubmit {
                                            focusedField = .phone
                                        }
                                }

                                // Phone Number
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Phone Number")
                                        .foregroundColor(.white)
                                        .font(.headline)
                                        .shadow(color: .blue, radius: 5)
                                    
                                    HStack(spacing: 0) {
                                        Text("+62")
                                            .foregroundColor(.black)
                                            .font(.body)
                                            .padding(.leading, 16)
                                            .padding(.trailing, 12)
                                        
                                        Rectangle()
                                            .fill(Color.cyan.opacity(0.3))
                                            .frame(width: 1)
                                            .padding(.vertical, 10)
                                        
                                        ZStack(alignment: .leading) {
                                            // ✅ Fixed: Dark placeholder that works in all modes
                                            if phoneNumber.isEmpty && focusedField != .phone {
                                                Text("812-3456-7890")
                                                    .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                                                    .padding(.leading, 16)
                                                    .allowsHitTesting(false)
                                            }
                                            TextField("", text: $phoneNumber)
                                                .foregroundColor(.black)
                                                .keyboardType(.phonePad)
                                                .padding(.leading, 16)
                                                .padding(.trailing, 16)
                                                .focused($focusedField, equals: .phone)
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

                                // Password with Show/Hide Toggle
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Create a Password")
                                        .foregroundColor(.white)
                                        .font(.headline)
                                        .shadow(color: .blue, radius: 5)
                                    
                                    HStack {
                                        ZStack(alignment: .leading) {
                                            // ✅ Fixed: Dark placeholder that works in all modes
                                            if password.isEmpty && focusedField != .password {
                                                Text("Enter your password")
                                                    .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                                                    .padding(.leading, 16)
                                                    .allowsHitTesting(false)
                                            }
                                            if showPassword {
                                                TextField("", text: $password)
                                                    .foregroundColor(.black)
                                                    .padding(.leading, 16)
                                                    .focused($focusedField, equals: .password)
                                            } else {
                                                SecureField("", text: $password)
                                                    .foregroundColor(.black)
                                                    .padding(.leading, 16)
                                                    .focused($focusedField, equals: .password)
                                            }
                                        }
                                        
                                        Button(action: { showPassword.toggle() }) {
                                            Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                                .foregroundColor(.gray)
                                                .padding(.trailing, 16)
                                        }
                                    }
                                    .frame(height: 56)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.cyan, lineWidth: 2)
                                    )
                                    .shadow(color: .blue, radius: 8)
                                    
                                    // ✅ Password Requirements Checklist
                                    if !password.isEmpty {
                                        VStack(alignment: .leading, spacing: 4) {
                                            PasswordRequirement(
                                                text: "8-20 characters",
                                                isMet: password.count >= 8 && password.count <= 20
                                            )
                                            PasswordRequirement(
                                                text: "At least one uppercase letter (A-Z)",
                                                isMet: password.range(of: "[A-Z]", options: .regularExpression) != nil
                                            )
                                            PasswordRequirement(
                                                text: "At least one lowercase letter (a-z)",
                                                isMet: password.range(of: "[a-z]", options: .regularExpression) != nil
                                            )
                                            PasswordRequirement(
                                                text: "At least one number (0-9)",
                                                isMet: password.range(of: "[0-9]", options: .regularExpression) != nil
                                            )
                                        }
                                        .padding(.top, 8)
                                    }
                                }

                                // Confirm Password with Show/Hide Toggle
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Confirm Password")
                                        .foregroundColor(.white)
                                        .font(.headline)
                                        .shadow(color: .blue, radius: 5)
                                    
                                    HStack {
                                        ZStack(alignment: .leading) {
                                            // ✅ Fixed: Dark placeholder that works in all modes
                                            if confirmpassword.isEmpty && focusedField != .confirmPassword {
                                                Text("Confirm your password")
                                                    .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                                                    .padding(.leading, 16)
                                                    .allowsHitTesting(false)
                                            }
                                            if showConfirmPassword {
                                                TextField("", text: $confirmpassword)
                                                    .foregroundColor(.black)
                                                    .padding(.leading, 16)
                                                    .focused($focusedField, equals: .confirmPassword)
                                            } else {
                                                SecureField("", text: $confirmpassword)
                                                    .foregroundColor(.black)
                                                    .padding(.leading, 16)
                                                    .focused($focusedField, equals: .confirmPassword)
                                            }
                                        }
                                        
                                        Button(action: { showConfirmPassword.toggle() }) {
                                            Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                                .foregroundColor(.gray)
                                                .padding(.trailing, 16)
                                        }
                                    }
                                    .frame(height: 56)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.cyan, lineWidth: 2)
                                    )
                                    .shadow(color: .blue, radius: 8)
                                    
                                    // ✅ Password Match Indicator
                                    if !confirmpassword.isEmpty {
                                        HStack {
                                            Image(systemName: password == confirmpassword ? "checkmark.circle.fill" : "xmark.circle.fill")
                                                .foregroundColor(password == confirmpassword ? .green : .red)
                                            Text(password == confirmpassword ? "Passwords match" : "Passwords do not match")
                                                .foregroundColor(password == confirmpassword ? .green : .red)
                                                .font(.caption)
                                        }
                                        .padding(.top, 4)
                                    }
                                }
                                .padding(.bottom, 20)

                                // MARK: - Sign Up Button
                                Button(action: {
                                    focusedField = nil
                                    authVM.errorMessage = nil
                                    
                                    authVM.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
                                    authVM.password = password
                                    
                                    // ✅ NEW: Format and pass phone number
                                    let formattedPhone = "+62" + phoneNumber.replacingOccurrences(of: "-", with: "")
                                    authVM.signUp(phoneNumber: formattedPhone)

                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        if authVM.errorMessage?.contains("successful") == true {
                                            goToLogin = true
                                        }
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
                                .disabled(!isFormValid)

                                // Feedback Messages
                                if let error = authVM.errorMessage, !error.isEmpty {
                                    Text(error)
                                        .foregroundColor(error.contains("successful") ? .green : .red)
                                        .font(.caption)
                                        .padding(.top, 8)
                                        .multilineTextAlignment(.center)
                                }

                                // Back to Login
                                NavigationLink("Already have an account? Sign In") {
                                    LoginView(authVM: authVM)
                                }
                                .foregroundColor(.cyan)
                                .padding(.top, 10)
                                .padding(.bottom, 40)
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                }
            }
            .onTapGesture {
                focusedField = nil
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
        let limited = String(cleaned.prefix(12))
        
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

// MARK: - Password Requirement Component
struct PasswordRequirement: View {
    let text: String
    let isMet: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isMet ? .green : .white.opacity(0.5))
                .font(.caption)
            Text(text)
                .foregroundColor(isMet ? .green : .white.opacity(0.7))
                .font(.caption)
        }
    }
}

#Preview{
    SignUpView(authVM: AuthenticationViewModel(context: PersistenceController.shared.container.viewContext))
}
