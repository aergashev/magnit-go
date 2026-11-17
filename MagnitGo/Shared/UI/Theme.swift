import SwiftUI

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
