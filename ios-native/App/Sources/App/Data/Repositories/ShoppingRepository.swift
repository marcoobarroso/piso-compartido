import Foundation
import Supabase

struct ShoppingItemInsert: Encodable {
    let householdId: UUID
    let name: String
    let quantity: String?
    let addedBy: UUID
    let ownerUserId: UUID?
}

struct ShoppingItemCheckedUpdate: Encodable {
    var isChecked: Bool
    var checkedBy: UUID?
    var checkedAt: Date?
}

struct ShoppingItemFieldsUpdate: Encodable {
    var name: String
    var quantity: String?
}

struct ShoppingRepository {
    func fetchItems(householdId: UUID) async throws -> [ShoppingItem] {
        try await supabase.from("shopping_items")
            .select()
            .eq("household_id", value: householdId)
            .order("created_at", ascending: true)
            .execute()
            .value
    }

    func addItem(_ item: ShoppingItemInsert) async throws -> ShoppingItem {
        try await supabase.from("shopping_items")
            .insert(item)
            .select()
            .single()
            .execute()
            .value
    }

    func setChecked(id: UUID, isChecked: Bool, userId: UUID) async throws -> ShoppingItem {
        try await supabase.from("shopping_items")
            .update(ShoppingItemCheckedUpdate(isChecked: isChecked, checkedBy: isChecked ? userId : nil, checkedAt: isChecked ? Date() : nil))
            .eq("id", value: id)
            .select()
            .single()
            .execute()
            .value
    }

    func updateFields(id: UUID, name: String, quantity: String?) async throws -> ShoppingItem {
        try await supabase.from("shopping_items")
            .update(ShoppingItemFieldsUpdate(name: name, quantity: quantity))
            .eq("id", value: id)
            .select()
            .single()
            .execute()
            .value
    }

    func deleteItem(id: UUID) async throws {
        try await supabase.from("shopping_items").delete().eq("id", value: id).execute()
    }
}

/// Live-updates the shared/personal shopping list for changes made by OTHER
/// members (ShoppingView applies its own mutations locally already). Unlike
/// the web app's manual per-event merge, this just refetches everything on
/// any change — simpler and robust, at the cost of a slightly less
/// "optimistic" feel; revisit if that proves too chatty in practice.
@MainActor
final class ShoppingRealtimeSubscription {
    private var channel: RealtimeChannelV2?

    func subscribe(householdId: UUID, onChange: @escaping @Sendable () -> Void) async {
        await unsubscribe()
        let channel = supabase.channel("shopping-\(householdId.uuidString)")
        _ = channel.onPostgresChange(
            AnyAction.self,
            schema: "public",
            table: "shopping_items",
            filter: .eq("household_id", value: householdId)
        ) { _ in
            onChange()
        }
        self.channel = channel
        try? await channel.subscribeWithError()
    }

    func unsubscribe() async {
        guard let channel else { return }
        await supabase.removeChannel(channel)
        self.channel = nil
    }
}
