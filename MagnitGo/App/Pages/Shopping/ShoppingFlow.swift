import SwiftUI

enum Route: Hashable {
    /// The receipt with its QR: shown to the cashier, or paid in the app from here.
    case pay
    case paying(PayMethod)
    case success(Receipt)
}

/// Scanner, then the receipt with its QR, then done. One stack, so "back" always
/// returns to a basket that can still be edited.
struct ShoppingFlow: View {
    @Environment(AppState.self) private var app
    let close: () -> Void
    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            ScannerScreen(close: close, checkout: { path.append(.pay) })
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: Route.self) { route in
                    Group {
                        switch route {
                        case .pay: PayScreen(path: $path)
                        case .paying(let method): PayingScreen(method: method, path: $path)
                        case .success(let receipt): SuccessScreen(receipt: receipt, close: close)
                        }
                    }
                    .toolbar(.hidden, for: .navigationBar)
                    .navigationBarBackButtonHidden()
                }
        }
        .onAppear {
            // Debug shortcuts for checking screens: -demoBasket fills a basket,
            // -route <pay|success> opens that screen directly.
            let args = ProcessInfo.processInfo.arguments
            guard path.isEmpty else { return }
            if args.contains("-demoBasket"), app.basket.isEmpty {
                Catalog.demoShelf.prefix(6).forEach { app.scanAndAdd(Catalog.demoCode($0)) }
                app.scanAndAdd(Catalog.demoShelf[0])
                app.scanAndAdd(Catalog.demoCode(Catalog.demoShelf[2]))
            }
            if let index = args.firstIndex(of: "-route"), index + 1 < args.count {
                switch args[index + 1] {
                case "pay": path = [.pay]
                case "success": path = [.success(app.completePurchase(method: .payme))]
                default: break
                }
            }
        }
    }
}
