//
//  ToastView.swift
//  cognition.curator
//
//  Created by Assistant on 1/24/25.
//

import SwiftUI

// MARK: - Toast Model
struct Toast: Equatable {
    let id = UUID()
    let message: String
    let type: ToastType
    let duration: TimeInterval

    init(message: String, type: ToastType = .info, duration: TimeInterval = 3.0) {
        self.message = message
        self.type = type
        self.duration = duration
    }
}

enum ToastType {
    case success
    case error
    case info
    case warning

    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .info: return .blue
        case .warning: return .orange
        }
    }

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Toast View
struct ToastView: View {
    let toast: Toast

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.type.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(toast.type.color)

            Text(toast.message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(2)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(toast.type.color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Toast Manager
class ToastManager: ObservableObject {
    @Published var currentToast: Toast?
    private var toastTimer: Timer?

    func show(_ toast: Toast) {
        // Cancel existing timer
        toastTimer?.invalidate()

        // Show new toast
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentToast = toast
        }

        // Auto-hide after duration
        toastTimer = Timer.scheduledTimer(withTimeInterval: toast.duration, repeats: false) { _ in
            self.hide()
        }
    }

    func show(message: String, type: ToastType = .info, duration: TimeInterval = 3.0) {
        let toast = Toast(message: message, type: type, duration: duration)
        show(toast)
    }

    func hide() {
        toastTimer?.invalidate()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentToast = nil
        }
    }
}

// MARK: - Toast Container View Modifier
struct ToastContainer: ViewModifier {
    @ObservedObject var toastManager: ToastManager

    func body(content: Content) -> some View {
        ZStack {
            content

            VStack {
                Spacer()

                if let toast = toastManager.currentToast {
                    ToastView(toast: toast)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100) // Position above tab bar
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                        .onTapGesture {
                            toastManager.hide()
                        }
                }
            }
        }
    }
}

extension View {
    func toast(manager: ToastManager) -> some View {
        modifier(ToastContainer(toastManager: manager))
    }
}
