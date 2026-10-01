import Foundation
import Supabase

struct HouseholdNameUpdate: Encodable {
    var name: String
}

struct HouseholdRepository {
    func createHousehold(name: String) async throws -> Household {
        try await supabase
            .rpc("create_household", params: NameParams(name: name))
            .execute()
            .value
    }

    func joinHousehold(inviteCode: String) async throws -> Household {
        try await supabase
            .rpc("join_household", params: InviteCodeParams(inviteCode: inviteCode))
            .execute()
            .value
    }

    func leaveHousehold(householdId: UUID) async throws {
        try await supabase
            .rpc("leave_household", params: HouseholdIdParams(householdId: householdId))
            .execute()
    }

    func removeMember(householdId: UUID, userId: UUID) async throws {
        try await supabase
            .rpc("remove_household_member", params: RemoveMemberParams(householdId: householdId, userId: userId))
            .execute()
    }

    func regenerateInviteCode(householdId: UUID) async throws -> String {
        try await supabase
            .rpc("regenerate_invite_code", params: HouseholdIdParams(householdId: householdId))
            .execute()
            .value
    }

    func renameHousehold(id: UUID, name: String) async throws {
        try await supabase.from("households")
            .update(HouseholdNameUpdate(name: name))
            .eq("id", value: id)
            .execute()
    }

    func fetchHousehold(id: UUID) async throws -> Household {
        try await supabase.from("households")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value
    }

    func fetchMembers(householdId: UUID) async throws -> [HouseholdMember] {
        try await supabase.from("household_members")
            .select("*, profiles(*)")
            .eq("household_id", value: householdId)
            .order("joined_at", ascending: true)
            .execute()
            .value
    }

    /// The app assumes one household per user (enforced server-side by
    /// join_household); this is how every screen resolves "my household".
    func fetchMyMembership(userId: UUID) async throws -> HouseholdMember? {
        try await supabase.from("household_members")
            .select()
            .eq("user_id", value: userId)
            .maybeSingle()
            .execute()
            .value
    }

    func deleteAccount() async throws {
        try await supabase.rpc("delete_my_account").execute()
    }
}
