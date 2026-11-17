import Foundation

/// What the till reads from the QR on the receipt: every code the shopper scanned, so
/// the cashier rescans nothing. The list travels in the QR itself, so it works with no
/// signal in the store and no lookup on the till's side.
///
///     MG1;<basket>;<window>;<points>;<item>,<item>,…
///
///     4780000000017x2     a barcode and its quantity
///     2100017008425       a scale label exactly as printed (the weight is inside it)
///     m<base64url>        one marked unit: its full marking code, check field included
///
/// `basket` identifies the receipt, `window` changes every 30 seconds so an old
/// screenshot can be told apart, `points` is the cashback the shopper chose to spend.
/// Prices are deliberately absent: the till prices the codes itself.
enum BasketQR {
    static func payload(basket: [BasketLine], code: String, window: Int, pointsApplied: Int) -> String {
        // Oldest first, the order the receipt shows.
        let items = basket.reversed().flatMap { line -> [String] in
            if let grams = line.grams {
                return [Catalog.scaleLabel(plu: line.product.id, grams: grams)]
            }
            if line.isMarked {
                return line.marks.map { "m" + base64url($0) }
            }
            return ["\(line.product.id)x\(line.qty)"]
        }
        return ["MG1", code, String(window), String(pointsApplied), items.joined(separator: ",")]
            .joined(separator: ";")
    }

    /// Marking codes contain separators and punctuation, so they are wrapped.
    private static func base64url(_ text: String) -> String {
        Data(text.utf8).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
