import SwiftUI
import UIKit

// MARK: - Pay: show the QR at the till, or pay in the app

struct PayScreen: View {
    @Environment(AppState.self) private var app
    @Binding var path: [Route]
    @State private var savedBrightness: CGFloat?

    /// The code changes every 30 seconds so a screenshot cannot be reused.
    private static let rotation: TimeInterval = 30

    /// The method used last time comes first.
    private var methods: [PayMethod] {
        [app.lastInAppMethod] + PayMethod.inApp.filter { $0 != app.lastInAppMethod }
    }

    var body: some View {
        @Bindable var app = app

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 4) {
                    IconButton(icon: .back) { path.removeLast() }
                        .padding(.leading, -12)
                        .accessibilityLabel(app.t("Savatga qaytish", "Назад к корзине"))
                        .accessibilityIdentifier("payBack")
                    Steps(labels: app.flowSteps, current: 1)
                    Spacer()
                }

                Text(app.t("Kassirga ko‘rsating", "Покажите кассиру"))
                    .font(.ui(28, .medium))
                    .padding(.top, 8)
                // Says what happens next, and who does what.
                Text(app.t("Kassir shu QR-kodni skanerlaydi va barcha mahsulotlar kassaga o‘tadi. Pulni kassada to‘laysiz.",
                           "Кассир отсканирует этот QR, и все товары попадут на кассу. Оплатите на кассе."))
                    .font(.ui(15))
                    .foregroundStyle(Theme.text2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)

                // Decided before the QR is shown, because it changes what the till charges.
                if app.points > 0 {
                    Toggle(isOn: $app.usePoints) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(app.t("Keshbek ballari bilan to‘lash", "Оплатить баллами кешбэка"))
                                .font(.ui(16))
                            Text(app.t("\(app.pointsText(app.points)) bor: \(app.money(min(app.points, app.subtotal))) chegirma",
                                       "Есть \(app.pointsText(app.points)): скидка \(app.money(min(app.points, app.subtotal)))"))
                                .font(.ui(13))
                                .foregroundStyle(Theme.text2)
                        }
                    }
                    .tint(Theme.accent)
                    .frame(minHeight: 56)
                    .padding(.top, 12)
                    .accessibilityIdentifier("usePoints")
                }

                TimelineView(.periodic(from: .now, by: Self.rotation)) { context in
                    let window = Int(context.date.timeIntervalSince1970 / Self.rotation)

                    // No store header here: it would push the points switch off the screen.
                    Paper(tornTop: true) {
                        VStack(spacing: 8) {
                            ReceiptRow(label: app.itemsText(app.itemCount), value: app.number(app.subtotal))
                            if app.pointsApplied > 0 {
                                ReceiptRow(label: app.t("Keshbek ballari bilan", "Баллами кешбэка"),
                                           value: "−" + app.number(app.pointsApplied))
                            }
                            ReceiptRow(label: app.t("To‘lanadi", "К оплате"), value: app.money(app.total), total: true)
                                .accessibilityIdentifier("payTotal")
                            ReceiptRow(label: app.t("Keshbek qo‘shiladi", "Начислим кешбэк"),
                                       value: "+" + app.pointsText(app.cashbackEarned))
                        }

                        ReceiptRule().padding(.vertical, 12)

                        VStack(spacing: 8) {
                            // The QR carries the whole basket: see BasketQR.
                            QRView(payload: BasketQR.payload(basket: app.basket, code: app.basketCode,
                                                             window: window, pointsApplied: app.pointsApplied))
                                .frame(width: 248, height: 248)
                                .accessibilityIdentifier("basketQR")
                            // Nothing to press: the screen is waiting on the cashier.
                            HStack(spacing: 8) {
                                ProgressView().tint(Theme.ink)
                                Text(app.t("Kassir skanerlashi kutilmoqda", "Ждём, пока кассир отсканирует"))
                                    .font(.paper(14))
                            }
                            .accessibilityIdentifier("waitingForCashier")
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, 12)
            }
            .padding(.horizontal, Theme.page)
            .padding(.bottom, 16)
        }
        .scrollIndicators(.hidden)
        .foregroundStyle(Theme.text)
        .background(Theme.bg.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) { actions }
        .animation(Theme.ease, value: app.usePoints)
        .onAppear {
            // Full brightness so the till scanner reads it first time; restored on leave.
            #if !targetEnvironment(macCatalyst)
            savedBrightness = UIScreen.main.brightness
            UIScreen.main.brightness = 1
            #endif
        }
        .onDisappear {
            #if !targetEnvironment(macCatalyst)
            if let savedBrightness { UIScreen.main.brightness = savedBrightness }
            #endif
        }
    }

    /// The other way to pay, with every method visible rather than behind a menu.
    private var actions: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(app.t("Yoki navbatsiz, ilovada to‘lang", "Или оплатите в приложении, без очереди"))

            HStack(spacing: 8) {
                ForEach(methods, id: \.self) { method in
                    Button(method.title) {
                        Haptics.tap()
                        path.append(.paying(method))
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .accessibilityIdentifier("pay-\(method.rawValue)")
                }
            }

            // Stands in for the till confirming the basket.
            Button(app.t("Demo: kassir QR-kodni skanerladi", "Демо: кассир отсканировал QR")) { finish() }
                .font(.ui(14))
                .foregroundStyle(Theme.text3)
                .frame(maxWidth: .infinity, minHeight: 44)
                .accessibilityIdentifier("demoCashierScanned")
        }
        .padding(.horizontal, Theme.page)
        .padding(.top, 12)
        .padding(.bottom, 4)
        .background(Theme.bg)
    }

    private func finish() {
        Haptics.success()
        let receipt = app.completePurchase(method: .cashier)
        path = [.success(receipt)]
    }
}

