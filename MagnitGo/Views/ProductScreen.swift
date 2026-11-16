import SwiftUI

/// One product: its photo, name, price, what it is and how it is scanned.
///
/// Opened from a basket line it edits that line, with the same rules the cheque has:
/// marked drinks have no plus, weighed goods can only be removed. Opened from home it
/// has no "add" button, because nothing reaches the basket without a scan: the
/// marking code or the scale label is what the till sells.
struct ProductScreen: View {
    enum Mode: Equatable {
        case inBasket(UUID)
        case browsing
    }

    @Environment(AppState.self) private var app
    let product: Product
    let mode: Mode
    let close: () -> Void
    var startScanning: () -> Void = {}

    @State private var expanded = false
    @State private var truncated = false

    private var line: BasketLine? {
        guard case .inBasket(let id) = mode else { return nil }
        return app.basket.first { $0.id == id }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                photo
                details
                    .padding(.horizontal, Theme.page)
                    .padding(.top, 24)
            }
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .foregroundStyle(Theme.text)
        .background(Theme.bg.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
        .onChange(of: line == nil) { _, gone in
            // The line was removed here (or undone elsewhere): back to the basket,
            // where the undo bar is.
            if gone, mode != .browsing { close() }
        }
        .accessibilityIdentifier("productScreen")
    }

    // MARK: Photo

    /// The cut-out on a raised panel with a curved lower edge.
    private var photo: some View {
        ProductPhoto(product: product, size: 220)
            .frame(maxWidth: .infinity)
            .padding(.top, 64)
            .padding(.bottom, 32)
            .background(
                UnevenRoundedRectangle(bottomLeadingRadius: 40, bottomTrailingRadius: 40, style: .continuous)
                    .fill(Theme.raised)
                    .ignoresSafeArea(edges: .top)
            )
            .overlay(alignment: .topLeading) {
                IconButton(icon: mode == .browsing ? .close : .back, filled: true, action: close)
                    .padding(.leading, 16)
                    .padding(.top, 8)
                    .accessibilityLabel(mode == .browsing ? app.t("Yopish", "Закрыть") : app.t("Savatga qaytish", "Назад к корзине"))
                    .accessibilityIdentifier("productClose")
            }
    }

    // MARK: Details

    private var details: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(app.name(product))
                .font(.ui(28, .medium))
                .fixedSize(horizontal: false, vertical: true)

            SectionLabel(product.weighted ? app.t("1 kg narxi", "Цена за 1 кг") : app.t("1 dona narxi", "Цена за 1 шт"))
                .padding(.top, 16)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(app.number(product.price))
                    .font(.ui(40, .medium).monospacedDigit())
                    .tracking(-0.5)
                Text(product.weighted ? app.t("so‘m / kg", "сум / кг") : app.t("so‘m", "сум"))
                    .font(.ui(18))
                    .foregroundStyle(Theme.text2)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("productPrice")

            if !app.about(product).isEmpty {
                SectionLabel(app.t("Mahsulot haqida", "О товаре"))
                    .padding(.top, 24)
                about.padding(.top, 4)
            }

            if let facts = product.facts {
                nutrition(facts).padding(.top, 24)
                if let ingredients = app.lang == .uz ? facts.ingredientsUz : facts.ingredientsRu {
                    fact(app.t("Tarkibi", "Состав"), ingredients)
                }
                fact(app.t("Saqlash muddati", "Срок годности"), app.t(facts.shelfLifeUz, facts.shelfLifeRu))
                fact(app.t("Ishlab chiqarilgan mamlakat", "Страна производства"), app.t(facts.countryUz, facts.countryRu))
                if let maker = facts.maker {
                    fact(app.t("Ishlab chiqaruvchi", "Производитель"), maker)
                }
            }

