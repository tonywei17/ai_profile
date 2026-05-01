import UIKit

final class PrintLayoutService {
    static let shared = PrintLayoutService()
    private init() {}

    /// Render an ID photo tiled onto a print-ready canvas at 300 DPI.
    /// Runs off the main thread to avoid UI blocking.
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
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: canvasSize, format: format)

        guard let cgImage = image.cgImage else { return nil }

        return renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: canvasSize))

            let gc = ctx.cgContext
            gc.saveGState()
            gc.translateBy(x: 0, y: canvasSize.height)
            gc.scaleBy(x: 1, y: -1)
            for row in 0..<layout.rows {
                for col in 0..<layout.cols {
                    let origin = layout.photoOrigin(col: col, row: row)
                    let rect = CGRect(
                        x: origin.x,
                        y: canvasSize.height - origin.y - Double(layout.photoHeightPx),
                        width: Double(layout.photoWidthPx),
                        height: Double(layout.photoHeightPx)
                    )
                    drawAspectFill(cgImage: cgImage, in: rect, context: gc)
                }
            }
            gc.restoreGState()

            if showGuides {
                drawGuides(ctx: ctx.cgContext, layout: layout)
            }
        }
    }

    /// Scale-to-fill while preserving aspect ratio, cropping any overflow to the target rect.
    private func drawAspectFill(cgImage: CGImage, in rect: CGRect, context: CGContext) {
        let imgW = CGFloat(cgImage.width)
        let imgH = CGFloat(cgImage.height)
        let scaleX = rect.width / imgW
        let scaleY = rect.height / imgH
        let scale = max(scaleX, scaleY)

        let scaledW = imgW * scale
        let scaledH = imgH * scale
        let drawRect = CGRect(
            x: rect.minX + (rect.width - scaledW) / 2,
            y: rect.minY + (rect.height - scaledH) / 2,
            width: scaledW,
            height: scaledH
        )

        context.saveGState()
        context.clip(to: rect)
        context.draw(cgImage, in: drawRect)
        context.restoreGState()
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
