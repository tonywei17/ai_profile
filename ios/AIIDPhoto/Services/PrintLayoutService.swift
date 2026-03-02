import UIKit

final class PrintLayoutService {
    static let shared = PrintLayoutService()
    private init() {}

    /// Render an ID photo tiled onto a print-ready canvas at 300 DPI.
    func renderLayout(
        image: UIImage,
        spec: IDPhotoSpec,
        paperSize: PrintPaperSize,
        showGuides: Bool = true
    ) -> UIImage? {
        renderLayout(image: image, photoSizeMM: spec.photoSizeMM, paperSize: paperSize, showGuides: showGuides)
    }

    /// Render with raw mm dimensions (supports custom sizes).
    func renderLayout(
        image: UIImage,
        photoSizeMM: (width: Double, height: Double),
        paperSize: PrintPaperSize,
        showGuides: Bool = true
    ) -> UIImage? {
        let layout = PrintLayoutInfo.calculate(photoSizeMM: photoSizeMM, paperSize: paperSize)
        let canvasSize = CGSize(width: paperSize.widthPx, height: paperSize.heightPx)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1 // Absolute pixel dimensions (no @2x/@3x scaling)
        let renderer = UIGraphicsImageRenderer(size: canvasSize, format: format)

        return renderer.image { ctx in
            // White paper background
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: canvasSize))

            // Draw each photo cell
            for row in 0..<layout.rows {
                for col in 0..<layout.cols {
                    let origin = layout.photoOrigin(col: col, row: row)
                    let rect = CGRect(
                        x: origin.x, y: origin.y,
                        width: Double(layout.photoWidthPx),
                        height: Double(layout.photoHeightPx)
                    )
                    image.draw(in: rect)
                }
            }

            // Cutting guides: thin lines around each photo
            if showGuides {
                drawGuides(ctx: ctx.cgContext, layout: layout)
            }
        }
    }

    private func drawGuides(ctx: CGContext, layout: PrintLayoutInfo) {
        ctx.setStrokeColor(UIColor.lightGray.withAlphaComponent(0.5).cgColor)
        ctx.setLineWidth(1)

        for row in 0..<layout.rows {
            for col in 0..<layout.cols {
                let origin = layout.photoOrigin(col: col, row: row)
                let rect = CGRect(
                    x: origin.x, y: origin.y,
                    width: Double(layout.photoWidthPx),
                    height: Double(layout.photoHeightPx)
                )
                ctx.stroke(rect)
            }
        }
    }
}
