import Foundation

/// Parses the invite links shared from HouseholdHomeView
/// ("https://piso-compartido.vercel.app/join/<CODE>"), the same shape the
/// web's app/.well-known/apple-app-site-association and app/join/[code]
/// route handle as a Universal Link.
public enum InviteLink {
    public static func inviteCode(from url: URL) -> String? {
        let segments = url.pathComponents.filter { $0 != "/" }
        guard let joinIndex = segments.firstIndex(of: "join"),
              segments.index(after: joinIndex) < segments.count
        else { return nil }
        let code = segments[segments.index(after: joinIndex)]
        return code.isEmpty ? nil : code
    }
}
