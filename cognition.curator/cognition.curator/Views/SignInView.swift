import SwiftUI

struct SignInView: View {
    @StateObject private var authService = AuthenticationService.shared
    @State private var signInForm = SignInForm()
    @State private var showPassword = false
    @FocusState private var focusedField: SignInField?
    
    let onSuccess: () -> Void
    let onSwitchToSignUp: () -> Void
    
    enum SignInField {
        case email, password
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Welcome back message
                VStack(spacing: 8) {
                    Text("Welcome Back!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Sign in to continue your learning journey")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Form fields
                VStack(spacing: 20) {
                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            Text("Email Address")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        
                        TextField("Enter your email", text: $signInForm.email)
                            .textFieldStyle(CustomTextFieldStyle(
                                isValid: true, // We don't validate on sign in
                                isFocused: focusedField == .email
                            ))
                            .focused($focusedField, equals: .email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.next)
                            .onSubmit {
                                focusedField = .password
                            }
                    }
                    
                    // Password field
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            Text("Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        
                        HStack {
                            Group {
                                if showPassword {
                                    TextField("Enter your password", text: $signInForm.password)
                                } else {
                                    SecureField("Enter your password", text: $signInForm.password)
                                }
                            }
                            .focused($focusedField, equals: .password)
                            .submitLabel(.done)
                            .onSubmit {
                                if signInForm.isValid {
                                    signIn()
                                }
                            }
                            
                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        .textFieldStyle(CustomTextFieldStyle(
                            isValid: true,
                            isFocused: focusedField == .password
                        ))
                    }
                }
                .padding(.horizontal, 24)
                
                // Sign in actions
                VStack(spacing: 20) {
                    // Sign in button
                    Button(action: signIn) {
                        HStack {
                            if case .authenticating = authService.authState {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                                Text("Signing In...")
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                Text("Sign In")
                            }
                        }
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(signInForm.isValid ? Color.blue : Color.gray.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(!signInForm.isValid || authService.authState == .authenticating)
                    .padding(.horizontal, 24)
                    
                    // Forgot password
                    Button("Forgot Password?") {
                        // TODO: Implement forgot password
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    
                    // Error message
                    if case .error(let error) = authService.authState {
                        ErrorMessageView(message: error.localizedDescription)
                            .padding(.horizontal, 24)
                    }
                }
                
                // Demo account info
                DemoAccountView()
                    .padding(.horizontal, 24)
                
                // Switch to sign up
                VStack(spacing: 16) {
                    HStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                        
                        Text("or")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 24)
                    
                    Button(action: onSwitchToSignUp) {
                        HStack {
                            Text("Don't have an account?")
                                .foregroundColor(.secondary)
                            Text("Sign Up")
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                        .font(.subheadline)
                    }
                }
                .padding(.top, 8)
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }
    
    private func signIn() {
        focusedField = nil
        
        Task {
            await authService.signIn(
                email: signInForm.email,
                password: signInForm.password
            )
            
            if authService.isAuthenticated {
                await MainActor.run {
                    onSuccess()
                }
            }
        }
    }
}

// MARK: - Demo Account View

struct DemoAccountView: View {
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    
                    Text("Try Demo Account")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Use these credentials to explore the app:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Email:")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("demo@example.com")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Password:")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("demo1234")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                    }
                    
                    DemoSignInButton()
                }
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
    }
}

struct DemoSignInButton: View {
    @StateObject private var authService = AuthenticationService.shared
    
    var body: some View {
        Button(action: signInWithDemo) {
            HStack {
                Image(systemName: "play.circle.fill")
                Text("Sign In with Demo")
                    .fontWeight(.medium)
            }
            .font(.caption)
            .foregroundColor(.blue)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.blue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private func signInWithDemo() {
        Task {
            // First create demo account if it doesn't exist
            let demoEmail = "demo@example.com"
            let demoPassword = "demo1234"
            
            // Try to sign in first
            await authService.signIn(email: demoEmail, password: demoPassword)
            
            // If sign in failed, create the demo account
            if !authService.isAuthenticated {
                await authService.signUp(
                    name: "Demo User",
                    email: demoEmail,
                    password: demoPassword
                )
            }
        }
    }
}

#Preview {
    SignInView(
        onSuccess: {},
        onSwitchToSignUp: {}
    )
} 