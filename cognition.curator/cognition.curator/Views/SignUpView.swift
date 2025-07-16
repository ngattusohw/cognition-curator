import SwiftUI

struct SignUpView: View {
    @StateObject private var authService = AuthenticationService.shared
    @State private var signUpForm = SignUpForm()
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var agreedToTerms = false
    @FocusState private var focusedField: SignUpField?
    
    let onSuccess: () -> Void
    let onSwitchToSignIn: () -> Void
    
    enum SignUpField {
        case name, email, password, confirmPassword
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Form fields
                VStack(spacing: 20) {
                    // Name field
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            Text("Full Name")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        
                        TextField("Enter your full name", text: $signUpForm.name)
                            .textFieldStyle(CustomTextFieldStyle(
                                isValid: signUpForm.name.isEmpty || signUpForm.isValidName,
                                isFocused: focusedField == .name
                            ))
                            .focused($focusedField, equals: .name)
                            .textInputAutocapitalization(.words)
                            .submitLabel(.next)
                            .onSubmit {
                                focusedField = .email
                            }
                        
                        if !signUpForm.name.isEmpty && !signUpForm.isValidName {
                            ValidationMessage(text: "Name must be at least 2 characters")
                        }
                    }
                    
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
                        
                        TextField("Enter your email", text: $signUpForm.email)
                            .textFieldStyle(CustomTextFieldStyle(
                                isValid: signUpForm.email.isEmpty || signUpForm.isValidEmail,
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
                        
                        if !signUpForm.email.isEmpty && !signUpForm.isValidEmail {
                            ValidationMessage(text: "Please enter a valid email address")
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
                                    TextField("Create a password", text: $signUpForm.password)
                                } else {
                                    SecureField("Create a password", text: $signUpForm.password)
                                }
                            }
                            .focused($focusedField, equals: .password)
                            .submitLabel(.next)
                            .onSubmit {
                                focusedField = .confirmPassword
                            }
                            
                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        .textFieldStyle(CustomTextFieldStyle(
                            isValid: signUpForm.password.isEmpty || signUpForm.isValidPassword,
                            isFocused: focusedField == .password
                        ))
                        
                        if !signUpForm.password.isEmpty && !signUpForm.isValidPassword {
                            ValidationMessage(text: "Password must be at least 8 characters")
                        }
                        
                        // Password strength indicator
                        if !signUpForm.password.isEmpty {
                            PasswordStrengthView(password: signUpForm.password)
                        }
                    }
                    
                    // Confirm password field
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            Text("Confirm Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        
                        HStack {
                            Group {
                                if showConfirmPassword {
                                    TextField("Confirm your password", text: $signUpForm.confirmPassword)
                                } else {
                                    SecureField("Confirm your password", text: $signUpForm.confirmPassword)
                                }
                            }
                            .focused($focusedField, equals: .confirmPassword)
                            .submitLabel(.done)
                            .onSubmit {
                                if signUpForm.isValid && agreedToTerms {
                                    signUp()
                                }
                            }
                            
                            Button(action: { showConfirmPassword.toggle() }) {
                                Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        .textFieldStyle(CustomTextFieldStyle(
                            isValid: signUpForm.confirmPassword.isEmpty || signUpForm.passwordsMatch,
                            isFocused: focusedField == .confirmPassword
                        ))
                        
                        if !signUpForm.confirmPassword.isEmpty && !signUpForm.passwordsMatch {
                            ValidationMessage(text: "Passwords do not match")
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                
                // Terms and conditions
                VStack(spacing: 16) {
                    Button(action: { agreedToTerms.toggle() }) {
                        HStack(spacing: 12) {
                            Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                                .foregroundColor(agreedToTerms ? .blue : .gray)
                                .font(.title2)
                            
                            Text("I agree to the Terms of Service and Privacy Policy")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Sign up button
                    Button(action: signUp) {
                        HStack {
                            if case .authenticating = authService.authState {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                                Text("Creating Account...")
                            } else {
                                Image(systemName: "person.crop.circle.badge.plus")
                                Text("Create Account")
                            }
                        }
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            (signUpForm.isValid && agreedToTerms) ? 
                            Color.blue : Color.gray.opacity(0.6)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(!signUpForm.isValid || !agreedToTerms || authService.authState == .authenticating)
                    .padding(.horizontal, 24)
                    
                    // Error message
                    if case .error(let error) = authService.authState {
                        ErrorMessageView(message: error.localizedDescription)
                            .padding(.horizontal, 24)
                    }
                }
                
                // Switch to sign in
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
                    
                    Button(action: onSwitchToSignIn) {
                        HStack {
                            Text("Already have an account?")
                                .foregroundColor(.secondary)
                            Text("Sign In")
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
    
    private func signUp() {
        focusedField = nil
        
        Task {
            await authService.signUp(
                name: signUpForm.name,
                email: signUpForm.email,
                password: signUpForm.password
            )
            
            if authService.isAuthenticated {
                await MainActor.run {
                    onSuccess()
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct CustomTextFieldStyle: TextFieldStyle {
    let isValid: Bool
    let isFocused: Bool
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(uiColor: UIColor.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isFocused ? Color.blue :
                        isValid ? Color.clear : Color.red,
                        lineWidth: isFocused ? 2 : 1
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)
            .animation(.easeInOut(duration: 0.2), value: isValid)
    }
}

struct ValidationMessage: View {
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .font(.caption)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.red)
            
            Spacer()
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

struct ErrorMessageView: View {
    let message: String
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.red)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.red)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct PasswordStrengthView: View {
    let password: String
    
    private var strength: PasswordStrength {
        if password.count < 6 {
            return .weak
        } else if password.count < 8 {
            return .medium
        } else if password.count >= 8 && hasNumbers && hasSpecialChars {
            return .strong
        } else if password.count >= 8 {
            return .good
        } else {
            return .medium
        }
    }
    
    private var hasNumbers: Bool {
        password.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil
    }
    
    private var hasSpecialChars: Bool {
        password.rangeOfCharacter(from: CharacterSet.punctuationCharacters.union(.symbols)) != nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                ForEach(0..<4, id: \.self) { index in
                    Rectangle()
                        .fill(index < strength.level ? strength.color : Color.gray.opacity(0.3))
                        .frame(height: 4)
                        .clipShape(Capsule())
                }
            }
            
            Text(strength.text)
                .font(.caption)
                .foregroundColor(strength.color)
        }
        .animation(.easeInOut(duration: 0.2), value: strength)
    }
}

enum PasswordStrength {
    case weak, medium, good, strong
    
    var level: Int {
        switch self {
        case .weak: return 1
        case .medium: return 2
        case .good: return 3
        case .strong: return 4
        }
    }
    
    var color: Color {
        switch self {
        case .weak: return .red
        case .medium: return .orange
        case .good: return .yellow
        case .strong: return .green
        }
    }
    
    var text: String {
        switch self {
        case .weak: return "Weak password"
        case .medium: return "Medium password"
        case .good: return "Good password"
        case .strong: return "Strong password"
        }
    }
}

#Preview {
    SignUpView(
        onSuccess: {},
        onSwitchToSignIn: {}
    )
} 