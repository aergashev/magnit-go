import Foundation

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

struct RemovedLine: Equatable {
    let line: BasketLine
    let index: Int
    let token = UUID()
}
