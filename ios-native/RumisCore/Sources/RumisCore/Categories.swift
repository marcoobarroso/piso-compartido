import Foundation

/// Mirrors lib/categories.ts. Icons map to SF Symbols in the design-system
/// layer, not here — this type only carries the data the web app also keeps
/// framework-agnostic.
public enum ExpenseCategory: String, CaseIterable, Codable, Sendable {
    case comida, suministros, ocio, hogar, transporte, otros

    public var label: String {
        switch self {
        case .comida: return "Comida"
        case .suministros: return "Suministros"
        case .ocio: return "Ocio"
        case .hogar: return "Hogar"
        case .transporte: return "Transporte"
        case .otros: return "Otros"
        }
    }

    /// Same categorical palette used in Stats' charts, so a category reads as
    /// the same color everywhere in the app (and in the exported spreadsheet).
    public var hex: String {
        switch self {
        case .comida: return "#c2532c"
        case .suministros: return "#1f74a8"
        case .ocio: return "#8f7015"
        case .hogar: return "#6142b8"
        case .transporte: return "#457f3a"
        case .otros: return "#7d3fa3"
        }
    }
}
