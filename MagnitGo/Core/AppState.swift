import SwiftUI
import Observation

enum Lang: String, CaseIterable {
    case uz, ru

    var label: String { self == .uz ? "O‘zbekcha" : "Русский" }
    var short: String { self == .uz ? "UZ" : "RU" }
}

enum PayMethod: String, CaseIterable, Hashable {
    case cashier, payme, click, uzum

    static let inApp: [PayMethod] = [.payme, .click, .uzum]

    var title: String {
        switch self {
        case .cashier: return "Kassa"
        case .payme: return "Payme"
        case .click: return "Click"
        case .uzum: return "Uzum"
        }
    }
}

struct BasketLine: Identifiable, Hashable {
    let id: UUID
    let product: Product
    var qty: Int
    /// Set for goods scanned from a scale label.
    let grams: Int?
    /// One full marking code per unit, for drinks sold under digital marking.
    /// Their quantity is the number of codes scanned, never a typed number.
    var marks: [String] = []

    var isMarked: Bool { !marks.isEmpty }

    var total: Int {
        guard let grams else { return product.price * qty }
        let exact = Double(product.price) * Double(grams) / 1000
        return Int((exact / 10).rounded()) * 10
    }
}

struct Receipt: Identifiable, Hashable {
    let id: UUID
    let date: Date
    let lines: [BasketLine]
    let subtotal: Int
    let pointsUsed: Int
    let total: Int
    let earned: Int
    let method: PayMethod
    let code: String
    var store = AppState.stores[0]

    var itemCount: Int { lines.reduce(0) { $0 + $1.qty } }
}

/// Cashback rate by lifetime spend.
struct Tier: Equatable {
    let rate: Double
    let threshold: Int

    static let all = [
        Tier(rate: 0.01, threshold: 0),
        Tier(rate: 0.02, threshold: 1_000_000),
        Tier(rate: 0.03, threshold: 5_000_000),
    ]
}

enum ScanResult {
    case added(BasketLine)
    case unknown
    /// The barcode of a drink that has to be sold by its marking code.
    case needsMark(Product)
    /// This exact unit is already in the basket.
    case duplicateMark
}

struct RemovedLine: Equatable {
    let line: BasketLine
    let index: Int
    let token = UUID()
}

enum Route: Hashable {
    /// The receipt with its QR: shown to the cashier, or paid in the app from here.
    case pay
    case paying(PayMethod)
    case success(Receipt)
}

@Observable
final class AppState {
    // MARK: Session

    private(set) var lang: Lang
    private(set) var phone: String?
    private(set) var lastInAppMethod: PayMethod

    /// False until the first purchase: home explains how the app works until then.
    private(set) var hasShopped: Bool
    /// The welcome pages are shown once, before sign-in.
    private(set) var hasSeenWelcome: Bool

    var isSignedIn: Bool { phone != nil }
    /// Detected from location in production; the shopper can correct it, because
    /// prices belong to a store.
    static let stores = ["Magnit Chilonzor", "Magnit Yunusobod", "Magnit Sergeli", "Magnit Mirzo Ulug‘bek"]
    private(set) var storeName: String

    // MARK: Loyalty

    var points = 1_690
    var lifetimeSpend = 640_000

    // MARK: Basket

    var basket: [BasketLine] = []
    var lastAddedID: UUID?
    var removed: RemovedLine?
    var usePoints = false
    var basketCode = AppState.newCode()
    var history: [Receipt] = []

