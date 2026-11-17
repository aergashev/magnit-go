import SwiftUI

/// Cashback rate by lifetime spend.
struct Tier: Equatable {
    let rate: Double
    let threshold: Int

    static let all = [
        Tier(rate: 0.01, threshold: 0),
        Tier(rate: 0.02, threshold: 1_000_000),
        Tier(rate: 0.03, threshold: 5_000_000),
    ]
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
