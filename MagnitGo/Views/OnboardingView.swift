import SwiftUI

/// Phone, then SMS code. One field per step, the action above the keyboard.
struct OnboardingView: View {
    @Environment(AppState.self) private var app

    private enum Step { case phone, code }
    private static let codeLength = 5

    @State private var step: Step
    @State private var digits: String
    @State private var code = ""
    @State private var verifying = false
    @State private var resendIn = 59
    @FocusState private var focus: Step?

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    /// The defaults are what the app uses; the arguments exist for previews.
    init(phone: String = "", atCodeStep: Bool = false) {
        _digits = State(initialValue: phone)
        _step = State(initialValue: atCodeStep ? .code : .phone)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                if step == .code {
                    IconButton(icon: .back) { backToPhone() }
                        .padding(.leading, -12)
                        .accessibilityLabel(app.t("Orqaga", "Назад"))
                        .accessibilityIdentifier("otpBack")
                } else {
                    LogoMark(size: 40)
                }
                Spacer()
                LanguageSwitch()
            }
            .frame(height: 44)
            .padding(.bottom, 24)

            Steps(labels: [app.t("Telefon", "Телефон"), app.t("SMS kod", "Код из SMS")],
                  current: step == .phone ? 0 : 1)
                .padding(.bottom, 24)