// MARK: - In-app payment hand-off

struct PayingScreen: View {
    @Environment(AppState.self) private var app
    let method: PayMethod
    @Binding var path: [Route]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Steps(labels: app.flowSteps, current: 1)
                .padding(.top, 12)

            Text(app.t("\(method.title) orqali to‘lanmoqda", "Оплачиваем через \(method.title)"))
                .font(.ui(28, .medium))
                .padding(.top, 32)
            Text(app.money(app.total))
                .font(.ui(20).monospacedDigit())
                .foregroundStyle(Theme.text2)
                .padding(.top, 8)
            HStack(spacing: 8) {
                ProgressView().tint(Theme.text2)
                Text(app.t("Bir necha soniya kuting", "Подождите несколько секунд"))
                    .font(.ui(15))
                    .foregroundStyle(Theme.text2)
            }
            .padding(.top, 24)
            Spacer()
            Button(app.t("Bekor qilish", "Отменить")) { path.removeLast() }
                .buttonStyle(SecondaryButtonStyle())
                .accessibilityIdentifier("cancelPay")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.page)
        .padding(.bottom, 8)
        .foregroundStyle(Theme.text)
        .background(Theme.bg.ignoresSafeArea())
        .task {
            // Stands in for the round trip to the payment app. Leaving cancels it.
            do { try await Task.sleep(for: .milliseconds(1800)) } catch { return }
            Haptics.success()
            let receipt = app.completePurchase(method: method)
            path = [.success(receipt)]
        }
    }
}

// MARK: - Done

/// What happened, what was earned, what to do next, then the receipt.
struct SuccessScreen: View {
    @Environment(AppState.self) private var app
    let receipt: Receipt
    let close: () -> Void

    @State private var shownPoints = 0
    @State private var progress: Double = 0

    private var paidInApp: Bool { receipt.method != .cashier }

    private var cashback: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel(app.t("Keshbek qo‘shildi", "Начислен кешбэк"))
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("+" + app.number(shownPoints))
                    .font(.ui(56, .medium).monospacedDigit())
                    .tracking(-1)
                    .contentTransition(.numericText(value: Double(shownPoints)))
                    .accessibilityIdentifier("earnedPoints")
                Text(app.pointsUnit(receipt.earned))
                    .font(.ui(20))
            }
            .foregroundStyle(Theme.accent)

            Text(app.t("Balansingiz: \(app.pointsText(app.points))", "Ваш баланс: \(app.pointsText(app.points))"))
                .font(.ui(16))
                .padding(.top, 4)

            if let next = app.nextTier {
                TierBar(progress: progress)
                    .padding(.top, 16)
                Text(app.t("Yana \(app.money(app.remainingToNextTier)) xarid qilsangiz, keshbek \(Int(next.rate * 100))% bo‘ladi",
                           "Ещё \(app.money(app.remainingToNextTier)) покупок, и кешбэк станет \(Int(next.rate * 100))%"))
                    .font(.ui(14))
                    .foregroundStyle(Theme.text2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Steps(labels: app.flowSteps, current: 2)
                    .padding(.top, 12)

                HStack(spacing: 12) {
                    IconView(.checkCircle, size: 28)
                    Text(paidInApp ? app.t("To‘landi", "Оплачено") : app.t("Xarid yakunlandi", "Покупка завершена"))
                        .font(.ui(28, .medium))
                        .accessibilityIdentifier("successTitle")
                }
                .padding(.top, 24)

                Text(paidInApp
                     ? app.t("\(app.money(receipt.total)) \(receipt.method.title) orqali to‘landi. Chiqishda pastdagi QR-kodni ko‘rsating.",
                             "\(app.money(receipt.total)) оплачено через \(receipt.method.title). На выходе покажите QR ниже.")
                     : app.t("\(app.money(receipt.total)) kassada to‘landi. Chek xaridlar tarixida saqlandi.",
                             "\(app.money(receipt.total)) оплачено на кассе. Чек сохранён в истории покупок."))
                    .font(.ui(15))
                    .foregroundStyle(Theme.text2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)

                // Paid in the app, the next thing to do is show the exit QR, so the
                // receipt carrying it comes first. Paid at the till, the cashback does.
                if paidInApp {
                    PaidReceipt(receipt: receipt, summarised: true, exitQR: true)
                        .padding(.top, 24)
                    cashback.padding(.top, 28)
                } else {
                    cashback.padding(.top, 28)
                    PaidReceipt(receipt: receipt, summarised: true)
                        .padding(.top, 28)
                }
            }
            .padding(.horizontal, Theme.page)
            .padding(.bottom, 16)
        }
        .scrollIndicators(.hidden)
        .foregroundStyle(Theme.text)
        .background(Theme.bg.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button(app.t("Bosh sahifaga qaytish", "Вернуться на главную"), action: close)
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, Theme.page)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .background(Theme.bg)
                .accessibilityIdentifier("done")
        }
        .onAppear {
            // The bar starts where it was before this purchase, then moves.
            let span = Double((app.nextTier?.threshold ?? app.lifetimeSpend) - app.tier.threshold)
            let before = Double(app.lifetimeSpend - receipt.total - app.tier.threshold)
            progress = span > 0 ? max(0.02, before / span) : 1

            withAnimation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.5).delay(0.15)) {
                shownPoints = receipt.earned
                progress = app.tierProgress
            }
        }
    }
}
