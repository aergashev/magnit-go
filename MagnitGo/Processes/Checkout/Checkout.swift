import Foundation

// Process: close a purchase. It spans the receipt, cashback and the session: the receipt
// is recorded, points are spent and earned, and a new empty basket starts.

extension AppState {
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
        markShopped()
        if method != .cashier { rememberInAppMethod(method) }
        startNewBasket()
        return receipt
    }
}
