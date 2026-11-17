import SwiftUI

/// A basket line opened in its product window. The product travels with the route so
/// the window can still say what it was after the line is removed.
struct OpenedLine: Hashable {
    let id: UUID
    let product: Product
}

/// The whole receipt so far, every line still editable. A line's photo or name opens
/// its product window on top.
struct BasketSheet: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    let checkout: () -> Void
    @State private var path: [OpenedLine] = []

    var body: some View {
        NavigationStack(path: $path) {
            receipt
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: OpenedLine.self) { opened in
                    ProductScreen(product: opened.product, mode: .inBasket(opened.id), close: {
                        if !path.isEmpty { path.removeLast() }
                    })
                    .toolbar(.hidden, for: .navigationBar)
                }
        }
    }

    private var receipt: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                Text(app.t("Savat", "Корзина"))
                    .font(.ui(28, .medium))
                    .foregroundStyle(Theme.text)
                Text(app.t("Miqdorni o‘zgartiring yoki mahsulotni o‘chiring. Mahsulot haqida bilish uchun nomini bosing",
                           "Измените количество или удалите товар. Нажмите на название, чтобы узнать о товаре"))
                    .font(.ui(15))
                    .foregroundStyle(Theme.text2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 12)

                Paper(tornTop: true) {
                    ReceiptHeader(detail: app.itemsText(app.itemCount))
                    ReceiptRule().padding(.vertical, 12)

                    if app.basket.isEmpty {
                        Text(app.t("Savat bo‘sh", "Корзина пуста")).font(.paper(16))
                    } else {
                        // Newest first: the item just scanned is the one most likely
                        // to need fixing.
                        VStack(spacing: 8) {
                            ForEach(app.basket) { line in
                                EditableLine(line: line, open: {
                                    Haptics.tap()
                                    path.append(OpenedLine(id: line.id, product: line.product))
                                })
                            }
                        }
                        ReceiptRule().padding(.vertical, 12)
                        VStack(spacing: 8) {
                            ReceiptRow(label: app.t("Jami", "Итого"), value: app.money(app.subtotal), total: true)
                            ReceiptRow(label: app.t("Keshbek qo‘shiladi", "Начислим кешбэк"),
                                       value: "+" + app.pointsText(app.cashbackEarned))
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.page)
            .padding(.top, 32)
            .padding(.bottom, 16)
            .animation(Theme.ease, value: app.basket.map(\.id))
        }
        .scrollIndicators(.hidden)
        .background(Theme.bg.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 8) {
                UndoBar()
                if app.basket.isEmpty {
                    Button(app.t("Skanerlashga qaytish", "Вернуться к сканеру")) { dismiss() }
                        .buttonStyle(SecondaryButtonStyle())
                } else {
                    Button(app.t("To‘lovga o‘tish", "К оплате"), action: checkout)
                        .buttonStyle(PrimaryButtonStyle())
                        .accessibilityIdentifier("sheetCheckout")
                }
            }
            .padding(.horizontal, Theme.page)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(Theme.bg)
            .animation(Theme.ease, value: app.removed)
        }
    }
}
