import SwiftUI

/// The app language, switched in place. Session UI: it changes the session's language.
struct LanguageSwitch: View {
    @Environment(AppState.self) private var app

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Lang.allCases, id: \.self) { lang in
                Button {
                    Haptics.tap()
                    app.setLang(lang)
                } label: {
                    Text(lang.short)
                        .font(.ui(14, .medium))
                        .foregroundStyle(app.lang == lang ? Theme.text : Theme.text3)
                        .frame(width: 44, height: 32)
                        .background(app.lang == lang ? Theme.raised : .clear, in: Capsule())
                        .frame(height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(lang.label)
                .accessibilityIdentifier("lang-\(lang.rawValue)")
            }
        }
    }
}
