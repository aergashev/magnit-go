import SwiftUI
import UIKit
import CoreImage.CIFilterBuiltins

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
