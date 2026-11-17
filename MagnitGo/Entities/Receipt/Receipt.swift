import Foundation

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
