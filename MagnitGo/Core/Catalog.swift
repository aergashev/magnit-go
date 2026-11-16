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
}

/// What a scanned code resolved to.
struct ScannedItem {
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

/// Demo catalogue. In production this is the store's price list, fetched for the
/// store the shopper is standing in.
enum Catalog {
    static let pieces: [Product] = [
        Product(id: "4780000000017", nameUz: "Sut 3,2%, 1 l", nameRu: "Молоко 3,2%, 1 л", price: 14_990),
        Product(id: "4780000000024", nameUz: "Buxanka non", nameRu: "Хлеб «Буханка»", price: 4_500),
        Product(id: "4780000000031", nameUz: "Tuxum C1, 10 dona", nameRu: "Яйца С1, 10 шт", price: 16_990),
        Product(id: "4780000000048", nameUz: "Apelsin sharbati, 1 l", nameRu: "Сок апельсиновый, 1 л", price: 22_990, marked: true),
        Product(id: "4780000000055", nameUz: "Gazsiz suv, 1,5 l", nameRu: "Вода без газа, 1,5 л", price: 5_990, marked: true),
        Product(id: "4780000000062", nameUz: "Sutli shokolad, 90 g", nameRu: "Шоколад молочный, 90 г", price: 18_990),
        Product(id: "4780000000079", nameUz: "Golland pishlog'i, 200 g", nameRu: "Сыр голландский, 200 г", price: 32_990),
        Product(id: "4780000000086", nameUz: "Makaron, 400 g", nameRu: "Макароны, 400 г", price: 9_990),
        Product(id: "4780000000093", nameUz: "Eruvchan qahva, 95 g", nameRu: "Кофе растворимый, 95 г", price: 54_990),
    ]

    static let weighted: [Product] = [
        Product(id: "00017", nameUz: "Banan", nameRu: "Бананы", price: 21_990, weighted: true),
        Product(id: "00023", nameUz: "Qizil olma", nameRu: "Яблоки красные", price: 16_990, weighted: true),
        Product(id: "00031", nameUz: "Pomidor", nameRu: "Помидоры", price: 24_990, weighted: true),
    ]

    /// What the demo buttons "scan" where there is no camera. Scale labels carry the
    /// weight; for marked drinks `demoCode` turns the entry into a fresh marking code.
    static let demoShelf: [String] = [
        "4780000000017",
        scaleLabel(plu: "00017", grams: 842),
        "4780000000055",
        "4780000000024",
        "4780000000048",
        scaleLabel(plu: "00031", grams: 615),
        "4780000000031",
        "4780000000079",
        "4780000000062",
        scaleLabel(plu: "00023", grams: 1_204),
        "4780000000093",
        "4780000000086",
    ]

    /// With real products in hand during a demo, map any unknown retail barcode or
    /// marking code onto the demo catalogue so every scan lands. Turn off once a real
    /// price list is wired in.
    static let mapsUnknownBarcodesForDemo = true

    /// Scale labels use the in-store EAN-13 range: `21` + PLU (5) + grams (5) + check digit.
    static func scaleLabel(plu: String, grams: Int) -> String {
        let body = "21" + plu + String(format: "%05d", grams)
        return body + String(checkDigit(body))
    }

    /// The code a demo button sends. Each press on a marked drink is a different
    /// bottle, so it gets its own serial.
    static func demoCode(_ entry: String) -> String {
        guard let product = pieces.first(where: { $0.id == entry }), product.marked else { return entry }
        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789")
        let serial = String((0..<13).map { _ in alphabet.randomElement() ?? "A" })
        let check = String((0..<4).map { _ in alphabet.randomElement() ?? "A" })
        return "010" + entry + "21" + serial + String(MarkingCode.separator) + "93" + check
    }

    static func resolve(_ raw: String) -> ScannedItem? {
        // A marking code first: it also starts with digits, but is not a barcode.
        if let mark = MarkingCode(raw) {
            if let product = pieces.first(where: { $0.id == mark.ean13 }) {
                return ScannedItem(product: product, mark: mark.raw)
            }
            if mapsUnknownBarcodesForDemo {
                let drinks = pieces.filter(\.marked)
                let sum = mark.gtin.compactMap(\.wholeNumberValue).reduce(0, +)
                return ScannedItem(product: drinks[sum % drinks.count], mark: mark.raw)
            }
            return nil
        }

        let code = raw.filter(\.isNumber)

        if code.count == 13, code.hasPrefix("21") {
            let chars = Array(code)
            let plu = String(chars[2..<7])
            let grams = Int(String(chars[7..<12])) ?? 0
            if grams > 0, let product = weighted.first(where: { $0.id == plu }) {
                return ScannedItem(product: product, grams: grams)
            }
            return nil
        }

        if let product = pieces.first(where: { $0.id == code }) {
            return ScannedItem(product: product)
        }

        if mapsUnknownBarcodesForDemo, [8, 12, 13].contains(code.count) {
            // Unknown barcodes land on unmarked goods only, so a real product in hand
            // never dead-ends on "scan the marking code".
            let plain = pieces.filter { !$0.marked }
            let sum = code.compactMap(\.wholeNumberValue).reduce(0, +)
            return ScannedItem(product: plain[sum % plain.count])
        }
        return nil
    }

    private static func checkDigit(_ body: String) -> Int {
        let digits = body.compactMap(\.wholeNumberValue)
        let sum = digits.enumerated().reduce(0) { $0 + $1.element * ($1.offset.isMultiple(of: 2) ? 1 : 3) }
        return (10 - sum % 10) % 10
    }
}
