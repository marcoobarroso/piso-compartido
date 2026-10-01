import SwiftUI

/// Mirrors app/onboarding/page.tsx + onboarding-forms.tsx: shown by the
/// coordinator while AppSession.route == .needsHousehold, offering the two
/// mutually-exclusive paths into a household (create vs. join by code).
struct OnboardingView: View {
    @Environment(AppSession.self) private var session

    @State private var householdName = ""
    @State private var inviteCode = ""
    @State private var isCreating = false
    @State private var isJoining = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                RCard(
                    title: "Crea tu piso",
                    systemImage: "house.fill",
                    description: "Serás el admin y podrás invitar a tus compañeros con un código."
                ) {
                    VStack(spacing: 14) {
                        RTextField(title: "Piso de la calle X", text: $householdName)

                        Button {
                            createHousehold()
                        } label: {
                            Text(isCreating ? "Creando..." : "Crear piso")
                        }
                        .buttonStyle(.rPrimary)
                        .disabled(isCreating || householdName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }

                RCard(
                    title: "Únete a un piso",
                    systemImage: "person.2.fill",
                    description: "Pide el código de invitación a un compañero."
                ) {
                    VStack(spacing: 14) {
                        RTextField(title: "ABC123", text: $inviteCode)
                            .onChange(of: inviteCode) { _, newValue in
                                inviteCode = String(newValue.uppercased().prefix(6))
                            }

                        Button {
                            joinHousehold()
                        } label: {
                            Text(isJoining ? "Uniéndote..." : "Unirme al piso")
                        }
                        .buttonStyle(.rSecondary)
                        .disabled(isJoining || inviteCode.isEmpty)
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(RTheme.destructive)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(20)
            .frame(maxWidth: 420)
            .frame(maxWidth: .infinity)
        }
        .background(RTheme.background)
        .scrollDismissesKeyboard(.interactively)
    }

    private func createHousehold() {
        let cleanName = householdName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return }

        errorMessage = nil
        isCreating = true
        Task {
            do {
                try await session.createHousehold(name: cleanName)
                isCreating = false
            } catch {
                isCreating = false
                errorMessage = error.localizedDescription
            }
        }
    }

    private func joinHousehold() {
        guard !inviteCode.isEmpty else { return }

        errorMessage = nil
        isJoining = true
        Task {
            do {
                try await session.joinHousehold(code: inviteCode)
                isJoining = false
            } catch {
                isJoining = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
