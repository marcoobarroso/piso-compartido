import Testing
@testable import RumisCore
import Foundation

@Suite("InviteLink")
struct InviteLinkTests {
    @Test("extracts the code from a join link")
    func extractsCode() {
        #expect(InviteLink.inviteCode(from: URL(string: "https://piso-compartido.vercel.app/join/AB12CD")!) == "AB12CD")
    }

    @Test("ignores unrelated links")
    func ignoresUnrelatedLinks() {
        #expect(InviteLink.inviteCode(from: URL(string: "https://piso-compartido.vercel.app/household")!) == nil)
        #expect(InviteLink.inviteCode(from: URL(string: "https://piso-compartido.vercel.app/join/")!) == nil)
        #expect(InviteLink.inviteCode(from: URL(string: "https://piso-compartido.vercel.app/")!) == nil)
    }
}
