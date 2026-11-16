import SwiftUI

// The receipt is the one object that runs through the whole app: it feeds out of the
// scanner, carries the QR at the till, and is torn off and kept once paid.

/// Paper outline. A serrated edge is where the roll was torn.
struct PaperEdge: Shape {
    var tornTop: Bool
    var tornBottom: Bool

    func path(in rect: CGRect) -> Path {
        let depth: CGFloat = 4
        let count = max(1, Int((rect.width / 8).rounded()))
        let tooth = rect.width / CGFloat(count)
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.minY + (tornTop ? depth : 0)))
        if tornTop {
            for index in 0..<count {
                let x = rect.minX + CGFloat(index) * tooth
                path.addLine(to: CGPoint(x: x + tooth / 2, y: rect.minY))
                path.addLine(to: CGPoint(x: x + tooth, y: rect.minY + depth))
            }
        } else {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        }

        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - (tornBottom ? depth : 0)))
        if tornBottom {
            for index in 0..<count {
                let x = rect.maxX - CGFloat(index) * tooth
                path.addLine(to: CGPoint(x: x - tooth / 2, y: rect.maxY))
                path.addLine(to: CGPoint(x: x - tooth, y: rect.maxY - depth))
            }
        } else {
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        }
        path.closeSubpath()
        return path
    }
}

struct Paper<Content: View>: View {
    var tornTop = true
    var tornBottom = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0, content: content)
            .padding(.horizontal, 16)
            .padding(.top, tornTop ? 20 : 16)
            .padding(.bottom, tornBottom ? 20 : 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(Theme.ink)
            .background(PaperEdge(tornTop: tornTop, tornBottom: tornBottom).fill(Theme.paper))
    }
}

struct ReceiptHeader: View {
    @Environment(AppState.self) private var app
    let detail: String
    /// The store a past receipt was issued by; the current store when nil.
    var store: String?

    var body: some View {
        HStack(spacing: 12) {
            LogoMark(size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(store ?? app.storeName).font(.paper(15, .medium))
                Text(detail).font(.mono(12)).foregroundStyle(Theme.inkDim)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct ReceiptRule: View {
    var body: some View {
        Rectangle().fill(Theme.rule).frame(height: 1)
    }
}

/// Label on the left, figure in the price column on the right.
struct ReceiptRow: View {
    let label: String
    let value: String
    var total = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label)
                .font(.paper(total ? 17 : 15, total ? .medium : .regular))
                .lineLimit(1)
            Spacer(minLength: 8)
            Text(value)
                .font(.mono(total ? 20 : 15, total ? .medium : .regular))
                .lineLimit(1)
                .fixedSize()
        }
        .accessibilityElement(children: .combine)
    }
}

/// A printed line: name, how it was counted, price.
struct ReceiptLine: View {
    @Environment(AppState.self) private var app
    let line: BasketLine

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name(line.product)).font(.paper(15))
                Text(app.detail(line)).font(.mono(12)).foregroundStyle(Theme.inkDim)
            }
            Spacer(minLength: 8)
            Text(app.number(line.total)).font(.mono(15))
        }
        .accessibilityElement(children: .combine)
    }
}

