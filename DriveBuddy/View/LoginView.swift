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

// MARK: - Flowing Lines Animation
struct FlowingLinesView: View {
    @State private var phase1: CGFloat = 0
    @State private var phase2: CGFloat = 0
    @State private var phase3: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                WavePath(phase: phase1, amplitude: 30, frequency: 1.5)
                    .stroke(
                        LinearGradient(
                            colors: [.cyan.opacity(0.4), .blue.opacity(0.6), .cyan.opacity(0.4)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 3
                    )
                    .blur(radius: 3)
                    .offset(y: 150)

                WavePath(phase: phase2, amplitude: 45, frequency: 1.5)
                    .stroke(
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .cyan.opacity(0.5), .blue.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2.5
                    )
                    .blur(radius: 4)
                    .offset(y: 350)

                WavePath(phase: phase3, amplitude: 25, frequency: 1.8)
                    .stroke(
                        LinearGradient(
                            colors: [.cyan.opacity(0.3), .blue.opacity(0.4), .cyan.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2
                    )
                    .blur(radius: 2.5)
                    .offset(y: 550)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) { phase1 = .pi * 2 }
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) { phase2 = .pi * 2 }
            withAnimation(.linear(duration: 3.5).repeatForever(autoreverses: false)) { phase3 = .pi * 2 }
        }
    }
}

// MARK: - Wave Path Shape
struct WavePath: Shape {
    var phase: CGFloat
    var amplitude: CGFloat
    var frequency: CGFloat

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let midHeight = rect.height / 2

        path.move(to: CGPoint(x: 0, y: midHeight))

        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let sine = sin((relativeX * frequency * .pi * 2) + phase)
            let y = midHeight + (sine * amplitude)
            path.addLine(to: CGPoint(x: x, y: y))
        }

        return path
    }
}

// MARK: - Main Login View
struct LoginView: View {
    @ObservedObject var authVM: AuthenticationViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var isAnimating = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password
    }
    
    // ✅ Computed property to validate email format
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    // ✅ Computed property to check if form is valid
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && isValidEmail(email)
    }
    
    // ✅ Helper message when fields are empty or invalid
    private var validationMessage: String? {
        if email.isEmpty && password.isEmpty {
            return "Please enter your email and password"
        } else if email.isEmpty {
            return "Please enter your email"
        } else if !email.isEmpty && !isValidEmail(email) {
            return "Please enter a valid email address"
        } else if password.isEmpty {
            return "Please enter your password"
        }
        return nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.black.opacity(0.95).ignoresSafeArea()

                // Flowing lines animation
                FlowingLinesView()
                    .ignoresSafeArea()
                
                // Glowing circle background
                Circle()
                    .fill(Color.blue.opacity(0.5))
                    .frame(width: 400, height: 400)
                    .blur(radius: 100)
                    .offset(x: -50, y: -300)
                    .offset(y: isAnimating ? -20 : 20)
                    .animation(
                        Animation.easeInOut(duration: 3)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )

                VStack(spacing: 0) {
                    // Title at top
                    Text("Sign In")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .blue, radius: 10)
                        .padding(.top, 80)
                        .padding(.bottom, 40)
                    
                    // Email Field
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
                            .focused($focusedField, equals: .email)
                            .submitLabel(.next)
                            .onSubmit {
                                focusedField = .password
                            }
                    }
                    .padding(.horizontal, 30)

                    // Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .foregroundColor(.white)
                            .font(.headline)
                            .shadow(color: .blue, radius: 5)
                        SecureField("Enter your password", text: $password)
                            .textFieldStyle(NeonTextFieldStyle())
                            .focused($focusedField, equals: .password)
                            .submitLabel(.go)
                            .onSubmit {
                                if isFormValid {
                                    authVM.errorMessage = nil
                                    authVM.email = email
                                    authVM.password = password
                                    authVM.login()
                                }
                            }
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 20)

                    // MARK: - Login Button
                    Button(action: {
                        focusedField = nil
                        authVM.errorMessage = nil
                        authVM.email = email
                        authVM.password = password
                        authVM.login()
                    }) {
                        Text("Sign In")
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
                    .padding(.horizontal, 30)
                    .padding(.top, 30)

                    // MARK: - Validation Message
                    if let message = validationMessage {
                        Text(message)
                            .foregroundColor(.orange)
                            .font(.caption)
                            .padding(.top, 8)
                            .transition(.opacity)
                    }

                    // MARK: - Error Message (from auth)
                    if let error = authVM.errorMessage, !error.isEmpty {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.top, 8)
                            .transition(.opacity)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    withAnimation {
                                        authVM.errorMessage = nil
                                    }
                                }
                            }
                    }

                    // MARK: - Navigate to Sign Up
                    NavigationLink("Don't have an account ? Sign Up") {
                        SignUpView(authVM: authVM)
                    }
                    .foregroundColor(.cyan)
                    .padding(.top, 15)
                    
                    Spacer()
                    
                    // MARK: - Mascot Image (positioned to the right)
                    if focusedField == nil {
                        HStack {
                            Spacer()
                            Image("MascotDriveBuddy")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 550)
                                .padding(.trailing, -20)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .onTapGesture {
                focusedField = nil
            }
            .onAppear {
                withAnimation { isAnimating = true }
                authVM.errorMessage = nil
            }
            .navigationDestination(isPresented: $authVM.isAuthenticated) {
                HomeView(authVM: authVM)
            }
            .navigationTitle("")
            .navigationBarBackButtonHidden(false)
        }
    }
}

// MARK: - Preview
#Preview {
    LoginView(authVM: AuthenticationViewModel(context: PersistenceController.shared.container.viewContext))
}
