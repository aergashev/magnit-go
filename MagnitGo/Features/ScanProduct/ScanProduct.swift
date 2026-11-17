import Foundation

// Feature: read a code and say what it is. Nothing is added here: the shopper sees the
// product first and confirms it (Features/AddToBasket).

/// What a scanned code means for the basket, before anything is added.
enum ScanCheck {
    case found(ScannedItem)
    case unknown
    /// The barcode of a drink that has to be sold by its marking code.
    case needsMark(Product)
    /// This exact unit is already in the basket.
    case duplicateMark
}

extension AppState {
    func check(_ code: String) -> ScanCheck {
        guard let item = Catalog.resolve(code) else { return .unknown }

        // A marked drink is sold unit by unit: the till needs each bottle's own code.
        if item.product.marked, item.mark == nil { return .needsMark(item.product) }
        if let mark = item.mark, basket.contains(where: { $0.marks.contains(mark) }) {
            return .duplicateMark
        }
        return .found(item)
    }
}
