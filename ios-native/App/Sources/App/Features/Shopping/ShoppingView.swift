import SwiftUI
import RumisCore

/// Mirrors app/household/shopping/{page.tsx,shopping-list.tsx}: an inline
/// add row, then three sections — the household's shared list, "my food",
/// and a read-only view of each other member's personal items.
struct ShoppingView: View {
    @Environment(AppSession.self) private var session

    private let repository = ShoppingRepository()

    @State private var items: [ShoppingItem] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var subscription = ShoppingRealtimeSubscription()

    @State private var newName = ""
    @State private var newQuantity = ""
    @State private var isSharedScope = true

    @State private var editingId: UUID?
    @State private var editName = ""
    @State private var editQuantity = ""

    @State private var toggleTrigger = 0
    @State private var deleteTrigger = 0

    // Optional, not force-unwrapped: `session.userId`/`.household` can go
    // briefly nil while signing out, and this view's body reads these
    // transitively (via mineItems/othersItems) — a force-unwrap here
    // crashed on sign out (same root cause as HouseholdHomeView's crash).
    private var currentUserId: UUID? { session.userId }
    private var householdId: UUID? { session.household?.id }

    private var memberNames: [UUID: String] {
        var dict: [UUID: String] = [:]
        for member in session.members {
            dict[member.userId] = member.profiles?.displayName ?? "tu compi"
        }
        return dict
    }

    private var sharedItems: [ShoppingItem] { items.filter { $0.isShared } }
    private var mineItems: [ShoppingItem] { items.filter { $0.ownerUserId == currentUserId } }
    private var othersItems: [ShoppingItem] {
        items.filter { $0.ownerUserId != nil && $0.ownerUserId != currentUserId }
    }

    private var othersByOwner: [(ownerId: UUID, items: [ShoppingItem])] {
        let grouped = Dictionary(grouping: othersItems) { $0.ownerUserId! }
        return grouped
            .map { (ownerId: $0.key, items: $0.value) }
            .sorted { (memberNames[$0.ownerId] ?? "") < (memberNames[$1.ownerId] ?? "") }
    }

    var body: some View {
        VStack(spacing: 0) {
            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(RTheme.destructive)
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if isLoading && items.isEmpty {
                Spacer()
                ProgressView()
                    .tint(RTheme.primary)
                Spacer()
            } else {
                list
            }
        }
        .background(RTheme.background)
        .navigationTitle("Lista de la compra")
        .task {
            await loadAll()
            guard let householdId else { return }
            await subscription.subscribe(householdId: householdId) {
                Task { @MainActor in
                    await refetchItems()
                }
            }
        }
        .refreshable { await loadAll() }
        .onDisappear {
            Task { await subscription.unsubscribe() }
        }
        .sensoryFeedback(.selection, trigger: toggleTrigger)
        .sensoryFeedback(.impact(weight: .light), trigger: deleteTrigger)
    }

    private var list: some View {
        List {
            addItemSection

            Section {
                if sharedItems.isEmpty {
                    emptyRow("Nada compartido en la lista todavía.")
                } else {
                    ForEach(sharedItems) { item in
                        row(for: item, editable: true)
                    }
                }
            } header: {
                Text("Compartido")
            }

            Section {
                if mineItems.isEmpty {
                    emptyRow("No has añadido comida personal.")
                } else {
                    ForEach(mineItems) { item in
                        row(for: item, editable: true)
                    }
                }
            } header: {
                Text("Mi comida")
            }

            ForEach(othersByOwner, id: \.ownerId) { group in
                Section {
                    ForEach(group.items) { item in
                        row(for: item, editable: false)
                    }
                } header: {
                    Text("De \(memberNames[group.ownerId] ?? "tu compi")")
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Add row

    private var addItemSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmedName.isEmpty {
                        Text(EmojiMatch.groceryEmoji(trimmedName))
                    }
                    RTextField(title: "Leche", text: $newName)
                        .onSubmit { Task { await addItem() } }
                    RTextField(title: "2L", text: $newQuantity)
                        .frame(width: 70)
                        .onSubmit { Task { await addItem() } }
                    Button {
                        Task { await addItem() }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(RTheme.primary)
                    }
                    .disabled(trimmedName.isEmpty)
                    .accessibilityLabel("Añadir a la lista")
                }

                Picker("Para quién", selection: $isSharedScope) {
                    Text("Compartido").tag(true)
                    Text("Solo para mí").tag(false)
                }
                .pickerStyle(.segmented)
                .tint(RTheme.primary)
            }
            .padding(.vertical, 4)
        }
        .listRowBackground(RTheme.card)
    }

    private func emptyRow(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(RTheme.mutedForeground)
            .listRowBackground(RTheme.card)
    }

    // MARK: - Rows

