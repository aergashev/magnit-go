import SwiftUI

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
