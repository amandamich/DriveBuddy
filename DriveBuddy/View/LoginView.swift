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

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.opacity(0.95).ignoresSafeArea()

                FlowingLinesView()
                    .ignoresSafeArea()

                VStack {
                    ZStack(alignment: .center) {
                        // Glowing circle background
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
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled(true)
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
                                authVM.errorMessage = nil
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

                            // MARK: - Error Message
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
                withAnimation { isAnimating = true }
                authVM.errorMessage = nil
            }

            // ✅ Auto-navigation to HomeView after login
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
