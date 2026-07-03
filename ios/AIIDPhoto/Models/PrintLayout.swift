import Foundation

// MARK: - Print Paper Size

enum PrintPaperSize: String, CaseIterable, Identifiable {
    case fiveInch   // 5寸 89×127mm
    case sixInch    // 6寸 102×152mm — 中国照相馆最主流
    case sevenInch  // 7寸 127×178mm

    var id: String { rawValue }

    var widthMM: Double {
        switch self {
        case .fiveInch:  89
        case .sixInch:   102
        case .sevenInch: 127
        }
    }

    var heightMM: Double {
        switch self {
        case .fiveInch:  127
        case .sixInch:   152
        case .sevenInch: 178
        }
    }

    /// Pixel dimensions at 300 DPI (print standard).
    var widthPx: Int  { Int(round(widthMM / 25.4 * 300)) }
    var heightPx: Int { Int(round(heightMM / 25.4 * 300)) }

    var sizeLabel: String {
        switch self {
        case .fiveInch:  "89×127 mm"
        case .sixInch:   "102×152 mm"
        case .sevenInch: "127×178 mm"
        }
    }

    func displayName(language: String) -> String {
        switch self {
        case .fiveInch:  return language == "zh" ? "5 寸 (89×127)" : "5R (89×127)"
        case .sixInch:   return language == "zh" ? "6 寸 (102×152)" : "6R (102×152)"
        case .sevenInch: return language == "zh" ? "7 寸 (127×178)" : "7R (127×178)"
        }
    }

    func priceHint(language: String) -> String {
        switch self {
        case .fiveInch:  return language == "zh" ? "约 1~2 元" : "~¥1-2"
        case .sixInch:   return language == "zh" ? "约 2~3 元" : "~¥2-3"
        case .sevenInch: return language == "zh" ? "约 3~6 元" : "~¥3-6"
        }
    }
}

// MARK: - Layout Calculation

struct PrintLayoutInfo {
    let paperSize: PrintPaperSize
    let cols: Int
    let rows: Int
    let photoWidthPx: Int   // slot width（rotated=true 时为照片原始高度）
    let photoHeightPx: Int  // slot height（rotated=true 时为照片原始宽度）
    let rotated: Bool       // 是否将照片旋转 90° 以获得更多数量

    var totalCount: Int { cols * rows }

    /// Even spacing between photos and edges.
    var hMargin: Double {
        Double(paperSize.widthPx - cols * photoWidthPx) / Double(cols + 1)
    }

    var vMargin: Double {
        Double(paperSize.heightPx - rows * photoHeightPx) / Double(rows + 1)
    }

    /// Top-left origin for a given grid cell.
    func photoOrigin(col: Int, row: Int) -> CGPoint {
        CGPoint(
            x: hMargin + Double(col) * (Double(photoWidthPx) + hMargin),
            y: vMargin + Double(row) * (Double(photoHeightPx) + vMargin)
        )
    }

    /// Calculate optimal grid layout for a given spec on a paper size.
    /// Automatically tries both normal and rotated 90° orientations and picks
    /// whichever fits more photos. Uses ~3mm (35px @ 300dpi) minimum gap.
    static func calculate(spec: IDPhotoSpec, paperSize: PrintPaperSize) -> PrintLayoutInfo {
        calculate(photoSizeMM: spec.photoSizeMM, paperSize: paperSize)
    }

    /// Calculate layout from raw mm dimensions (supports custom sizes).
    static func calculate(photoSizeMM: (width: Double, height: Double), paperSize: PrintPaperSize) -> PrintLayoutInfo {
        let dpi = 300.0
        let photoW = Int(round(photoSizeMM.width / 25.4 * dpi))
        let photoH = Int(round(photoSizeMM.height / 25.4 * dpi))
        let minGap = 35 // ~3mm at 300dpi

        // Normal orientation
        let colsN = max(1, (paperSize.widthPx + minGap) / (photoW + minGap))
        let rowsN = max(1, (paperSize.heightPx + minGap) / (photoH + minGap))
        let countN = colsN * rowsN

        // Rotated 90° orientation
        let colsR = max(1, (paperSize.widthPx + minGap) / (photoH + minGap))
        let rowsR = max(1, (paperSize.heightPx + minGap) / (photoW + minGap))
        let countR = colsR * rowsR

        if countR > countN {
            return PrintLayoutInfo(
                paperSize: paperSize,
                cols: colsR,
                rows: rowsR,
                photoWidthPx: photoH,
                photoHeightPx: photoW,
                rotated: true
            )
        }

        return PrintLayoutInfo(
            paperSize: paperSize,
            cols: colsN,
            rows: rowsN,
            photoWidthPx: photoW,
            photoHeightPx: photoH,
            rotated: false
        )
    }
}
