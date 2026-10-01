import SwiftUI

/// Edit-chore sheet: pre-fills ChoreFormFields from an existing chore and
/// persists via updateChore on submit. Mirrors chore-row-actions.tsx's
/// edit dialog.
struct EditChoreSheet: View {
    let chore: Chore
    let members: [HouseholdMember]
    let onSave: () async -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var description: String
    @State private var recurrenceDays: Int
    @State private var rotationOrder: [UUID]
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let repo = ChoresRepository()

    init(chore: Chore, members: [HouseholdMember], onSave: @escaping () async -> Void) {
        self.chore = chore
        self.members = members
        self.onSave = onSave
        _name = State(initialValue: chore.name)
        _description = State(initialValue: chore.description ?? "")
        _recurrenceDays = State(initialValue: chore.recurrenceDays)
        _rotationOrder = State(initialValue: chore.rotationOrder)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("El nuevo intervalo se aplica a partir del próximo turno.")
                        .font(.footnote)
                        .foregroundStyle(RTheme.mutedForeground)

                    ChoreFormFields(
                        name: $name,
                        description: $description,
                        recurrenceDays: $recurrenceDays,
                        rotationOrder: $rotationOrder,
                        members: members
                    )

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(RTheme.destructive)
                    }

                    Button {
                        Task { await save() }
                    } label: {
                        Text(isSaving ? "Guardando…" : "Guardar cambios")
                    }
                    .buttonStyle(.rPrimary)
                    .disabled(isSaving)
                }
                .padding(16)
            }
            .background(RTheme.background)
            .navigationTitle("Editar tarea")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }

    private func save() async {
        errorMessage = nil
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Ponle un nombre a la tarea."
            return
        }
        guard recurrenceDays > 0 else {
            errorMessage = "Indica cada cuántos días se repite."
            return
        }
        guard !rotationOrder.isEmpty else {
            errorMessage = "Elige quién forma parte de la rotación."
            return
        }

        isSaving = true
        defer { isSaving = false }

        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let fields = ChoreFieldsUpdate(
            name: trimmedName,
            description: trimmedDescription.isEmpty ? nil : trimmedDescription,
            recurrenceDays: recurrenceDays,
            rotationOrder: rotationOrder
        )

        do {
            try await repo.updateChore(id: chore.id, fields: fields)
            await onSave()
            dismiss()
        } catch {
            errorMessage = "No se ha podido actualizar la tarea: \(error.localizedDescription)"
        }
    }
}
