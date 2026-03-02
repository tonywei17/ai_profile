import Foundation

// MARK: - Print Paper Size

enum PrintPaperSize: String, CaseIterable, Identifiable {
    case lSize   // L判 89×127mm — most common convenience store photo paper
    case twoL    // 2L判 127×178mm — larger option, more photos per sheet

    var id: String { rawValue }

    var widthMM: Double {
        switch self {
        case .lSize: 89
        case .twoL:  127
        }
    }

    var heightMM: Double {
        switch self {
        case .lSize: 127
        case .twoL:  178
        }
    }

    /// Pixel dimensions at 300 DPI (print standard).
    var widthPx: Int  { Int(round(widthMM / 25.4 * 300)) }
    var heightPx: Int { Int(round(heightMM / 25.4 * 300)) }

    var sizeLabel: String {
        switch self {
        case .lSize: "89×127 mm"
        case .twoL:  "127×178 mm"
        }
    }

    func displayName(language: String) -> String {
        switch self {
        case .lSize:
            switch language {
            case "zh": return "L判"
            case "ja": return "L判"
            case "ko": return "L 사이즈"
            default:   return "L Size"
            }
        case .twoL:
            switch language {
            case "zh": return "2L判"
            case "ja": return "2L判"
            case "ko": return "2L 사이즈"
            default:   return "2L Size"
            }
        }
    }

    func priceHint(language: String) -> String {
        switch self {
        case .lSize:
            switch language {
            case "zh": return "约30~40日元"
            case "ja": return "約30〜40円"
            case "ko": return "약 30~40엔"
            default:   return "~¥30-40"
            }
        case .twoL:
            switch language {
            case "zh": return "约80日元"
            case "ja": return "約80円"
            case "ko": return "약 80엔"
            default:   return "~¥80"
            }
        }
    }
}

// MARK: - Layout Calculation

struct PrintLayoutInfo {
    let paperSize: PrintPaperSize
    let cols: Int
    let rows: Int
    let photoWidthPx: Int
    let photoHeightPx: Int

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
    /// Uses ~3mm (35px @ 300dpi) minimum gap for comfortable cutting.
    static func calculate(spec: IDPhotoSpec, paperSize: PrintPaperSize) -> PrintLayoutInfo {
        calculate(photoSizeMM: spec.photoSizeMM, paperSize: paperSize)
    }

    /// Calculate layout from raw mm dimensions (supports custom sizes).
    static func calculate(photoSizeMM: (width: Double, height: Double), paperSize: PrintPaperSize) -> PrintLayoutInfo {
        let dpi = 300.0
        let photoW = Int(round(photoSizeMM.width / 25.4 * dpi))
        let photoH = Int(round(photoSizeMM.height / 25.4 * dpi))
        let minGap = 35 // ~3mm at 300dpi

        let cols = max(1, (paperSize.widthPx + minGap) / (photoW + minGap))
        let rows = max(1, (paperSize.heightPx + minGap) / (photoH + minGap))

        return PrintLayoutInfo(
            paperSize: paperSize,
            cols: cols,
            rows: rows,
            photoWidthPx: photoW,
            photoHeightPx: photoH
        )
    }
}
