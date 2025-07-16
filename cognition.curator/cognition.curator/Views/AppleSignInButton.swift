import SwiftUI
import AuthenticationServices

struct AppleSignInButton: View {
    let onSignIn: () -> Void
    
    var body: some View {
        Button(action: onSignIn) {
            HStack(spacing: 12) {
                Image(systemName: "applelogo")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                
                Text("Continue with Apple")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.black)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(AppleSignInButtonStyle())
    }
}

struct AppleSignInButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: 20) {
        AppleSignInButton {
            print("Apple Sign In tapped")
        }
        .padding()
        
        // Show in different color schemes
        AppleSignInButton {
            print("Apple Sign In tapped")
        }
        .padding()
        .preferredColorScheme(.dark)
    }
} 