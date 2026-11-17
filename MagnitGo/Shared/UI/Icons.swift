import SwiftUI

/// Untitled UI PRO icons, solid set. The SVGs live in Assets.xcassets/Icons and are
/// exported from the licensed `@untitledui-pro/icons` package.
enum Icon: String {
    case close
    case back
    case chevronRight = "chevron-right"
    case chevronDown = "chevron-down"
    case chevronUp = "chevron-up"
    case user
    case scan
    case cart
    case minus
    case plus
    case trash
    case check
    case checkCircle = "check-circle"
    case alert
    case flash
    case flashOff = "flash-off"
}

/// One icon at one size, tinted by the surrounding foreground style.
struct IconView: View {
    let icon: Icon
    var size: CGFloat = 20

    init(_ icon: Icon, size: CGFloat = 20) {
        self.icon = icon
        self.size = size
    }

    var body: some View {
        Image("Icons/" + icon.rawValue)
            .renderingMode(.template)
            .resizable()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// A bare 44pt icon. `overCamera` gives it a backing so it stays legible on video;
/// `filled` gives it a round backing in the page colour, for buttons over raised panels.
struct IconButton: View {
    let icon: Icon
    var overCamera = false
    var filled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            IconView(icon)
                .foregroundStyle(Theme.text)
                .frame(width: 44, height: 44)
                .background {
                    if overCamera {
                        Circle().fill(.ultraThinMaterial)
                    } else if filled {
                        Circle().fill(Theme.bg)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
