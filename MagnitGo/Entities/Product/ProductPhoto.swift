import SwiftUI
import UIKit

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