    @ViewBuilder
    private func row(for item: ShoppingItem, editable: Bool) -> some View {
        if editable && editingId == item.id {
            editingRow(for: item)
        } else {
            HStack(spacing: 10) {
                Button {
                    if editable {
                        Task { await toggleItem(item) }
                    }
                } label: {
                    Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundStyle(
                            item.isChecked
                                ? RTheme.primary
                                : (editable ? RTheme.mutedForeground : RTheme.mutedForeground.opacity(0.5))
                        )
                }
                .buttonStyle(.plain)
                .disabled(!editable)
                .accessibilityLabel(item.isChecked ? "Marcar sin comprar" : "Marcar comprado")

                Text(itemLabel(item))
                    .font(.subheadline)
                    .foregroundStyle(item.isChecked ? RTheme.mutedForeground : RTheme.foreground)
                    .strikethrough(item.isChecked)
                    .onTapGesture {
                        if editable { startEditing(item) }
                    }

                Spacer(minLength: 0)

                if editable {
                    Button {
                        startEditing(item)
                    } label: {
                        Image(systemName: "pencil")
                            .foregroundStyle(RTheme.mutedForeground)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Editar")

                    Button {
                        Task { await deleteItem(item) }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(RTheme.mutedForeground)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Quitar")
                }
            }
            .contentShape(Rectangle())
            .listRowBackground(RTheme.card)
            .swipeActions(edge: .trailing) {
                if editable {
                    Button(role: .destructive) {
                        Task { await deleteItem(item) }
                    } label: {
                        Label("Quitar", systemImage: "trash")
                    }
                }
            }
        }
    }

    private func editingRow(for item: ShoppingItem) -> some View {
        HStack(spacing: 8) {
            RTextField(title: "Nombre", text: $editName)
                .onSubmit { Task { await saveEditing(item.id) } }
            RTextField(title: "Cantidad", text: $editQuantity)
                .frame(width: 80)
                .onSubmit { Task { await saveEditing(item.id) } }
            Button {
                Task { await saveEditing(item.id) }
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(RTheme.primary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Guardar cambios")
            Button {
                cancelEditing()
            } label: {
                Image(systemName: "xmark.circle")
                    .foregroundStyle(RTheme.mutedForeground)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Cancelar")
        }
        .listRowBackground(RTheme.card)
    }

    private func itemLabel(_ item: ShoppingItem) -> String {
        let emoji = EmojiMatch.groceryEmoji(item.name)
        let quantity = item.quantity.map { " (\($0))" } ?? ""
        return "\(emoji) \(item.name)\(quantity)"
    }

    // MARK: - Data

    private func loadAll() async {
        guard let householdId else { return }
        isLoading = true
        errorMessage = nil
        do {
            items = try await repository.fetchItems(householdId: householdId)
        } catch {
            errorMessage = "No se ha podido cargar la lista de la compra: \(error.localizedDescription)"
        }
        isLoading = false
    }

    private func refetchItems() async {
        guard let householdId else { return }
        do {
            items = try await repository.fetchItems(householdId: householdId)
        } catch {
            errorMessage = "No se ha podido actualizar la lista: \(error.localizedDescription)"
        }
    }

    private func addItem() async {
        guard let householdId, let currentUserId else { return }
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        let trimmedQuantity = newQuantity.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            let created = try await repository.addItem(
                ShoppingItemInsert(
                    householdId: householdId,
                    name: trimmedName,
                    quantity: trimmedQuantity.isEmpty ? nil : trimmedQuantity,
                    addedBy: currentUserId,
                    ownerUserId: isSharedScope ? nil : currentUserId
                )
            )
            withAnimation {
                items.append(created)
            }
            newName = ""
            newQuantity = ""
        } catch {
            errorMessage = "No se ha podido añadir el artículo: \(error.localizedDescription)"
        }
    }

    private func toggleItem(_ item: ShoppingItem) async {
        guard let currentUserId else { return }
        do {
            let updated = try await repository.setChecked(id: item.id, isChecked: !item.isChecked, userId: currentUserId)
            if let index = items.firstIndex(where: { $0.id == item.id }) {
                items[index] = updated
            }
            toggleTrigger += 1
        } catch {
            errorMessage = "No se ha podido actualizar el artículo: \(error.localizedDescription)"
        }
    }

    private func deleteItem(_ item: ShoppingItem) async {
        do {
            try await repository.deleteItem(id: item.id)
            withAnimation {
                items.removeAll { $0.id == item.id }
            }
            deleteTrigger += 1
        } catch {
            errorMessage = "No se ha podido quitar el artículo: \(error.localizedDescription)"
        }
    }

    private func startEditing(_ item: ShoppingItem) {
        editingId = item.id
        editName = item.name
        editQuantity = item.quantity ?? ""
    }

    private func cancelEditing() {
        editingId = nil
    }

    private func saveEditing(_ id: UUID) async {
        let trimmedName = editName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        let trimmedQuantity = editQuantity.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            let updated = try await repository.updateFields(id: id, name: trimmedName, quantity: trimmedQuantity.isEmpty ? nil : trimmedQuantity)
            if let index = items.firstIndex(where: { $0.id == id }) {
                items[index] = updated
            }
            editingId = nil
        } catch {
            errorMessage = "No se ha podido guardar el cambio: \(error.localizedDescription)"
        }
    }
}
