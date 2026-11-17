import SwiftUI

// A basket line on the cheque while it can still be changed, and the undo for removing one.

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