            fact(app.t("Qanday skanerlanadi", "Как сканировать"), howToScan)
            fact(product.weighted ? app.t("Tarozi kodi (PLU)", "Код весов (PLU)") : app.t("Shtrix-kod", "Штрихкод"),
                 product.id)
        }
    }

    /// A labelled block of plain text.
    private func fact(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionLabel(label)
            Text(value)
                .font(.ui(16).monospacedDigit())
                .foregroundStyle(Theme.text2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 24)
        .accessibilityElement(children: .combine)
    }

    // MARK: Nutrition

    /// Energy and the three macronutrients side by side, each with its unit and name.
    private func nutrition(_ facts: ProductFacts) -> some View {
        let values = facts.nutrition
        let grams = app.t("g", "г")
        return VStack(alignment: .leading, spacing: 8) {
            SectionLabel(facts.perMl
                         ? app.t("Ozuqaviy qiymati, 100 ml da", "Пищевая ценность в 100 мл")
                         : app.t("Ozuqaviy qiymati, 100 g da", "Пищевая ценность в 100 г"))
            HStack(spacing: 8) {
                nutrient(app.t("Kaloriya", "Калории"), app.number(values.kcal), app.t("kkal", "ккал"))
                nutrient(app.t("Oqsil", "Белки"), app.decimal(values.protein), grams)
                nutrient(app.t("Yog‘", "Жиры"), app.decimal(values.fat), grams)
                nutrient(app.t("Uglevod", "Углеводы"), app.decimal(values.carbs), grams)
            }
        }
        .accessibilityIdentifier("nutrition")
    }

    private func nutrient(_ label: String, _ value: String, _ unit: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.ui(12))
                .foregroundStyle(Theme.text3)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(value)
                .font(.ui(20, .semibold).monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(unit)
                .font(.ui(13))
                .foregroundStyle(Theme.text2)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 4)
        .padding(.vertical, 12)
        .background(Theme.raised, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    /// Two lines, and "read more" only when two lines cut it short.
    private var about: some View {
        let text = app.about(product)
        return VStack(alignment: .leading, spacing: 4) {
            Text(text)
                .font(.ui(16))
                .foregroundStyle(Theme.text2)
                .lineLimit(expanded ? nil : 2)
                .fixedSize(horizontal: false, vertical: true)
                .overlay {
                    GeometryReader { shown in
                        // The whole text at the same width, measured but never drawn.
                        Text(text)
                            .font(.ui(16))
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(width: shown.size.width, alignment: .leading)
                            .hidden()
                            .background(GeometryReader { full in
                                Color.clear
                                    .onAppear { measure(full: full.size.height, shown: shown.size.height) }
                                    .onChange(of: shown.size.height) { _, height in
                                        measure(full: full.size.height, shown: height)
                                    }
                            })
                    }
                    .accessibilityHidden(true)
                }

            if truncated || expanded {
                Button {
                    Haptics.tap()
                    withAnimation(Theme.ease) { expanded.toggle() }
                } label: {
                    Text(expanded ? app.t("Qisqartirish", "Свернуть") : app.t("Batafsil", "Читать полностью"))
                        .font(.ui(15, .medium))
                        .foregroundStyle(Theme.text)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("readMore")
            }
        }
    }

    private func measure(full: CGFloat, shown: CGFloat) {
        guard !expanded else { return }
        truncated = full > shown + 1
    }

    private var howToScan: String {
        if product.weighted {
            return app.t("Tarozida torting va tarozi chiqargan yorliqni skanerlang. Narx og‘irlikka qarab hisoblanadi.",
                         "Взвесьте на весах и отсканируйте этикетку, которую они напечатают. Цена считается по весу.")
        }
        if product.marked {
            return app.t("Markirovka bilan sotiladi: har bir shishadagi kvadrat kodni skanerlang. U qopqoq yoki yorliqda bo‘ladi.",
                         "Продаётся по маркировке: сканируйте квадратный код на каждой бутылке. Он на крышке или этикетке.")
        }
        return app.t("Qadoqdagi shtrix-kodni skanerlang.", "Отсканируйте штрихкод на упаковке.")
    }

    // MARK: Bottom

    @ViewBuilder
    private var bottomBar: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let line {
                // What this line adds to the basket, labelled.
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        SectionLabel(app.t("Savatda", "В корзине"))
                        Text(app.detail(line))
                            .font(.ui(15).monospacedDigit())
                            .foregroundStyle(Theme.text2)
                    }
                    Spacer(minLength: 8)
                    Text(app.money(line.total))
                        .font(.ui(20, .medium).monospacedDigit())
                        .contentTransition(.numericText(value: Double(line.total)))
                        .accessibilityIdentifier("lineTotal")
                }
                .accessibilityElement(children: .combine)

                if line.isMarked {
                    Text(app.t("Yana bir shisha uchun uning kodini ham skanerlang",
                               "Ещё одна бутылка: отсканируйте и её код"))
                        .font(.ui(13))
                        .foregroundStyle(Theme.text3)
                        .fixedSize(horizontal: false, vertical: true)
                } else if line.grams != nil {
                    Text(app.t("Og‘irlik tarozi yorlig‘idan olingan, uni faqat o‘chirish mumkin",
                               "Вес взят с этикетки весов, товар можно только удалить"))
                        .font(.ui(13))
                        .foregroundStyle(Theme.text3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 12) {
                    PaperStepper(line: line, onPaper: false)
                        .fixedSize()
                    Button(app.t("Tayyor", "Готово"), action: close)
                        .buttonStyle(PrimaryButtonStyle())
                        .accessibilityIdentifier("productDone")
                }
                .animation(Theme.easeFast, value: line.qty)
            } else if mode == .browsing {
                Button {
                    Haptics.tap()
                    startScanning()
                } label: {
                    HStack(spacing: 8) {
                        IconView(.scan)
                        Text(app.itemCount > 0
                             ? app.t("Xaridni davom ettirish", "Продолжить покупку")
                             : app.t("Skanerlashni boshlash", "Начать сканировать"))
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityIdentifier("productScan")
            }
        }
        .padding(.horizontal, Theme.page)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(Theme.bg)
    }
}
