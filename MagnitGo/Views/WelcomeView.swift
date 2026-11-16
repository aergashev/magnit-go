import SwiftUI

/// Three pages before sign-in: what the app does, in the order it happens in the store.
/// Shown once. Each page is a photo, a headline and one line on a lower panel; one
/// button moves on, and the last page hands over to sign-in.
struct WelcomeView: View {
    @Environment(AppState.self) private var app
    @State private var page = 0

    private struct Page {
        let photo: String
        let titleUz, titleRu: String
        let bodyUz, bodyRu: String
    }

    private static let pages = [
        Page(photo: "welcome-1",
             titleUz: "Javonning o‘zida skanerlang", titleRu: "Сканируйте прямо у полки",
             bodyUz: "Mahsulotni savatga solayotganda shtrix-kodini telefon bilan o‘qiting. Nomi va narxi darhol chiqadi.",
             bodyRu: "Кладя товар в корзину, считайте его штрихкод телефоном. Название и цена появятся сразу."),
        Page(photo: "welcome-2",
             titleUz: "Chek telefoningizda", titleRu: "Чек в вашем телефоне",
             bodyUz: "Har bir mahsulot chekka yoziladi. Miqdorni o‘zgartirish yoki mahsulotni o‘chirish mumkin.",
             bodyRu: "Каждый товар сразу попадает в чек. Количество можно изменить, а товар удалить."),
        Page(photo: "welcome-3",
             titleUz: "Bitta QR va keshbek", titleRu: "Один QR и кешбэк",
             bodyUz: "Kassirga QR-kodni ko‘rsating yoki ilovada to‘lang. Har xariddan ball qaytadi: 1 ball = 1 so‘m.",
             bodyRu: "Покажите кассиру QR или оплатите в приложении. С каждой покупки возвращаются баллы: 1 балл = 1 сум."),
    ]

    private var isLast: Bool { page == Self.pages.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                LogoMark(size: 40)
                Spacer()
                LanguageSwitch()
            }
            .frame(height: 44)
            .padding(.horizontal, Theme.page)
            .padding(.top, 12)

            TabView(selection: $page) {
                ForEach(Array(Self.pages.enumerated()), id: \.offset) { index, item in
                    pageView(item)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .padding(.top, 16)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { bottom }
        .foregroundStyle(Theme.text)
        .background(Theme.bg.ignoresSafeArea())
        .accessibilityIdentifier("welcome")
    }

    private func pageView(_ item: Page) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // The photo takes whatever height the screen leaves.
            Color.clear
                .overlay {
                    Image("Welcome/" + item.photo)
                        .resizable()
                        .scaledToFill()
                }
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 8) {
                Text(app.t(item.titleUz, item.titleRu))
                    .font(.ui(30, .semibold))
                    .fixedSize(horizontal: false, vertical: true)
                Text(app.t(item.bodyUz, item.bodyRu))
                    .font(.ui(16))
                    .foregroundStyle(Theme.text2)
                    .lineLimit(3, reservesSpace: true)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.raised, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
            .padding(.top, 12)
            .accessibilityElement(children: .combine)
        }
        .padding(.horizontal, Theme.page)
    }

    private var bottom: some View {
        VStack(spacing: 16) {
            PageDots(count: Self.pages.count, current: page)

            Button {
                Haptics.tap()
                if isLast {
                    app.finishWelcome()
                } else {
                    withAnimation(Theme.ease) { page += 1 }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(isLast ? app.t("Boshlash", "Начать") : app.t("Keyingisi", "Далее"))
                    IconView(.chevronRight, size: 18)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .accessibilityIdentifier("welcomeNext")
        }
        .padding(.horizontal, Theme.page)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .background(Theme.bg)
    }
}

/// Where you are among a few pages: the current one is a longer pill.
struct PageDots: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? Theme.text : Theme.text3.opacity(0.5))
                    .frame(width: index == current ? 20 : 8, height: 8)
            }
        }
        .animation(Theme.ease, value: current)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(current + 1) / \(count)")
    }
}
