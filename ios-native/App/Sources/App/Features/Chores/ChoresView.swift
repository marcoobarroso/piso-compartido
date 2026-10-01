import SwiftUI
import RumisCore

/// Chores tab root: add-chore form, a Lista/Calendario/Historial segmented
/// view, and a "Gestionar tareas" section for editing/deleting chores.
/// Mirrors app/household/chores/page.tsx.
struct ChoresView: View {
    @Environment(AppSession.self) private var session

    private let choresRepo = ChoresRepository()

    @State private var chores: [Chore] = []
    @State private var assignments: [ChoreAssignment] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    @State private var selectedTab: ChoresTab = .list

    // Add-chore form state.
    @State private var newName = ""
    @State private var newDescription = ""
    @State private var newRecurrenceDays = 7
    @State private var newRotationOrder: [UUID] = []
    @State private var isSubmitting = false
    @State private var formError: String?

    @State private var choreToEdit: Chore?
    @State private var choreToDelete: Chore?
    @State private var deleteTrigger = 0

    private enum ChoresTab: String, CaseIterable, Identifiable, Hashable {
        case list = "Lista"
        case calendar = "Calendario"
        case history = "Historial"
        var id: String { rawValue }
    }

    private var memberNames: [UUID: String] {
        Dictionary(uniqueKeysWithValues: session.members.map { ($0.userId, $0.profiles?.displayName ?? "Sin nombre") })
    }

    var body: some View {
        // `session.household`/`.userId` can go briefly nil while signing
        // out; `tabContent` reads them directly, so guard instead of
        // force-unwrapping (force-unwrap here crashed on sign out).
        if let household = session.household, let userId = session.userId {
            content(householdId: household.id, userId: userId)
        } else {
            ProgressView()
                .tint(RTheme.primary)
        }
    }

