import Foundation
import Supabase

struct ProfileUpdate: Encodable {
    var displayName: String
}

struct ProfileRepository {
    func fetchProfile(id: UUID) async throws -> Profile {
        try await supabase.from("profiles")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value
    }

    func setDisplayName(_ name: String, userId: UUID) async throws {
        try await supabase.from("profiles")
            .update(ProfileUpdate(displayName: name))
            .eq("id", value: userId)
            .execute()
    }
}
