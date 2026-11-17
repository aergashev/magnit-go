import SwiftUI

/// Pick the store you are standing in; locked while the basket has items.
struct StoreSheet: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss

    private var locked: Bool { app.itemCount > 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(app.t("Do‘konni tanlang", "Выберите магазин"))
                .font(.ui(28, .medium))
                .padding(.top, 32)
            // Says why the choice matters, or why it is unavailable right now.
            Text(locked
                 ? app.t("Savatda mahsulot bor. Do‘konni o‘zgartirish uchun avval xaridni yakunlang yoki savatni bo‘shating.",
                         "В корзине есть товары. Чтобы сменить магазин, завершите покупку или очистите корзину.")
                 : app.t("Narxlar do‘konga qarab farq qiladi, shuning uchun hozir turgan do‘koningizni tanlang.",
                         "Цены зависят от магазина, поэтому выберите тот, в котором вы сейчас."))
                .font(.ui(15))
                .foregroundStyle(Theme.text2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
                .padding(.bottom, 12)

            ForEach(AppState.stores, id: \.self) { store in
                Button {
                    app.setStore(store)
                    dismiss()
                } label: {
                    HStack {
                        Text(store).font(.ui(16))
                        Spacer()
                        if store == app.storeName {
                            IconView(.check, size: 18)
                        }
                    }
                    .frame(minHeight: 52)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(locked)
                .opacity(locked && store != app.storeName ? 0.4 : 1)
                .accessibilityIdentifier("store-\(store)")
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Theme.page)
        .foregroundStyle(Theme.text)
        .preferredColorScheme(.dark)
    }
}
