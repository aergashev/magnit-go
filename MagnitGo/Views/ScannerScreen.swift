import SwiftUI

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
                Catalog.demoShelf.prefix(6).forEach { app.scan(Catalog.demoCode($0)) }
                app.scan(Catalog.demoShelf[0])
                app.scan(Catalog.demoCode(Catalog.demoShelf[2]))
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

struct ScannerScreen: View {
    @Environment(AppState.self) private var app
    let close: () -> Void
    let checkout: () -> Void

    @State private var torch = false
    @State private var captured = false
    private enum Notice: Equatable {
        case added(String)
        case problem(String)

        var text: String {
            switch self {
            case .added(let text), .problem(let text): return text
            }
        }

        /// Told apart by icon, not by colour.
        var icon: Icon {
            switch self {
            case .added: return .check
            case .problem: return .alert
            }
        }
    }

    @State private var notice: Notice?
    @State private var noticeToken = UUID()
    @State private var cameraUnavailable = false
    @State private var basketOpen = false
    @State private var checkoutAfterDismiss = false

    private var usesDemoCodes: Bool {
        #if targetEnvironment(simulator) || targetEnvironment(macCatalyst)
        return true
        #else
        return cameraUnavailable
        #endif
    }

    var body: some View {
        ZStack {
            cameraLayer.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    IconButton(icon: .close, overCamera: true, action: close)
                        .accessibilityLabel(app.t("Yopish", "Закрыть"))
                        .accessibilityIdentifier("closeScanner")
                    Spacer()
                    Steps(labels: app.flowSteps, current: 0)
                        .padding(.horizontal, 12)
                        .frame(height: 44)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    Spacer()
                    if usesDemoCodes {
                        // Keeps the steps centred where there is no torch.
                        Color.clear.frame(width: 44, height: 44)
                    } else {
                        IconButton(icon: torch ? .flash : .flashOff, overCamera: true) {
                            Haptics.tap()
                            torch.toggle()
                        }
                        .accessibilityLabel(app.t("Chiroq", "Фонарик"))
                        .accessibilityIdentifier("torch")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Spacer(minLength: 16)
                viewfinder
                Spacer(minLength: 16)
            }
        }
        .foregroundStyle(Theme.text)
        .safeAreaInset(edge: .bottom, spacing: 0) { bottom }
        .background(Color.black.ignoresSafeArea())
        .sheet(isPresented: $basketOpen, onDismiss: {
            if checkoutAfterDismiss {
                checkoutAfterDismiss = false
                checkout()
            }
        }) {
            BasketSheet(checkout: {
                checkoutAfterDismiss = true
                basketOpen = false
            })
            .environment(app)
            .preferredColorScheme(.dark)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationBackground(Theme.bg)
        }
    }

    // MARK: Layers

    @ViewBuilder
    private var cameraLayer: some View {
        #if targetEnvironment(simulator) || targetEnvironment(macCatalyst)
        Color(hex: 0x0B0B0C)
        #else
        if cameraUnavailable {
            Color(hex: 0x0B0B0C)
        } else {
            CameraScanner(torch: torch, onCode: handle, onUnavailable: { cameraUnavailable = true })
        }
        #endif
    }

