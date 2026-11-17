import Foundation

struct Product: Identifiable, Hashable {
    /// EAN-13 for piece goods, 5-digit PLU for goods sold by weight.
    let id: String
    let nameUz: String
    let nameRu: String
    /// Per piece, or per kilogram when `weighted`.
    let price: Int
    var weighted = false
    /// Sold under mandatory digital marking (Asl Belgisi): every unit carries its own
    /// Data Matrix code, and that code, not the barcode, is what must be scanned.
    var marked = false
    /// Image name in Assets.xcassets/Products.
    var photo = ""
    var aboutUz = ""
    var aboutRu = ""
}

/// Energy and macronutrients, per 100 g (or per 100 ml for drinks), as printed on the pack.
struct Nutrition: Hashable {
    let kcal: Int
    let protein: Double
    let fat: Double
    let carbs: Double
}

/// What the pack says besides the name and price.
struct ProductFacts: Hashable {
    let nutrition: Nutrition
    /// Nutrition is per 100 ml rather than per 100 g.
    var perMl = false
    /// Nil for fresh produce, which has no ingredient list.
    var ingredientsUz: String?
    var ingredientsRu: String?
    let shelfLifeUz: String
    let shelfLifeRu: String
    let countryUz: String
    let countryRu: String
    /// Left empty in the demo rather than invented; the store's price list supplies it.
    var maker: String?
}

extension Product {
    var facts: ProductFacts? { Catalog.facts[id] }
}

/// What a scanned code resolved to. Each scan is its own item, even of the same product.
struct ScannedItem: Identifiable, Hashable {
    let id = UUID()
    let product: Product
    /// Grams read from a scale label; nil for piece goods.
    var grams: Int?
    /// The unit's full marking code, when a Data Matrix was scanned.
    var mark: String?
}

/// A GS1 marking code as printed on the unit: (01) product number, (21) serial, then a
/// check field the till validates. Only the first two are read here.
struct MarkingCode: Equatable {
    static let separator: Character = "\u{1D}"

    /// 14 digits.
    let gtin: String
    let serial: String
    /// The whole code as scanned. The till needs it intact to sell the unit.
    let raw: String

    /// The retail barcode the product number wraps.
    var ean13: String { gtin.hasPrefix("0") ? String(gtin.dropFirst()) : gtin }

    init?(_ scanned: String) {
        var code = scanned
        if code.hasPrefix("]d2") { code.removeFirst(3) }
        while code.first == Self.separator { code.removeFirst() }

        guard code.hasPrefix("01") else { return nil }
        let afterAI = code.dropFirst(2)
        let gtin = String(afterAI.prefix(14))
        guard gtin.count == 14, gtin.allSatisfy(\.isNumber) else { return nil }

        let rest = afterAI.dropFirst(14)
        guard rest.hasPrefix("21") else { return nil }
        let tail = rest.dropFirst(2)
        // The serial runs to the group separator. Scanners that drop the separator
        // leave it glued to the check field, so fall back to the 13 characters the
        // Asl Belgisi serial uses.
        let serial = tail.contains(Self.separator)
            ? String(tail.prefix { $0 != Self.separator })
            : String(tail.prefix(13))
        guard !serial.isEmpty else { return nil }

        self.gtin = gtin
        self.serial = serial
        self.raw = code
    }
}