/// A line that can still be changed. The controls sit on the line they change. With
/// `open`, the photo and name lead to the product's own window.
struct EditableLine: View {
    @Environment(AppState.self) private var app
    let line: BasketLine
    var open: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let open {
                Button(action: open) {
                    identity.contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint(app.t("Mahsulot haqida", "О товаре"))
                .accessibilityIdentifier("open-\(line.product.id)")
            } else {
                identity
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 0) {
                Text(app.number(line.total))
                    .font(.mono(16))
                    .contentTransition(.numericText(value: Double(line.total)))
                PaperStepper(line: line)
            }
        }
        .animation(Theme.easeFast, value: line.qty)
    }

    /// Photo, name, how it was counted.
    private var identity: some View {
        HStack(alignment: .top, spacing: 12) {
            ProductPhoto(product: line.product, size: 44)
            VStack(alignment: .leading, spacing: 4) {
                Text(app.name(line.product))
                    .font(.paper(16))
                    .multilineTextAlignment(.leading)
                Text(app.detail(line)).font(.mono(13)).foregroundStyle(Theme.inkDim)
                if line.isMarked {
                    // Says why this line has no plus.
                    Text(app.t("Yana bir shisha uchun uning kodini ham skanerlang",
                               "Ещё одна бутылка: отсканируйте и её код"))
                        .font(.paper(12))
                        .foregroundStyle(Theme.inkDim)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// Quantity controls for one line. On the cheque they are printed in ink; off it
/// (the product window) they are a graphite pill the height of the main button.
struct PaperStepper: View {
    @Environment(AppState.self) private var app
    let line: BasketLine
    var onPaper = true

    private var ink: Color { onPaper ? Theme.ink : Theme.text }

    var body: some View {
        HStack(spacing: 0) {
            if line.grams == nil {
                control(line.qty > 1 ? .minus : .trash, label: app.t("Kamaytirish", "Убавить"), id: "minus") {
                    app.decrement(line)
                }
                Text("\(line.qty)")
                    .font(onPaper ? Font.mono(15) : Font.ui(17, .medium).monospacedDigit())
                    .foregroundStyle(ink)
                    .frame(minWidth: 20)
                    .contentTransition(.numericText(value: Double(line.qty)))
                // Another marked bottle means another code to scan, so there is no plus.
                if !line.isMarked {
                    control(.plus, label: app.t("Ko‘paytirish", "Добавить"), id: "plus") {
                        app.increment(line)
                    }
                } else {
                    Color.clear.frame(width: 12)
                }
            } else {
                // The weight comes from the scale label, so the only edit is removing it.
                control(.trash, label: app.t("O‘chirish", "Удалить"), id: "remove") {
                    app.remove(line)
                }
            }
        }
        .frame(height: onPaper ? 44 : 52)
        .padding(.horizontal, onPaper ? 0 : 4)
        .background {
            if onPaper {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Theme.rule, lineWidth: 1)
                    .padding(.vertical, 4)
            } else {
                Capsule().fill(Theme.raised)
            }
        }
    }

    private func control(_ icon: Icon, label: String, id: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            IconView(icon, size: 18)
                .foregroundStyle(ink)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityIdentifier("\(id)-\(line.product.id)")
    }
}

/// A paid receipt, as kept in history and shown after payment.
struct PaidReceipt: View {
    @Environment(AppState.self) private var app
    let receipt: Receipt
    /// Collapse the lines to a count (used right after paying, where the QR matters more).
    var summarised = false
    /// Paid in the app: nobody at a till has seen the basket, so the guard checks this.
    var exitQR = false

    var body: some View {
        Paper(tornTop: true, tornBottom: true) {
            ReceiptHeader(detail: app.date(receipt.date) + "  № " + AppState.chunked(receipt.code), store: receipt.store)
            ReceiptRule().padding(.vertical, 12)

            if summarised {
                ReceiptRow(label: app.itemsText(receipt.itemCount), value: app.number(receipt.subtotal))
            } else {
                VStack(spacing: 10) {
                    ForEach(receipt.lines) { ReceiptLine(line: $0) }
                }
            }

            ReceiptRule().padding(.vertical, 12)

            VStack(spacing: 8) {
                if receipt.pointsUsed > 0 {
                    ReceiptRow(label: app.t("Ball bilan to‘landi", "Оплачено баллами"), value: "−" + app.number(receipt.pointsUsed))
                }
                ReceiptRow(label: app.t("Jami", "Итого"), value: app.money(receipt.total), total: true)
                ReceiptRow(label: app.t("To‘lov", "Оплата"),
                           value: receipt.method == .cashier ? app.t("kassada", "на кассе") : receipt.method.title)
                ReceiptRow(label: app.t("Keshbek qo‘shildi", "Начислено кешбэка"), value: "+" + app.pointsText(receipt.earned))
            }

            if exitQR {
                ReceiptRule().padding(.vertical, 12)
                VStack(spacing: 8) {
                    Text(app.t("Chiqishda shu QR-kodni ko‘rsating", "Покажите этот QR на выходе"))
                        .font(.paper(15, .medium))
                    QRView(payload: "MAGNITGO:PAID:\(receipt.code)")
                        .frame(width: 148, height: 148)
                }
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("exitPass")
            }
        }
    }
}

/// Removal is instant and undoable instead of asking "are you sure?".
struct UndoBar: View {
    @Environment(AppState.self) private var app

    var body: some View {
        if let entry = app.removed {
            HStack(spacing: 12) {
                Text(app.t("\(app.name(entry.line.product)) o‘chirildi", "\(app.name(entry.line.product)): удалено"))
                    .font(.ui(14))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Button {
                    Haptics.tap()
                    app.undoRemove()
                } label: {
                    Text(app.t("Qaytarish", "Вернуть"))
                        .font(.ui(14, .medium))
                        .foregroundStyle(Theme.text)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("undo")
            }
            .padding(.leading, 20)
            .padding(.trailing, 12)
            .background(Theme.raised, in: Capsule())
            .transition(.opacity)
        }
    }
}
