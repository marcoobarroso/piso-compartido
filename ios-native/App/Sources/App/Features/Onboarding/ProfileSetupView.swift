import SwiftUI

/// Mirrors app/profile/setup/page.tsx + profile-setup-form.tsx: shown by the
/// coordinator while AppSession.route == .needsProfile.
struct ProfileSetupView: View {
    @Environment(AppSession.self) private var session

    @State private var name = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            RCard(
                title: "¿Cómo te llamamos?",
                description: "Tus compañeros de piso verán este nombre en los gastos y tareas."
            ) {
                VStack(spacing: 14) {
                    RTextField(title: "Marc", text: $name, textContentType: .name)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(RTheme.destructive)
                    }

                    Button {
                        save()
                    } label: {
                        Text(isLoading ? "Guardando..." : "Guardar")
                    }
                    .buttonStyle(.rPrimary)
                    .disabled(isLoading || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(20)
            .frame(maxWidth: 420)
            .frame(maxWidth: .infinity)
        }
        .background(RTheme.background)
        .scrollDismissesKeyboard(.interactively)
        .task { AnalyticsConfig.screen("ProfileSetup") }
    }

    private func save() {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return }

        errorMessage = nil
        isLoading = true
        Task {
            do {
                try await session.completeProfileSetup(name: cleanName)
                isLoading = false
                AnalyticsConfig.track("profile_completed")
            } catch {
                isLoading = false
                errorMessage = "No se ha podido guardar: \(error.localizedDescription)"
            }
        }
    }
}
