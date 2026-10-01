import SwiftUI

/// Mirrors app/login/page.tsx + login-form.tsx + demo-login-button.tsx:
/// passwordless email-code login in two steps, plus a one-tap public demo
/// account. AppSession's auth-state listener flips `route` once the OTP
/// verify (or the demo sign-in) succeeds, so this view only needs to stop
/// its own spinner on success — no manual navigation here.
struct LoginView: View {
    private enum Step: Equatable {
        case email
        case code
    }

    private let otpLength = 8
    private let demoEmail = "demo1@example.com"
    private let demoPassword = "DemoPiso2026!"

    private let authRepo = AuthRepository()

    @State private var step: Step = .email
    @State private var email = ""
    @State private var code = ""
    @State private var isLoading = false
    @State private var isDemoLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: RTheme.Radius.lg)
                        .fill(RTheme.primary.opacity(0.15))
                    Image(systemName: "house.fill")
                        .foregroundStyle(RTheme.primary)
                        .font(.system(size: 22, weight: .semibold))
                }
                .frame(width: 56, height: 56)
                .padding(.top, 40)

                RCard(title: "Rumis", description: stepDescription) {
                    Group {
                        switch step {
                        case .email:
                            emailStep
                        case .code:
                            codeStep
                        }
                    }
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        )
                    )
                    .animation(.easeInOut(duration: 0.25), value: step)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(RTheme.destructive)
                        .multilineTextAlignment(.center)
                }

                Button {
                    signInDemo()
                } label: {
                    Label(isDemoLoading ? "Entrando..." : "Ver demo (sin registro)", systemImage: "eye")
                }
                .buttonStyle(.rSecondary)
                .disabled(isDemoLoading)
            }
            .padding(20)
            .frame(maxWidth: 420)
            .frame(maxWidth: .infinity)
        }
        .background(RTheme.background)
        .scrollDismissesKeyboard(.interactively)
    }

    private var stepDescription: String {
        switch step {
        case .email:
            return "Escribe tu email y te mandamos un código para entrar, sin contraseña."
        case .code:
            return "Escribe el código que le hemos mandado a \(email)."
        }
    }

    private var emailStep: some View {
        VStack(spacing: 14) {
            RTextField(
                title: "tucorreo@ejemplo.com",
                text: $email,
                keyboardType: .emailAddress,
                textContentType: .emailAddress
            )

            Button {
                sendCode()
            } label: {
                Text(isLoading ? "Enviando..." : "Enviar código")
            }
            .buttonStyle(.rPrimary)
            .disabled(isLoading || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private var codeStep: some View {
        VStack(spacing: 14) {
            RTextField(
                title: String(repeating: "1", count: otpLength),
                text: $code,
                keyboardType: .numberPad,
                textContentType: .oneTimeCode
            )
            .onChange(of: code) { _, newValue in
                code = String(newValue.filter(\.isNumber).prefix(otpLength))
            }

            Button {
                verifyCode()
            } label: {
                Text(isLoading ? "Comprobando..." : "Entrar")
            }
            .buttonStyle(.rPrimary)
            .disabled(isLoading || code.count != otpLength)

            HStack {
                Button("Cambiar email") {
                    withAnimation {
                        step = .email
                        code = ""
                        errorMessage = nil
                    }
                }
                .font(.footnote)
                .foregroundStyle(RTheme.mutedForeground)

                Spacer()

                Button("Reenviar código") {
                    sendCode()
                }
                .font(.footnote)
                .foregroundStyle(RTheme.primary)
                .disabled(isLoading)
            }
        }
    }

    private func sendCode() {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        email = cleanEmail
        guard !cleanEmail.isEmpty else { return }

        errorMessage = nil
        isLoading = true
        Task {
            do {
                try await authRepo.requestEmailCode(email: cleanEmail)
                isLoading = false
                if step != .code {
                    withAnimation {
                        step = .code
                    }
                }
            } catch {
                isLoading = false
                errorMessage = "No se ha podido enviar el código: \(error.localizedDescription)"
            }
        }
    }

    private func verifyCode() {
        errorMessage = nil
        isLoading = true
        Task {
            do {
                try await authRepo.verifyEmailCode(email: email, code: code)
                isLoading = false
                // AppSession's auth listener picks up the new session and
                // flips `route` on its own; nothing else to do here.
            } catch {
                isLoading = false
                errorMessage = "Código incorrecto o caducado."
            }
        }
    }

    private func signInDemo() {
        errorMessage = nil
        isDemoLoading = true
        Task {
            do {
                try await authRepo.signInDemo(email: demoEmail, password: demoPassword)
                isDemoLoading = false
            } catch {
                isDemoLoading = false
                errorMessage = "No se ha podido entrar a la demo. Inténtalo de nuevo."
            }
        }
    }
}