    private var viewfinder: some View {
        VStack(spacing: 20) {
            ViewfinderCorners()
                .stroke(Theme.text, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .frame(width: 272, height: 168)
                // Closes in for a moment when a code is read.
                .scaleEffect(captured ? 0.94 : 1)
                .animation(Theme.easeFast, value: captured)

            Group {
                if let notice {
                    HStack(spacing: 8) {
                        IconView(notice.icon, size: 18)
                        Text(notice.text)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Theme.raised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .accessibilityIdentifier("scanNotice")
                } else if cameraUnavailable {
                    Button(app.t("Kameraga ruxsat berish", "Разрешить доступ к камере")) {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .frame(minHeight: 44)
                } else {
                    Text(app.t("Shtrix-kod, tarozi yorlig‘i yoki markirovka kodini skanerlang",
                               "Сканируйте штрихкод, этикетку с весов или код маркировки"))
                }
            }
            .font(.ui(15))
            .multilineTextAlignment(.center)
            .frame(minHeight: 48)
            .padding(.horizontal, 32)
        }
    }

    private var bottom: some View {
        VStack(spacing: 0) {
            if usesDemoCodes { demoCodes.padding(.bottom, 12) }

            if app.removed != nil, !basketOpen {
                UndoBar()
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }

            // The receipt feeds out of the till below it.
            ScanSlip(open: { basketOpen = true })
                .padding(.horizontal, 16)

            VStack(spacing: 0) {
                if !app.basket.isEmpty {
                    Button(action: checkout) {
                        HStack {
                            Text(app.t("To‘lovga o‘tish", "К оплате"))
                            Spacer()
                            Text(app.money(app.subtotal))
                                .monospacedDigit()
                                .contentTransition(.numericText(value: Double(app.subtotal)))
                        }
                        .padding(.horizontal, 20)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .accessibilityIdentifier("toCheckout")
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity)
            .background(Theme.bg.ignoresSafeArea(edges: .bottom))
        }
        .animation(Theme.ease, value: app.removed)
        .animation(Theme.ease, value: app.subtotal)
    }

    /// Stands in for the camera where there is none: tap a name to "scan" its code.
    private var demoCodes: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(app.t("Demo: kamera o‘rniga mahsulot nomini bosing, u skanerlangandek qo‘shiladi",
                       "Демо: вместо камеры нажмите на товар, он добавится как отсканированный"))
                .font(.ui(12))
                .foregroundStyle(Theme.text3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 16)

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(Catalog.demoShelf, id: \.self) { entry in
                        if let item = Catalog.resolve(entry) {
                            demoButton(demoTitle(item), id: entry) { handle(Catalog.demoCode(entry)) }
                        }
                    }
                    demoButton(app.t("Noma’lum kod", "Неизвестный код"), id: "unknown") { handle("0000") }
                }
                .padding(.horizontal, 16)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func demoTitle(_ item: ScannedItem) -> String {
        if let grams = item.grams { return app.name(item.product) + " " + app.weight(grams) }
        if item.product.marked { return app.name(item.product) + app.t(", markirovka", ", маркировка") }
        return app.name(item.product)
    }

    private func demoButton(_ title: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.ui(14))
                .foregroundStyle(Theme.text)
                .padding(.horizontal, 12)
                .frame(height: 36)
                .background(Theme.raised, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .frame(height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("demo-\(id)")
    }

    // MARK: Scanning

    private func handle(_ code: String) {
        guard !basketOpen else { return }
        switch app.scan(code) {
        case .added(let line):
            // Heard, felt and read: a beep, a haptic, the frame closes in, the name
            // appears where the shopper is looking, and the line prints below.
            Sounds.scanned()
            Haptics.success()
            captured = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { captured = false }
            let name = app.name(line.product)
            post(.added(line.qty > 1
                        ? app.t("\(name) qo‘shildi, endi \(line.qty) ta", "\(name): добавлено, теперь \(line.qty) шт")
                        : app.t("\(name) qo‘shildi", "\(name): добавлено")),
                 for: 1.8)
        case .unknown:
            show(app.t("Bu kod topilmadi. Qayta skanerlang yoki xodimdan so‘rang",
                       "Код не найден. Отсканируйте ещё раз или спросите сотрудника"))
        case .needsMark:
            // Says what to scan instead, and where it usually is.
            show(app.t("Bu ichimlik markirovka bilan sotiladi. Qopqoq yoki yorliqdagi kvadrat kodni skanerlang",
                       "Этот напиток продаётся по маркировке. Отсканируйте квадратный код на крышке или этикетке"))
        case .duplicateMark:
            show(app.t("Bu shisha allaqachon chekda", "Эта бутылка уже в чеке"))
        }
    }

    private func show(_ message: String) {
        Haptics.warning()
        post(.problem(message), for: 4)
    }

    private func post(_ value: Notice, for seconds: Double) {
        let token = UUID()
        noticeToken = token
        notice = value
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            if noticeToken == token { notice = nil }
        }
    }
}

// MARK: - Pieces

struct ViewfinderCorners: Shape {
    func path(in rect: CGRect) -> Path {
        let arm: CGFloat = 28
        let radius: CGFloat = 12
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.minY + arm))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addQuadCurve(to: CGPoint(x: rect.minX + radius, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + arm, y: rect.minY))

        path.move(to: CGPoint(x: rect.maxX - arm, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + radius), control: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + arm))

        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - arm))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - radius, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - arm, y: rect.maxY))

        path.move(to: CGPoint(x: rect.minX + arm, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - radius), control: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - arm))

        return path
    }
}

/// The end of the receipt that is still in the till: the line just printed, and a way
/// to pull the whole thing out.
struct ScanSlip: View {
    @Environment(AppState.self) private var app
    let open: () -> Void

    private var current: BasketLine? {
        app.basket.first { $0.id == app.lastAddedID } ?? app.basket.first
    }

    var body: some View {
        Paper(tornTop: true) {
            if let line = current {
                EditableLine(line: line)
                    .id(line.id)
                    // The old line leaves at once, so a tap aimed at the new line's
                    // controls can never land on the previous product.
                    .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .identity))

                ReceiptRule().padding(.top, 4)

                // Names the action and the thing: "see the basket", with what is in it.
                Button(action: open) {
                    HStack(spacing: 8) {
                        IconView(.cart, size: 18)
                        Text(app.t("Savatni ko‘rish", "Открыть корзину"))
                            .font(.ui(15, .medium))
                        Text(app.itemsText(app.itemCount))
                            .font(.ui(15))
                            .foregroundStyle(Theme.inkDim)
                        Spacer()
                        IconView(.chevronUp, size: 18)
                    }
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.bottom, -8)
                .accessibilityIdentifier("openBasket")
            } else {
                Text(app.t("Savat bo‘sh", "Корзина пуста"))
                    .font(.ui(16, .medium))
                Text(app.t("Birinchi mahsulotni skanerlang: nomi va narxi shu yerda chiqadi",
                           "Отсканируйте первый товар: название и цена появятся здесь"))
                    .font(.ui(14))
                    .foregroundStyle(Theme.inkDim)
                    .padding(.top, 4)
                    .accessibilityIdentifier("emptyBasket")
            }
        }
        .clipped()
        .animation(Theme.ease, value: app.lastAddedID)
        .animation(Theme.ease, value: app.basket.isEmpty)
    }
}

/// The whole receipt so far, every line still editable.
struct BasketSheet: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    let checkout: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                Text(app.t("Savat", "Корзина"))
                    .font(.ui(28, .medium))
                    .foregroundStyle(Theme.text)
                Text(app.t("Miqdorni o‘zgartiring yoki mahsulotni o‘chiring",
                           "Измените количество или удалите товар"))
                    .font(.ui(15))
                    .foregroundStyle(Theme.text2)
                    .padding(.bottom, 12)

                Paper(tornTop: true) {
                    ReceiptHeader(detail: app.itemsText(app.itemCount))
                    ReceiptRule().padding(.vertical, 12)

                    if app.basket.isEmpty {
                        Text(app.t("Savat bo‘sh", "Корзина пуста")).font(.ui(16))
                    } else {
                        // Newest first: the item just scanned is the one most likely
                        // to need fixing.
                        VStack(spacing: 8) {
                            ForEach(app.basket) { EditableLine(line: $0) }
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
