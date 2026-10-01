import Foundation

/// Mirrors lib/emoji-match.ts: keyword-based, diacritic/case-insensitive
/// emoji suggestion for chore and grocery-list item names.
public enum EmojiMatch {
    private static func normalize(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "es_ES"))
    }

    private static func match(_ text: String, dictionary: [([String], String)], fallback: String) -> String {
        let normalized = normalize(text)
        for (keywords, emoji) in dictionary {
            if keywords.contains(where: { normalized.contains($0) }) {
                return emoji
            }
        }
        return fallback
    }

    private static let choreDictionary: [([String], String)] = [
        (["basura", "reciclaje", "reciclar", "contenedor"], "🗑️"),
        (["cocina", "fogones", "horno"], "🍳"),
        (["bano", "wc", "retrete", "inodoro"], "🚽"),
        (["plato", "vajilla", "fregar", "lavavajillas"], "🍽️"),
        (["barrer", "escoba", "recoger"], "🧹"),
        (["aspirar", "aspiradora"], "🌀"),
        (["polvo", "limpiar", "limpieza"], "🧼"),
        (["ropa", "colada", "lavadora", "tender", "planchar"], "🧺"),
        (["planta", "regar", "jardin", "terraza"], "🪴"),
        (["ventana", "cristal", "espejo"], "🪟"),
        (["nevera", "frigorifico", "congelador"], "🧊"),
        (["compra", "supermercado"], "🛒"),
        (["mascota", "perro", "gato"], "🐾"),
    ]

    private static let groceryDictionary: [([String], String)] = [
        (["leche"], "🥛"),
        (["yogur", "yogures"], "🍮"),
        (["queso"], "🧀"),
        (["huevo"], "🥚"),
        (["mantequilla", "margarina"], "🧈"),
        (["pan", "baguette", "barra"], "🍞"),
        (["galleta"], "🍪"),
        (["chocolate", "cacao"], "🍫"),
        (["manzana"], "🍎"),
        (["platano", "banana"], "🍌"),
        (["naranja", "mandarina"], "🍊"),
        (["limon"], "🍋"),
        (["fresa"], "🍓"),
        (["uva"], "🍇"),
        (["tomate"], "🍅"),
        (["patata", "papa"], "🥔"),
        (["cebolla"], "🧅"),
        (["ajo"], "🧄"),
        (["zanahoria"], "🥕"),
        (["lechuga", "ensalada", "verdura"], "🥬"),
        (["pimiento"], "🫑"),
        (["fruta"], "🍎"),
        (["pollo"], "🍗"),
        (["carne", "ternera", "filete"], "🥩"),
        (["pescado", "salmon", "atun", "merluza"], "🐟"),
        (["marisco", "gamba"], "🦐"),
        (["arroz"], "🍚"),
        (["pasta", "macarron", "espagueti"], "🍝"),
        (["pizza"], "🍕"),
        (["agua"], "💧"),
        (["zumo"], "🧃"),
        (["cafe"], "☕"),
        (["te ", "infusion"], "🍵"),
        (["cerveza", "birra"], "🍺"),
        (["vino"], "🍷"),
        (["papel higienico", "papel de bano"], "🧻"),
        (["papel de cocina", "servilleta"], "🧻"),
        (["detergente", "jabon", "lavavajillas", "suavizante"], "🧴"),
        (["aceite"], "🫒"),
        (["sal"], "🧂"),
        (["azucar"], "🍬"),
        (["cereales"], "🥣"),
        (["congelado"], "🧊"),
        (["snack", "patatas fritas", "chips"], "🍟"),
        (["chuche", "golosina", "caramelo"], "🍬"),
    ]

    public static func choreEmoji(_ name: String) -> String {
        match(name, dictionary: choreDictionary, fallback: "🧹")
    }

    public static func groceryEmoji(_ name: String) -> String {
        match(name, dictionary: groceryDictionary, fallback: "🛒")
    }
}
