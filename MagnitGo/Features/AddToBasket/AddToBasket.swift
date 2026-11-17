import Foundation

// Feature: the shopper confirms a scanned product and it joins the basket.

extension AppState {
    /// Adds `qty` units of a scanned product. Weighed goods and marked drinks are always
    /// one: the weight is on the label, and every bottle has its own code.
    @discardableResult
    func add(_ item: ScannedItem, qty: Int = 1) -> BasketLine {
        removed = nil
        let count = (item.grams != nil || item.mark != nil) ? 1 : max(1, qty)

        // More of a product already in the basket joins its line, which moves to the top.
        if item.grams == nil,
           let index = basket.firstIndex(where: { $0.product == item.product && $0.grams == nil }) {
            var line = basket.remove(at: index)
            line.qty += count
            if let mark = item.mark { line.marks.append(mark) }
            basket.insert(line, at: 0)
            lastAddedID = line.id
            return line
        }

        let line = BasketLine(id: UUID(), product: item.product, qty: count, grams: item.grams,
                              marks: item.mark.map { [$0] } ?? [])
        basket.insert(line, at: 0)
        lastAddedID = line.id
        return line
    }

    /// Scan and add in one step, without the product window. Only for the debug
    /// shortcut that fills a demo basket.
    @discardableResult
    func scanAndAdd(_ code: String) -> BasketLine? {
        guard case .found(let item) = check(code) else { return nil }
        return add(item)
    }

    /// How many of this product the basket already holds (piece goods only).
    func quantityInBasket(_ product: Product) -> Int {
        basket.first { $0.product == product && $0.grams == nil }?.qty ?? 0
    }
}