    init() {
        let defaults = UserDefaults.standard
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-resetState") {
            ["lang", "phone", "method", "shopped", "store", "welcomed"].forEach(defaults.removeObject)
        }
        lang = Lang(rawValue: defaults.string(forKey: "lang") ?? "") ?? .uz
        phone = defaults.string(forKey: "phone")
        hasShopped = defaults.bool(forKey: "shopped")
        hasSeenWelcome = defaults.bool(forKey: "welcomed")
        storeName = defaults.string(forKey: "store") ?? AppState.stores[0]
        lastInAppMethod = PayMethod(rawValue: defaults.string(forKey: "method") ?? "") ?? .payme
        history = AppState.seedHistory()
    }

    // MARK: Totals

    var itemCount: Int { basket.reduce(0) { $0 + $1.qty } }
    var subtotal: Int { basket.reduce(0) { $0 + $1.total } }
    var pointsApplied: Int { usePoints ? min(points, subtotal) : 0 }
    var total: Int { subtotal - pointsApplied }
    var cashbackEarned: Int { Int((Double(total) * tier.rate).rounded()) }

    var tier: Tier { Tier.all.last { $0.threshold <= lifetimeSpend } ?? Tier.all[0] }
    var nextTier: Tier? { Tier.all.first { $0.threshold > lifetimeSpend } }

    var tierProgress: Double {
        guard let next = nextTier else { return 1 }
        return Double(lifetimeSpend - tier.threshold) / Double(next.threshold - tier.threshold)
    }

    var remainingToNextTier: Int { max(0, (nextTier?.threshold ?? lifetimeSpend) - lifetimeSpend) }

    // MARK: Basket actions

    @discardableResult
    func scan(_ code: String) -> ScanResult {
        guard let item = Catalog.resolve(code) else { return .unknown }

        // A marked drink is sold unit by unit: the till needs each bottle's own code.
        if item.product.marked, item.mark == nil { return .needsMark(item.product) }
        if let mark = item.mark, basket.contains(where: { $0.marks.contains(mark) }) {
            return .duplicateMark
        }
        removed = nil

        // Another unit of a product already in the basket joins its line.
        if item.grams == nil,
           let index = basket.firstIndex(where: { $0.product == item.product && $0.grams == nil }) {
            var line = basket.remove(at: index)
            line.qty += 1
            if let mark = item.mark { line.marks.append(mark) }
            basket.insert(line, at: 0)
            lastAddedID = line.id
            return .added(line)
        }

        let line = BasketLine(id: UUID(), product: item.product, qty: 1, grams: item.grams,
                              marks: item.mark.map { [$0] } ?? [])
        basket.insert(line, at: 0)
        lastAddedID = line.id
        return .added(line)
    }

    /// Not available for marked drinks: another bottle means another code to scan.
    func increment(_ line: BasketLine) {
        guard let index = basket.firstIndex(where: { $0.id == line.id }), !basket[index].isMarked else { return }
        basket[index].qty += 1
    }

    /// Going below one removes the line. No confirmation: removal is undoable.
    func decrement(_ line: BasketLine) {
        guard let index = basket.firstIndex(where: { $0.id == line.id }) else { return }
        if basket[index].qty > 1 {
            basket[index].qty -= 1
            if basket[index].isMarked { basket[index].marks.removeLast() }
        } else {
            remove(line)
        }
    }

    func remove(_ line: BasketLine) {
        guard let index = basket.firstIndex(where: { $0.id == line.id }) else { return }
        basket.remove(at: index)
        let entry = RemovedLine(line: line, index: index)
        removed = entry
        if lastAddedID == line.id { lastAddedID = basket.first?.id }

        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(7))
            if self?.removed?.token == entry.token { self?.removed = nil }
        }
    }

    func undoRemove() {
        guard let entry = removed else { return }
        basket.insert(entry.line, at: min(entry.index, basket.count))
        lastAddedID = entry.line.id
        removed = nil
    }

    func completePurchase(method: PayMethod) -> Receipt {
        let receipt = Receipt(
            id: UUID(),
            date: .now,
            // Oldest first, the order a printed receipt has.
            lines: Array(basket.reversed()),
            subtotal: subtotal,
            pointsUsed: pointsApplied,
            total: total,
            earned: cashbackEarned,
            method: method,
            code: basketCode,
            store: storeName
        )
        points += receipt.earned - receipt.pointsUsed
        lifetimeSpend += receipt.total
        history.insert(receipt, at: 0)
        hasShopped = true
        UserDefaults.standard.set(true, forKey: "shopped")
        if method != .cashier {
            lastInAppMethod = method
            UserDefaults.standard.set(method.rawValue, forKey: "method")
        }

        basket = []
        lastAddedID = nil
        removed = nil
        usePoints = false
        basketCode = AppState.newCode()
        return receipt
    }

    func finishWelcome() {
        hasSeenWelcome = true
        UserDefaults.standard.set(true, forKey: "welcomed")
    }

    /// Products from past purchases, most recent first, each once.
    var boughtBefore: [Product] {
        var seen = Set<String>()
        return history.flatMap(\.lines).map(\.product).filter { seen.insert($0.id).inserted }
    }

    func about(_ product: Product) -> String { lang == .uz ? product.aboutUz : product.aboutRu }

    /// "14 990 so‘m" for a piece, "21 990 so‘m / kg" for goods sold by weight.
    func unitPrice(_ product: Product) -> String {
        product.weighted ? money(product.price) + " / " + t("kg", "кг") : money(product.price)
    }

    func setLang(_ value: Lang) {
        lang = value
        UserDefaults.standard.set(value.rawValue, forKey: "lang")
    }

    /// Only with an empty basket: what is in it was priced by the current store.
    func setStore(_ name: String) {
        guard basket.isEmpty else { return }
        storeName = name
        UserDefaults.standard.set(name, forKey: "store")
    }

    func signIn(phone digits: String) {
        phone = digits
        UserDefaults.standard.set(digits, forKey: "phone")
    }

    func signOut() {
        phone = nil
        UserDefaults.standard.removeObject(forKey: "phone")
        basket = []
        removed = nil
        usePoints = false
    }

    // MARK: Text

    func t(_ uz: String, _ ru: String) -> String { lang == .uz ? uz : ru }

    func name(_ product: Product) -> String { lang == .uz ? product.nameUz : product.nameRu }

    func number(_ value: Int) -> String {
        AppState.grouping.string(from: NSNumber(value: value)) ?? String(value)
    }

    func money(_ value: Int) -> String { number(value) + "\u{00A0}" + t("so‘m", "сум") }

    func pointsText(_ value: Int) -> String {
        number(value) + "\u{00A0}" + t("ball", plural(value, "балл", "балла", "баллов"))
    }

    func pointsUnit(_ value: Int) -> String { t("ball", plural(value, "балл", "балла", "баллов")) }

    func itemsText(_ count: Int) -> String {
        t("\(count) ta mahsulot", "\(count) " + plural(count, "товар", "товара", "товаров"))
    }

    /// One decimal, comma as the separator: "2,9".
    func decimal(_ value: Double) -> String {
        String(format: "%.1f", value).replacingOccurrences(of: ".", with: ",")
    }

    func weight(_ grams: Int) -> String {
        String(format: "%.3f", Double(grams) / 1000).replacingOccurrences(of: ".", with: ",") + " " + t("kg", "кг")
    }

    func detail(_ line: BasketLine) -> String {
        if let grams = line.grams {
            return weight(grams) + " × " + number(line.product.price)
        }
        return line.qty > 1 ? "\(line.qty) × " + number(line.product.price) : t("1 dona", "1 шт")
    }

    var flowSteps: [String] {
        [t("Skanerlash", "Сканирование"), t("To‘lov", "Оплата"), t("Tayyor", "Готово")]
    }

    func date(_ date: Date, withTime: Bool = true) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: lang == .uz ? "uz_Latn_UZ" : "ru_RU")
        formatter.setLocalizedDateFormatFromTemplate(withTime ? "d MMMM HH:mm" : "d MMMM")
        return formatter.string(from: date)
    }

    func formattedPhone() -> String {
        guard let phone else { return "" }
        return "+998 " + AppState.maskPhone(phone)
    }

    /// 934942526 → 93 494 25 26 (chunked so it can be read back, Miller).
    static func maskPhone(_ digits: String) -> String {
        var out = ""
        for (index, char) in digits.enumerated() {
            if [2, 5, 7].contains(index) { out.append(" ") }
            out.append(char)
        }
        return out
    }

    static func chunked(_ code: String) -> String {
        stride(from: 0, to: code.count, by: 4).map { offset -> String in
            let start = code.index(code.startIndex, offsetBy: offset)
            let end = code.index(start, offsetBy: 4, limitedBy: code.endIndex) ?? code.endIndex
            return String(code[start..<end])
        }.joined(separator: " ")
    }

    private func plural(_ n: Int, _ one: String, _ few: String, _ many: String) -> String {
        let mod10 = n % 10, mod100 = n % 100
        if mod10 == 1, mod100 != 11 { return one }
        if (2...4).contains(mod10), !(12...14).contains(mod100) { return few }
        return many
    }

    private static let grouping: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "\u{00A0}"
        formatter.usesGroupingSeparator = true
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    private static func newCode() -> String {
        String(format: "%08d", Int.random(in: 10_000_000...99_999_999))
    }

    private static func seedHistory() -> [Receipt] {
        func line(_ index: Int, _ qty: Int) -> BasketLine {
            BasketLine(id: UUID(), product: Catalog.pieces[index], qty: qty, grams: nil)
        }
        func weighed(_ index: Int, _ grams: Int) -> BasketLine {
            BasketLine(id: UUID(), product: Catalog.weighted[index], qty: 1, grams: grams)
        }
        func receipt(daysAgo: Int, hour: Int, minute: Int, lines: [BasketLine], method: PayMethod, code: String) -> Receipt {
            let subtotal = lines.reduce(0) { $0 + $1.total }
            let day = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now
            return Receipt(
                id: UUID(),
                date: Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day,
                lines: lines,
                subtotal: subtotal,
                pointsUsed: 0,
                total: subtotal,
                earned: Int((Double(subtotal) * 0.01).rounded()),
                method: method,
                code: code
            )
        }
        return [
            receipt(daysAgo: 2, hour: 19, minute: 42, lines: [line(0, 2), line(1, 1), weighed(0, 1_120), line(6, 1)], method: .payme, code: "48217730"),
            receipt(daysAgo: 6, hour: 8, minute: 15, lines: [line(8, 1), line(5, 2), line(4, 6)], method: .cashier, code: "30955512"),
            receipt(daysAgo: 9, hour: 20, minute: 3, lines: [line(2, 1), line(7, 2), weighed(2, 790), line(1, 2)], method: .click, code: "27401186"),
            receipt(daysAgo: 15, hour: 13, minute: 27, lines: [line(3, 2), line(0, 1), weighed(1, 1_460)], method: .cashier, code: "19630254"),
        ]
    }
}
