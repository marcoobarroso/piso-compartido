import Foundation

/// Equal vs. exact-amounts split, matching add-expense-form.tsx's two modes.
public enum SplitMode: String, CaseIterable, Sendable {
    case equal, custom
}

/// Parses/formats the euro-denominated text fields used across the expense
/// forms. Money is always Int cents internally per project convention —
/// this is the one place that bridges user-typed decimal strings (comma or
/// dot) to/from cents.
public enum MoneyParsing {
    public static func centsFromEuroString(_ text: String) -> Int? {
        let normalized = text.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        guard !normalized.isEmpty, let value = Double(normalized), value.isFinite, value >= 0 else { return nil }
        return Int((value * 100).rounded())
    }

    public static func euroString(fromCents cents: Int) -> String {
        String(format: "%.2f", Double(cents) / 100)
    }
}
