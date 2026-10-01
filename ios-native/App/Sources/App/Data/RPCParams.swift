import Foundation

// Postgres RPC parameter names are underscore-prefixed (e.g. `_household_id`)
// per supabase/migrations/*.sql, so every payload spells out CodingKeys
// explicitly instead of relying on the client's convertToSnakeCase strategy.

struct NameParams: Encodable {
    let name: String
    enum CodingKeys: String, CodingKey { case name = "_name" }
}

struct InviteCodeParams: Encodable {
    let inviteCode: String
    enum CodingKeys: String, CodingKey { case inviteCode = "_invite_code" }
}

struct HouseholdIdParams: Encodable {
    let householdId: UUID
    enum CodingKeys: String, CodingKey { case householdId = "_household_id" }
}

struct RemoveMemberParams: Encodable {
    let householdId: UUID
    let userId: UUID
    enum CodingKeys: String, CodingKey {
        case householdId = "_household_id"
        case userId = "_user_id"
    }
}

struct PushTokenParams: Encodable {
    let token: String
    let platform: String
    enum CodingKeys: String, CodingKey {
        case token = "_token"
        case platform = "_platform"
    }
}

struct TokenOnlyParams: Encodable {
    let token: String
    enum CodingKeys: String, CodingKey { case token = "_token" }
}
