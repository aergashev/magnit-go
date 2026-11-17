import SwiftUI

/// Home: which store you are in, your cashback, how the app works (until the first
/// purchase), what you bought before, your past purchases, and one action.
struct MainView: View {
    @Environment(AppState.self) private var app
    @State private var shopping = false
    @State private var showsProfile = false
    @State private var showsStores = false
    @State private var opened: Receipt?
    @State private var browsing: Product?
    /// Set by a product window's "start scanning": the scanner opens once it has closed.
    @State private var scanAfterDismiss = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 12) {
                    LogoMark(size: 36)
                    // The store is detected, and can be corrected.
                    Button { showsStores = true } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            SectionLabel(app.t("Siz shu do‘kondasiz", "Вы в магазине"))
                            HStack(spacing: 6) {
                                Text(app.storeName).font(.ui(16, .medium))
                                IconView(.chevronDown, size: 16)
                                    .foregroundStyle(Theme.text3)
                            }
                        }
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(app.t("Do‘konni o‘zgartirish", "Сменить магазин"))
                    .accessibilityIdentifier("changeStore")
                    Spacer()
                    IconButton(icon: .user) { showsProfile = true }
                        .padding(.trailing, -12)
                        .accessibilityLabel(app.t("Profil", "Профиль"))
                        .accessibilityIdentifier("profile")
                }
                .frame(minHeight: 44)

                balance.padding(.top, 32)
                if !app.hasShopped { howItWorks.padding(.top, 32) }
                if !app.boughtBefore.isEmpty { boughtBefore.padding(.top, 32) }
                purchases.padding(.top, 32)
            }
            .padding(.horizontal, Theme.page)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .foregroundStyle(Theme.text)
        .background(Theme.bg.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) { action }
        .sheet(item: $opened) { receipt in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(app.t("Xarid cheki", "Чек покупки"))
                        .font(.ui(28, .medium))
                        .foregroundStyle(Theme.text)
                    PaidReceipt(receipt: receipt)
                }
                .padding(.horizontal, Theme.page)
                .padding(.top, 32)
                .padding(.bottom, 24)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationBackground(Theme.bg)
            .environment(app)
        }
        .sheet(item: $browsing, onDismiss: {
            if scanAfterDismiss {
                scanAfterDismiss = false
                shopping = true
            }
        }) { product in
            ProductScreen(product: product, mode: .browsing, close: { browsing = nil }, startScanning: {
                scanAfterDismiss = true
                browsing = nil
            })
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationBackground(Theme.bg)
            .environment(app)
        }
        .sheet(isPresented: $showsStores) {
            StoreSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationBackground(Theme.bg)
                .environment(app)
        }
        .sheet(isPresented: $showsProfile) {
            ProfileSheet()
                .presentationDetents([.height(340)])
                .presentationDragIndicator(.visible)
                .presentationBackground(Theme.bg)
                .environment(app)
        }
        .fullScreenCover(isPresented: $shopping) {
            ShoppingFlow(close: { shopping = false })
                .environment(app)
                .preferredColorScheme(.dark)
        }
        .onAppear {
            if ProcessInfo.processInfo.arguments.contains("-startShopping") { shopping = true }
        }
    }

    // MARK: Cashback

    private var balance: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel(app.t("Keshbek balansi", "Баланс кешбэка"))

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(app.number(app.points))
                    .font(.ui(56, .medium).monospacedDigit())
                    .tracking(-1)
                    .contentTransition(.numericText(value: Double(app.points)))
                Text(app.pointsUnit(app.points))
                    .font(.ui(20))
                    .foregroundStyle(Theme.text2)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("balance")

            Text(app.t("1 ball = 1 so‘m. To‘lov paytida ishlatishingiz mumkin",
                       "1 балл = 1 сум. Можно списать при оплате"))
                .font(.ui(14))
                .foregroundStyle(Theme.text2)
                .padding(.top, 4)

            if let next = app.nextTier {
                TierBar(progress: app.tierProgress)
                    .padding(.top, 20)
                Text(app.t("Hozir har xariddan \(percent(app.tier))% qaytadi. Yana \(app.money(app.remainingToNextTier)) xarid qilsangiz, \(percent(next))% bo‘ladi",
                           "Сейчас возвращается \(percent(app.tier))% с покупки. Ещё \(app.money(app.remainingToNextTier)) покупок, и станет \(percent(next))%"))
                    .font(.ui(14))
                    .foregroundStyle(Theme.text2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)
            } else {
                Text(app.t("Har xariddan \(percent(app.tier))% qaytadi", "Возвращается \(percent(app.tier))% с каждой покупки"))
                    .font(.ui(14))
                    .foregroundStyle(Theme.text2)
                    .padding(.top, 12)
            }
        }
    }

    // MARK: How it works

    private var howItWorks: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(app.t("Qanday ishlaydi", "Как это работает"))
            step(1,
                 app.t("Mahsulotlarni skanerlang", "Сканируйте товары"),
                 app.t("Shtrix-kodini telefon bilan o‘qiting, mahsulotni ko‘rib savatga qo‘shing",
                       "Считайте штрихкод телефоном, посмотрите товар и добавьте его в корзину"))
            step(2,
                 app.t("Kassirga bitta QR ko‘rsating", "Покажите кассиру один QR"),
                 app.t("Hamma mahsulot kassaga o‘tadi. Yoki ilovada Payme, Click, Uzum orqali to‘lang",
                       "Все товары попадут на кассу. Или оплатите в приложении через Payme, Click, Uzum"))
            step(3,
                 app.t("Keshbek oling", "Получите кешбэк"),
                 app.t("Ballar xariddan keyin o‘zi qo‘shiladi", "Баллы начислятся сами после покупки"))
        }
        .accessibilityIdentifier("howItWorks")
    }

    private func step(_ number: Int, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("\(number)")
                .font(.ui(16, .medium).monospacedDigit())
                .foregroundStyle(Theme.text3)
                .frame(width: 16, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.ui(16, .medium))
                Text(detail)
                    .font(.ui(14))
                    .foregroundStyle(Theme.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Bought before

    /// Products from past receipts, each once, newest first. A card opens the product
    /// window; adding still happens by scanning.
    private var boughtBefore: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(app.t("Oldin olganlaringiz", "Вы уже покупали"))
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(app.boughtBefore) { product in
                        Button {
                            Haptics.tap()
                            browsing = product
                        } label: {
                            productCard(product)
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint(app.t("Mahsulot haqida", "О товаре"))
                        .accessibilityIdentifier("bought-\(product.id)")
                    }
                }
                .padding(.horizontal, Theme.page)
            }
            .scrollIndicators(.hidden)
            .padding(.horizontal, -Theme.page)
        }
        .accessibilityIdentifier("boughtBefore")
    }

    private func productCard(_ product: Product) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ProductPhoto(product: product, size: 84)
                .frame(width: 128, height: 112)
                .background(Theme.raised, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            Text(app.name(product))
                .font(.ui(14))
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.leading)
            Text(app.unitPrice(product))
                .font(.ui(14, .medium).monospacedDigit())
                .lineLimit(1)
        }
        .frame(width: 128, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    // MARK: Purchases

    private var purchases: some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionLabel(app.t("Xaridlar tarixi", "История покупок"))

            if app.history.isEmpty {
                Text(app.t("Hali xarid yo‘q", "Покупок пока нет"))
                    .font(.ui(16))
                    .foregroundStyle(Theme.text2)
                    .padding(.top, 8)
            }

            ForEach(app.history) { receipt in
                Button { opened = receipt } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(app.date(receipt.date, withTime: false)).font(.ui(16))
                            Text(app.itemsText(receipt.itemCount))
                                .font(.ui(13))
                                .foregroundStyle(Theme.text3)
                        }
                        Spacer(minLength: 12)
                        Text(app.money(receipt.total)).font(.ui(16).monospacedDigit())
                        IconView(.chevronRight, size: 16)
                            .foregroundStyle(Theme.text3)
                    }
                    .frame(minHeight: 56)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("receipt-\(receipt.code)")
            }
        }
    }

    // MARK: Action

    /// With a basket in progress its receipt is already printing: it shows above the button.
    private var action: some View {
        VStack(spacing: 0) {
            if app.itemCount > 0 {
                Paper(tornTop: true) {
                    ReceiptRow(label: app.t("Savatda: \(app.itemsText(app.itemCount))", "В корзине: \(app.itemsText(app.itemCount))"),
                               value: app.money(app.subtotal))
                }
                .padding(.horizontal, 12)
                .accessibilityIdentifier("basketSlip")
            }
            Button {
                Haptics.tap()
                shopping = true
            } label: {
                HStack(spacing: 8) {
                    IconView(.scan)
                    Text(app.itemCount > 0
                         ? app.t("Xaridni davom ettirish", "Продолжить покупку")
                         : app.t("Skanerlashni boshlash", "Начать сканировать"))
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .accessibilityIdentifier("startShopping")
        }
        .padding(.horizontal, Theme.page)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(Theme.bg)
    }

    private func percent(_ tier: Tier) -> Int { Int(tier.rate * 100) }
}
