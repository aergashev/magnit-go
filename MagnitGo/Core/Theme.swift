import SwiftUI
import UIKit
import CoreImage.CIFilterBuiltins
import AudioToolbox

// Direction: brisk, exact, plain-spoken. The world is the till.
// Concept: the basket is the receipt. It prints as you scan, and showing it is how you pay.

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

enum Theme {
    // One graphite ramp for every working surface.
    static let bg = Color(hex: 0x141415)
    static let raised = Color(hex: 0x232325)
    static let line = Color(hex: 0xEDEDED, opacity: 0.08)
    static let text = Color(hex: 0xEDEDED)
    static let text2 = Color(hex: 0xA1A1A6)
    static let text3 = Color(hex: 0x85858B)

    // The two colours of the Magnit mark, sampled from it. Cream is only ever paper.
    static let paper = Color(hex: 0xCEC7B3)
    static let ink = Color(hex: 0x05020D)
    static let inkDim = Color(hex: 0x05020D, opacity: 0.66)
    static let rule = Color(hex: 0x05020D, opacity: 0.22)

    /// The one accent: points the shopper has earned. Nothing else uses it.
    static let accent = Color(hex: 0xFF8A3D)

    static let page: CGFloat = 20
    static let ease = Animation.timingCurve(0.22, 1, 0.36, 1, duration: 0.3)
    static let easeFast = Animation.timingCurve(0.22, 1, 0.36, 1, duration: 0.16)
}

extension Font {
    /// Everything off the paper: rounded, so the app reads as friendly rather than a till.
    static func ui(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    /// Words printed on the cheque keep the plain face the receipt always had.
    static func paper(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }

    /// Receipt figures and codes: the till prints in mono.
    static func mono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

// MARK: - Buttons

/// The one filled action on a screen.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var enabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.ui(16, .semibold))
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(Theme.text.opacity(enabled ? 1 : 0.3), in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(Theme.easeFast, value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.ui(16, .medium))
            .foregroundStyle(Theme.text)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(Theme.raised, in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(Theme.easeFast, value: configuration.isPressed)
    }
}

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

/// Where you are in a short flow, in words: "1 Skanerlash  2 To‘lov  3 Tayyor".
struct Steps: View {
    let labels: [String]
    let current: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                if index > 0 {
                    Rectangle().fill(Theme.text3).frame(width: 12, height: 1)
                }
                Text("\(index + 1) \(label)")
                    .font(.ui(13, index == current ? .medium : .regular))
                    .foregroundStyle(index == current ? Theme.text : Theme.text3)
                    .lineLimit(1)
                    .fixedSize()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(current + 1) / \(labels.count): \(labels[current])")
    }
}

/// A small heading that names the block under it.
struct SectionLabel: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.ui(13))
            .foregroundStyle(Theme.text3)
    }
}

struct LogoMark: View {
    var size: CGFloat = 36

    var body: some View {
        Image("Logo")
            .resizable()
            .interpolation(.high)
            .frame(width: size, height: size)
            .accessibilityLabel("Magnit")
    }
}

/// Progress to the next cashback level. Never starts empty.
struct TierBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(Theme.raised)
                Rectangle().fill(Theme.accent)
                    .frame(width: max(4, geo.size.width * min(1, max(0, progress))))
            }
        }
        .frame(height: 4)
        .clipShape(RoundedRectangle(cornerRadius: 2))
    }
}

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

// MARK: - QR

enum QR {
    private static let context = CIContext()

    /// Ink modules on a transparent background, so the code is printed on the paper.
    static func image(_ payload: String) -> UIImage {
        let generator = CIFilter.qrCodeGenerator()
        generator.message = Data(payload.utf8)
        // A long basket trades error correction for larger modules: a screen has no
        // scratches to recover from, and bigger modules scan faster.
        generator.correctionLevel = payload.utf8.count > 300 ? "L" : "M"
        guard let raw = generator.outputImage else { return UIImage() }

        let colour = CIFilter.falseColor()
        colour.inputImage = raw.transformed(by: CGAffineTransform(scaleX: 14, y: 14))
        colour.color0 = CIColor(color: UIColor(Theme.ink))
        colour.color1 = CIColor(red: 1, green: 1, blue: 1, alpha: 0)
        guard let output = colour.outputImage,
              let cg = context.createCGImage(output, from: output.extent) else { return UIImage() }
        return UIImage(cgImage: cg)
    }
}

struct QRView: View {
    let payload: String

    var body: some View {
        Image(uiImage: QR.image(payload))
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .accessibilityLabel("QR")
    }
}

enum Sounds {
    /// The beep a till scanner makes, so a scan is heard as well as felt. A built-in
    /// system sound; it follows the phone's silent switch.
    static func scanned() { AudioServicesPlaySystemSound(1054) }
}

enum Haptics {
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
    static func tap() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
}

// MARK: - Product photos

/// A product's cut-out photo from Assets.xcassets/Products, or its initial on a plain
/// tile when it has none. Cut-outs have no background, so they sit on paper or graphite.
struct ProductPhoto: View {
    let product: Product
    var size: CGFloat = 44

    var body: some View {
        Group {
            if !product.photo.isEmpty, let image = UIImage(named: "Products/" + product.photo) {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
            } else {
                Text(String(product.nameUz.prefix(1)))
                    .font(.ui(size * 0.4, .medium))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.text3.opacity(0.2), in: RoundedRectangle(cornerRadius: size * 0.25, style: .continuous))
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
