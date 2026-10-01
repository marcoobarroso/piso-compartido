import SwiftUI

/// Settings sheet mirroring app/household/page.tsx's bottom section:
/// rename the household, manage the invite code, manage members, and the
/// leave/sign-out/delete-account/privacy actions. `session.household`/
/// `.membership` can go nil mid-sign-out (this sheet can still be on
/// screen when that happens), so every use below guards optionally
/// instead of force-unwrapping.
struct AccountSettingsView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    private let householdRepo = HouseholdRepository()

    @State private var householdNameDraft = ""
    @State private var savingName = false

    @State private var errorMessage: String?

    @State private var showRegenerateConfirm = false
    @State private var regenerating = false

    @State private var memberToRemove: HouseholdMember?
    @State private var removingMember = false

    @State private var showLeaveConfirm = false
    @State private var leaving = false

    @State private var showDeleteConfirm = false
    @State private var deleting = false

    @State private var signingOut = false

    private var isDemo: Bool { session.household?.inviteCode == "DEMO01" }
    private var isAdmin: Bool { session.membership?.isAdmin == true }

    /// Same contact address already published in the privacy policy/terms.
    private var feedbackURL: URL? {
        var components = URLComponents(string: "mailto:marcbarro.07@gmail.com")
        components?.queryItems = [URLQueryItem(name: "subject", value: "Sugerencia sobre Rumis")]
        return components?.url
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundStyle(RTheme.destructive)
                    }

                    if isDemo {
                        RCard(
                            title: "Cuenta de demostración",
                            systemImage: "eye",
                            description: "Estás en la cuenta de demostración — las acciones que cambian el piso están desactivadas aquí."
                        ) {
                            EmptyView()
                        }
                    } else {
                        if isAdmin {
                            renameCard
                        }
                        inviteCodeCard
                        membersCard
                        leaveCard
                    }

                    signOutCard

                    if !isDemo {
                        deleteAccountCard
                    }

                    NavigationLink {
                        PrivacyView()
                    } label: {
                        RCard(title: "Política de privacidad", systemImage: "hand.raised.fill") {
                            EmptyView()
                        }
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        TermsView()
                    } label: {
                        RCard(title: "Términos de servicio", systemImage: "doc.text.fill") {
                            EmptyView()
                        }
                    }
                    .buttonStyle(.plain)

                    if let feedbackURL {
                        Link(destination: feedbackURL) {
                            RCard(title: "Enviar sugerencia", systemImage: "envelope.fill") {
                                EmptyView()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .background(RTheme.background)
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .task {
                householdNameDraft = session.household?.name ?? ""
            }
        }
    }

    // MARK: - Rename

    private var renameCard: some View {
        RCard(title: "Nombre del piso", systemImage: "house.fill") {
            HStack(spacing: 8) {
                RTextField(title: "Nombre del piso", text: $householdNameDraft)
                Button(savingName ? "..." : "Guardar") {
                    Task { await saveName() }
                }
                .buttonStyle(.rSecondary)
                .frame(width: 100)
                .disabled(savingName || householdNameDraft.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private func saveName() async {
        guard let household = session.household else { return }
        let name = householdNameDraft.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        savingName = true
        errorMessage = nil
        defer { savingName = false }
        do {
            try await householdRepo.renameHousehold(id: household.id, name: name)
            await session.refresh()
        } catch {
            errorMessage = "No se ha podido renombrar el piso: \(error.localizedDescription)"
        }
    }

    // MARK: - Invite code

    private var inviteCodeCard: some View {
        RCard(
            title: "Invita a tus compañeros",
            systemImage: "person.badge.plus",
            description: "Comparte este código con quien quieras invitar"
        ) {
            HStack {
                Text(session.household?.inviteCode ?? "")
                    .font(.system(.title3, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(RTheme.primary)
                Spacer()
                if isAdmin {
                    Button {
                        showRegenerateConfirm = true
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.rSecondary)
                    .frame(width: 44)
                    .disabled(regenerating)
                    .accessibilityLabel("Regenerar código de invitación")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(RTheme.secondary)
            .clipShape(RoundedRectangle(cornerRadius: RTheme.Radius.sm))
        }
        .confirmationDialog(
            "Esto invalidará el código actual. ¿Seguro?",
            isPresented: $showRegenerateConfirm,
            titleVisibility: .visible
        ) {
            Button("Regenerar código", role: .destructive) {
                Task { await regenerateCode() }
            }
            Button("Cancelar", role: .cancel) {}
        }
    }

    private func regenerateCode() async {
        guard let household = session.household else { return }
        regenerating = true
        errorMessage = nil
        defer { regenerating = false }
        do {
            _ = try await householdRepo.regenerateInviteCode(householdId: household.id)
            await session.refresh()
        } catch {
            errorMessage = "No se ha podido regenerar el código: \(error.localizedDescription)"
        }
    }

    // MARK: - Members

    private var membersCard: some View {
        RCard(title: "Compañeros de piso", systemImage: "person.2.fill") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(session.members) { member in
                    HStack(spacing: 10) {
                        Text(member.profiles?.displayName ?? "Sin nombre")
                            .font(.subheadline)
                            .foregroundStyle(RTheme.cardForeground)
                        if member.isAdmin {
                            RBadge(text: "Admin", tint: RTheme.accentForeground, background: RTheme.accent)
                        }
                        Spacer()
                        if isAdmin && member.userId != session.userId {
                            Button("Quitar", role: .destructive) {
                                memberToRemove = member
                            }
                            .font(.caption)
                            .disabled(removingMember)
                        }
                    }
                }
            }
        }
        .confirmationDialog(
            "¿Echar a \(memberToRemove?.profiles?.displayName ?? "esta persona") del piso?",
            isPresented: Binding(
                get: { memberToRemove != nil },
                set: { if !$0 { memberToRemove = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Echar del piso", role: .destructive) {
                if let member = memberToRemove {
                    Task { await removeMember(member) }
                }
            }
            Button("Cancelar", role: .cancel) { memberToRemove = nil }
        }
    }

    private func removeMember(_ member: HouseholdMember) async {
        guard let household = session.household else { return }
        removingMember = true
        errorMessage = nil
        defer {
            removingMember = false
            memberToRemove = nil
        }
        do {
            try await householdRepo.removeMember(householdId: household.id, userId: member.userId)
            await session.refreshMembers()
        } catch {
            errorMessage = "No se ha podido echar a esa persona: \(error.localizedDescription)"
        }
    }

    // MARK: - Leave / sign out / delete

    private var leaveCard: some View {
        Button {
            showLeaveConfirm = true
        } label: {
            Text(leaving ? "Saliendo..." : "Salir del piso")
        }
        .buttonStyle(.rSecondary)
        .disabled(leaving)
        .confirmationDialog(
            "¿Seguro que quieres salir de este piso?",
            isPresented: $showLeaveConfirm,
            titleVisibility: .visible
        ) {
            Button("Salir del piso", role: .destructive) {
                Task { await leaveHousehold() }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Tus compañeros conservarán el historial de gastos.")
        }
    }

    private func leaveHousehold() async {
        leaving = true
        errorMessage = nil
        defer { leaving = false }
        do {
            try await session.leaveHousehold()
        } catch {
            errorMessage = "No se ha podido salir del piso: \(error.localizedDescription)"
        }
    }

    private var signOutCard: some View {
        Button {
            Task { await signOut() }
        } label: {
            Text(signingOut ? "Cerrando sesión..." : "Cerrar sesión")
        }
        .buttonStyle(.rSecondary)
        .disabled(signingOut)
    }

    private func signOut() async {
        signingOut = true
        errorMessage = nil
        defer { signingOut = false }
        do {
            try await session.signOut()
        } catch {
            errorMessage = "No se ha podido cerrar sesión: \(error.localizedDescription)"
        }
    }

    private var deleteAccountCard: some View {
        Button {
            showDeleteConfirm = true
        } label: {
            Text(deleting ? "Borrando cuenta..." : "Borrar mi cuenta")
        }
        .buttonStyle(.rDestructive)
        .disabled(deleting)
        .confirmationDialog(
            "Esto borrará tu cuenta permanentemente. No se puede deshacer.",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Borrar mi cuenta para siempre", role: .destructive) {
                Task { await deleteAccountAction() }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Saldrás de tu piso, se eliminará tu correo y no podrás recuperar la cuenta. Tus compañeros conservarán el historial de gastos, con tu nombre anonimizado.")
        }
    }

    private func deleteAccountAction() async {
        deleting = true
        errorMessage = nil
        defer { deleting = false }
        do {
            try await householdRepo.deleteAccount()
            session.noteAccountDeleted()
            try await session.signOut()
        } catch {
            errorMessage = "No se ha podido borrar la cuenta: \(error.localizedDescription)"
        }
    }
}
