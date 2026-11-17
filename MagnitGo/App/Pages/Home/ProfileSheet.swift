import SwiftUI

/// Phone number, language and sign-out.
struct ProfileSheet: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(app.t("Profil", "Профиль"))
                .font(.ui(28, .medium))
                .padding(.top, 32)

            VStack(alignment: .leading, spacing: 2) {
                SectionLabel(app.t("Telefon raqami", "Номер телефона"))
                Text(app.formattedPhone()).font(.ui(17).monospacedDigit())
            }
            .padding(.top, 24)

            HStack {
                Text(app.t("Ilova tili", "Язык приложения")).font(.ui(16))
                Spacer()
                LanguageSwitch()
            }
            .frame(minHeight: 56)
            .padding(.top, 8)

            Spacer(minLength: 16)

            Button(app.t("Hisobdan chiqish", "Выйти из аккаунта")) {
                dismiss()
                app.signOut()
            }
            .buttonStyle(SecondaryButtonStyle())
            .accessibilityIdentifier("signOut")
        }
        .padding(.horizontal, Theme.page)
        .padding(.bottom, 8)
        .foregroundStyle(Theme.text)
        .preferredColorScheme(.dark)
    }
}