    @ViewBuilder
    private func content(householdId: UUID, userId: UUID) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(RTheme.destructive)
                }

                addChoreCard

                RCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Picker("", selection: $selectedTab) {
                            ForEach(ChoresTab.allCases) { tab in
                                Text(tab.rawValue).tag(tab)
                            }
                        }
                        .pickerStyle(.segmented)

                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                        } else {
                            tabContent(householdId: householdId, userId: userId)
                        }
                    }
                }

                manageChoresCard
            }
            .padding(16)
        }
        .background(RTheme.background)
        .scrollDismissesKeyboard(.interactively)
        .task { await loadAll() }
        .refreshable { await loadAll() }
        .sensoryFeedback(.impact(weight: .light), trigger: deleteTrigger)
        .sheet(item: $choreToEdit) { chore in
            EditChoreSheet(chore: chore, members: session.members) {
                await loadAll()
            }
        }
        .confirmationDialog(
            "¿Borrar esta tarea?",
            isPresented: Binding(
                get: { choreToDelete != nil },
                set: { isPresented in if !isPresented { choreToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Borrar tarea", role: .destructive) {
                if let chore = choreToDelete {
                    Task { await delete(chore) }
                }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Se borra también su historial. No se puede deshacer.")
        }
    }

    @ViewBuilder
    private func tabContent(householdId: UUID, userId: UUID) -> some View {
        switch selectedTab {
        case .list:
            ChoresListTab(
                chores: chores,
                assignments: assignments,
                memberNames: memberNames,
                householdId: householdId,
                userId: userId,
                onCompleted: { completed, next in
                    withAnimation {
                        if let index = assignments.firstIndex(where: { $0.id == completed.id }) {
                            assignments[index] = completed
                        }
                        assignments.append(next)
                    }
                }
            )
        case .calendar:
            ChoresCalendarTab(chores: chores, assignments: assignments, memberNames: memberNames)
        case .history:
            ChoresHistoryTab(chores: chores, assignments: assignments, memberNames: memberNames)
        }
    }

    private var addChoreCard: some View {
        RCard(title: "Añadir tarea", systemImage: "checklist", description: "Elige entre quién se rota") {
            VStack(alignment: .leading, spacing: 12) {
                ChoreFormFields(
                    name: $newName,
                    description: $newDescription,
                    recurrenceDays: $newRecurrenceDays,
                    rotationOrder: $newRotationOrder,
                    members: session.members
                )

                if let formError {
                    Text(formError)
                        .font(.footnote)
                        .foregroundStyle(RTheme.destructive)
                }

                Button {
                    Task { await submitNewChore() }
                } label: {
                    HStack {
                        Image(systemName: "plus")
                        Text(isSubmitting ? "Creando…" : "Añadir tarea")
                    }
                }
                .buttonStyle(.rPrimary)
                .disabled(isSubmitting)
            }
        }
    }

    private var manageChoresCard: some View {
        RCard(
            title: "Gestionar tareas",
            systemImage: "list.bullet.clipboard",
            description: chores.isEmpty ? nil : "Edita o borra tareas existentes"
        ) {
            if chores.isEmpty {
                Text("Todavía no hay tareas domésticas. Añade la primera arriba.")
                    .font(.subheadline)
                    .foregroundStyle(RTheme.mutedForeground)
            } else {
                VStack(spacing: 10) {
                    ForEach(chores) { chore in
                        HStack(spacing: 10) {
                            Text(EmojiMatch.choreEmoji(chore.name))
                                .font(.system(size: 16))
                                .frame(width: 32, height: 32)
                                .background(RTheme.accent)
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(chore.name)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(RTheme.foreground)
                                Text("cada \(chore.recurrenceDays) día\(chore.recurrenceDays == 1 ? "" : "s") · \(chore.rotationOrder.count) persona\(chore.rotationOrder.count == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundStyle(RTheme.mutedForeground)
                            }

                            Spacer()

                            Button {
                                choreToEdit = chore
                            } label: {
                                Image(systemName: "pencil")
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(RTheme.mutedForeground)
                            .accessibilityLabel("Editar \(chore.name)")

                            Button {
                                choreToDelete = chore
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(RTheme.destructive)
                            .accessibilityLabel("Borrar \(chore.name)")
                        }
                    }
                }
            }
        }
    }

    private func loadAll() async {
        guard let householdId = session.household?.id else { return }
        errorMessage = nil
        do {
            async let choresResult = choresRepo.fetchChores(householdId: householdId)
            async let assignmentsResult = choresRepo.fetchAssignments(householdId: householdId)
            chores = try await choresResult
            assignments = try await assignmentsResult
        } catch {
            errorMessage = "No se han podido cargar las tareas: \(error.localizedDescription)"
        }
        isLoading = false
    }

    private func submitNewChore() async {
        guard let householdId = session.household?.id, let userId = session.userId else { return }
        formError = nil
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            formError = "Ponle un nombre a la tarea."
            return
        }
        guard newRecurrenceDays > 0 else {
            formError = "Indica cada cuántos días se repite."
            return
        }
        guard !newRotationOrder.isEmpty, let firstAssignee = newRotationOrder.first else {
            formError = "Elige quién forma parte de la rotación."
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }

        let calendar = Calendar.current
        let dueDate = calendar.date(byAdding: .day, value: newRecurrenceDays, to: Date()) ?? Date()
        let dueDateStr = Format.dateOnlyString(from: dueDate)

        let trimmedDescription = newDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let insert = ChoreInsert(
            householdId: householdId,
            name: trimmedName,
            description: trimmedDescription.isEmpty ? nil : trimmedDescription,
            recurrenceDays: newRecurrenceDays,
            rotationOrder: newRotationOrder,
            createdBy: userId
        )

        do {
            let (created, assignment) = try await choresRepo.addChore(insert, firstAssignee: firstAssignee, firstDueDate: dueDateStr)
            withAnimation {
                chores.append(created)
                assignments.append(assignment)
            }
            newName = ""
            newDescription = ""
            newRecurrenceDays = 7
            newRotationOrder = []
        } catch {
            formError = "No se ha podido crear la tarea: \(error.localizedDescription)"
        }
    }

    private func delete(_ chore: Chore) async {
        do {
            try await choresRepo.deleteChore(id: chore.id)
            withAnimation {
                chores.removeAll { $0.id == chore.id }
                assignments.removeAll { $0.choreId == chore.id }
            }
            deleteTrigger += 1
        } catch {
            errorMessage = "No se ha podido borrar la tarea: \(error.localizedDescription)"
        }
        choreToDelete = nil
    }
}
