import Testing
@testable import RumisCore

@Suite("EmojiMatch")
struct EmojiMatchTests {
    @Test("matches chore keywords case/diacritic-insensitively")
    func matchesChoreKeywords() {
        #expect(EmojiMatch.choreEmoji("Sacar la BASURA") == "🗑️")
        #expect(EmojiMatch.choreEmoji("Limpiar el baño") == "🚽")
        #expect(EmojiMatch.choreEmoji("Algo sin match") == "🧹")
    }

    @Test("matches grocery keywords")
    func matchesGroceryKeywords() {
        #expect(EmojiMatch.groceryEmoji("Leche entera") == "🥛")
        #expect(EmojiMatch.groceryEmoji("Papel higiénico") == "🧻")
        #expect(EmojiMatch.groceryEmoji("Algo raro") == "🛒")
    }
}