            if step == .phone { phoneStep } else { codeStep }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Theme.page)
        .padding(.top, 12)
        .safeAreaInset(edge: .bottom, spacing: 0) { bottomAction }
        .background(Theme.bg.ignoresSafeArea())
        .foregroundStyle(Theme.text)
        .onAppear { focus = step }
        .onReceive(ticker) { _ in
            if step == .code, resendIn > 0 { resendIn -= 1 }
        }
    }

    // MARK: Phone

    private var phoneStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(app.t("Telefon raqamingiz", "Ваш номер телефона"))
                .font(.ui(28, .medium))
            Text(app.t("SMS kod yuboramiz. Keshbek shu raqamda yig‘iladi.",
                       "Пришлём код в SMS. Кешбэк копится на этом номере."))
                .font(.ui(16))
                .foregroundStyle(Theme.text2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)

            ZStack(alignment: .leading) {
                // The real field draws nothing; the mask shows the expected format
                // before anything is typed and the digits after.
                TextField("", text: phoneInput)
                    .keyboardType(.numberPad)
                    .textContentType(.telephoneNumber)
                    .focused($focus, equals: .phone)
                    .foregroundStyle(.clear)
                    .tint(.clear)
                    .frame(maxWidth: .infinity, minHeight: 64)
                    .accessibilityIdentifier("phoneField")
                    .accessibilityLabel(app.t("Telefon raqami", "Номер телефона"))

                HStack(spacing: 0) {
                    Text("+998 ").foregroundStyle(Theme.text3)
                    Text(maskedPhone.typed).foregroundStyle(Theme.text)
                    if focus == .phone { Caret() }
                    Text(maskedPhone.rest).foregroundStyle(Theme.text3.opacity(0.5))
                }
                .font(.ui(26, .medium).monospacedDigit())
                .padding(.horizontal, 16)
                .allowsHitTesting(false)
            }
            .fieldBox(focused: focus == .phone)
            .padding(.top, 24)
        }
    }

    /// The digits typed so far and the part of the mask still to fill.
    private var maskedPhone: (typed: String, rest: String) {
        let typed = Array(digits)
        var filled = ""
        var rest = ""
        var used = 0
        for char in "00 000 00 00" {
            if char == " " {
                if used < typed.count { filled.append(" ") } else { rest.append(" ") }
            } else if used < typed.count {
                filled.append(typed[used])
                used += 1
            } else {
                rest.append(char)
            }
        }
        return (filled, rest)
    }

    // Input is cleaned in the binding's setter rather than in onChange: SMS autofill and
    // paste deliver every digit in one frame, and onChange drops all but the first change.

    private var phoneInput: Binding<String> {
        Binding(get: { digits }, set: { digits = Self.normalise($0) })
    }

    private var codeInput: Binding<String> {
        Binding(get: { code }, set: { new in
            code = String(new.filter(\.isNumber).prefix(Self.codeLength))
            // Nothing to press once the code is complete.
            if code.count == Self.codeLength { verify() }
        })
    }

    /// Accepts "+998 93 494 25 26", "998934942526" or "934942526".
    private static func normalise(_ raw: String) -> String {
        var clean = raw.filter(\.isNumber)
        if clean.count > 9, clean.hasPrefix("998") { clean.removeFirst(3) }
        return String(clean.prefix(9))
    }

    // MARK: Code

    private var codeStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(app.t("SMS kodni kiriting", "Введите код из SMS"))
                .font(.ui(28, .medium))
            Text(app.t("+998 \(AppState.maskPhone(digits)) raqamiga yuborildi",
                       "Отправили на +998 \(AppState.maskPhone(digits))"))
                .font(.ui(16))
                .foregroundStyle(Theme.text2)
                .padding(.top, 8)

            ZStack {
                TextField("", text: codeInput)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .focused($focus, equals: .code)
                    .foregroundStyle(.clear)
                    .tint(.clear)
                    .frame(maxWidth: .infinity, minHeight: 64)
                    .accessibilityIdentifier("codeField")
                    .accessibilityLabel(app.t("SMS kod", "Код из SMS"))

                HStack(spacing: 8) {
                    ForEach(0..<Self.codeLength, id: \.self) { index in
                        let chars = Array(code)
                        let isNext = index == chars.count && focus == .code
                        ZStack {
                            if index < chars.count {
                                Text(String(chars[index])).font(.ui(26, .medium).monospacedDigit())
                            } else if isNext {
                                Caret()
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 64)
                        .fieldBox(focused: isNext)
                    }
                }
                .allowsHitTesting(false)
            }
            .padding(.top, 24)

            HStack {
                if resendIn > 0 {
                    Text(app.t("Qayta yuborish", "Отправить снова") + String(format: " 0:%02d", resendIn))
                        .font(.ui(14).monospacedDigit())
                        .foregroundStyle(Theme.text3)
                } else {
                    Button(app.t("Kodni qayta yuborish", "Отправить код снова")) { resendIn = 59 }
                        .font(.ui(14, .medium))
                        .foregroundStyle(Theme.text)
                }
                Spacer()
                Text(app.t("Demo: istalgan 5 raqam", "Демо: любые 5 цифр"))
                    .font(.ui(14))
                    .foregroundStyle(Theme.text3)
            }
            .frame(minHeight: 44)
            .padding(.top, 8)
        }
    }

    // MARK: Bottom

    @ViewBuilder
    private var bottomAction: some View {
        Group {
            if step == .phone {
                Button(app.t("Kod olish", "Получить код")) { sendCode() }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(digits.count < 9)
                    .accessibilityIdentifier("sendCode")
            } else if verifying {
                HStack(spacing: 8) {
                    ProgressView().tint(Theme.text2)
                    Text(app.t("Tekshirilmoqda", "Проверяем"))
                        .font(.ui(14))
                        .foregroundStyle(Theme.text2)
                }
                .frame(maxWidth: .infinity, minHeight: 52)
            }
        }
        .padding(.horizontal, Theme.page)
        .padding(.bottom, 8)
    }

    // MARK: Actions

    private func sendCode() {
        guard digits.count == 9 else { return }
        Haptics.tap()
        code = ""
        resendIn = 59
        step = .code
        focus = .code
    }

    private func backToPhone() {
        // The typed number is kept.
        step = .phone
        focus = .phone
    }

    private func verify() {
        guard !verifying else { return }
        verifying = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(400))
            Haptics.success()
            app.signIn(phone: digits)
        }
    }
}

/// A text cursor for the fields that draw their own text.
private struct Caret: View {
    @State private var on = true

    var body: some View {
        Rectangle()
            .fill(Theme.text)
            .frame(width: 2, height: 30)
            .opacity(on ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) { on = false }
            }
            .accessibilityHidden(true)
    }
}

private extension View {
    /// The filled, outlined box that makes an input read as an input.
    func fieldBox(focused: Bool) -> some View {
        background(Theme.raised, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(focused ? Theme.text : .clear, lineWidth: 1)
            )
    }
}
