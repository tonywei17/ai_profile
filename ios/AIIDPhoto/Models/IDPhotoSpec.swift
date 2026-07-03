import Foundation

// MARK: - ID Photo Spec (China-only)

enum IDPhotoSpec: String, CaseIterable, Identifiable {
    // Free
    case chinaID            // 居民身份证 26×32
    case oneInch            // 一寸 25×35
    case twoInch            // 二寸 35×49
    case chinaPassport      // 中国护照 33×48
    case driverLicense      // 驾驶证 22×32 (小一寸)
    case studentID          // 学生证 25×35
    case socialSecurity     // 社保卡 26×32
    case resume             // 简历照 25×35
    case standardPortrait   // 证件照（胸部以上）35×45
    case halfBody           // 半身照 89×127 (3R)
    case fullBody           // 全身照 102×152 (4R)

    // Pro
    case chinaMarriage      // 结婚登记照 53×35 横版 (双人合影)
    case oneInchLarge       // 大一寸 33×48
    case twoInchSmall       // 小二寸 35×45
    case ncreExam           // NCRE 32×40

    var id: String { rawValue }

    /// Pro-only specs require subscription to use.
    var isPro: Bool {
        switch self {
        case .chinaMarriage, .oneInchLarge, .twoInchSmall, .ncreExam: true
        default: false
        }
    }

    /// Whether this spec is a couple/two-person photo.
    var isCouplePhoto: Bool {
        self == .chinaMarriage
    }

    // MARK: - Localized Display Name

    func displayName(language: String) -> String {
        switch self {
        case .chinaID:           language == "zh" ? "居民身份证"       : "China ID Card"
        case .oneInch:           language == "zh" ? "一寸照"           : "1-Inch Photo"
        case .twoInch:           language == "zh" ? "二寸照"           : "2-Inch Photo"
        case .chinaPassport:     language == "zh" ? "中国护照"         : "China Passport"
        case .driverLicense:     language == "zh" ? "驾驶证"           : "Driver License"
        case .studentID:         language == "zh" ? "学生证"           : "Student ID"
        case .socialSecurity:    language == "zh" ? "社保卡"           : "Social Security Card"
        case .resume:            language == "zh" ? "简历照"           : "Resume Photo"
        case .standardPortrait:  language == "zh" ? "证件照（胸部以上）" : "Standard Portrait"
        case .halfBody:          language == "zh" ? "半身照"           : "Half-Body Portrait"
        case .fullBody:          language == "zh" ? "全身照"           : "Full-Body Portrait"
        case .chinaMarriage:     language == "zh" ? "结婚登记照"       : "Marriage Photo"
        case .oneInchLarge:      language == "zh" ? "大一寸"           : "Large 1-Inch"
        case .twoInchSmall:      language == "zh" ? "小二寸"           : "Small 2-Inch"
        case .ncreExam:          language == "zh" ? "计算机等级"       : "NCRE Exam"
        }
    }

    // MARK: - SF Symbol Icon

    var icon: String {
        switch self {
        case .chinaID:          "creditcard.fill"
        case .oneInch:          "1.square.fill"
        case .twoInch:          "2.square.fill"
        case .chinaPassport:    "books.vertical.fill"
        case .driverLicense:    "car.fill"
        case .studentID:        "graduationcap.fill"
        case .socialSecurity:   "cross.case.fill"
        case .resume:           "doc.text.fill"
        case .standardPortrait: "person.crop.rectangle.fill"
        case .halfBody:         "figure.stand"
        case .fullBody:         "figure.walk"
        case .chinaMarriage:    "heart.fill"
        case .oneInchLarge:     "rectangle.portrait.fill"
        case .twoInchSmall:     "rectangle.portrait"
        case .ncreExam:         "desktopcomputer"
        }
    }

    // MARK: - Size Label

    var sizeLabel: String {
        switch self {
        case .chinaID:          "26×32 mm"
        case .oneInch:          "25×35 mm"
        case .twoInch:          "35×49 mm"
        case .chinaPassport:    "33×48 mm"
        case .driverLicense:    "22×32 mm"
        case .studentID:        "25×35 mm"
        case .socialSecurity:   "26×32 mm"
        case .resume:           "25×35 mm"
        case .standardPortrait: "35×45 mm"
        case .halfBody:         "89×127 mm"
        case .fullBody:         "102×152 mm"
        case .chinaMarriage:    "53×35 mm"
        case .oneInchLarge:     "33×48 mm"
        case .twoInchSmall:     "35×45 mm"
        case .ncreExam:         "32×40 mm"
        }
    }

    /// Pixel dimensions at 300 DPI derived from photoSizeMM.
    var pixelSize: (width: Int, height: Int) {
        let scale = 300.0 / 25.4
        let (w, h) = photoSizeMM
        return (Int((w * scale).rounded()), Int((h * scale).rounded()))
    }

    /// Background color hex without # (used by HivisionIDPhotos add_background).
    var backgroundColorHex: String {
        switch self {
        case .driverLicense: return "5395e2"
        case .chinaMarriage: return "c10000"
        case .studentID:     return "438edb"
        default:             return "ffffff"
        }
    }

    /// Physical dimensions in millimeters (width × height).
    var photoSizeMM: (width: Double, height: Double) {
        switch self {
        case .chinaID:          (26, 32)
        case .oneInch:          (25, 35)
        case .twoInch:          (35, 49)
        case .chinaPassport:    (33, 48)
        case .driverLicense:    (22, 32)
        case .studentID:        (25, 35)
        case .socialSecurity:   (26, 32)
        case .resume:           (25, 35)
        case .standardPortrait: (35, 45)
        case .halfBody:         (89, 127)
        case .fullBody:         (102, 152)
        case .chinaMarriage:    (53, 35)
        case .oneInchLarge:     (33, 48)
        case .twoInchSmall:     (35, 45)
        case .ncreExam:         (32, 40)
        }
    }

    // MARK: - Sorting

    /// All specs ordered for display: free first, Pro last.
    static func sorted(for locale: Locale) -> [IDPhotoSpec] {
        allCases.sorted { a, b in
            if a.isPro != b.isPro { return !a.isPro }
            guard let idxA = allCases.firstIndex(of: a),
                  let idxB = allCases.firstIndex(of: b) else { return false }
            return idxA < idxB
        }
    }

    /// Default selected spec.
    static func defaultSpec(for locale: Locale) -> IDPhotoSpec { .chinaID }

    // MARK: - Generation Prompt (image-edit friendly imperative)

    /// Protect facial identity only; hair/attire are controlled by user options.
    private var preserveSuffix: String {
        "保持人物的脸部五官完全不变。"
    }

    /// Standard Chinese ID photo framing per GB/GA461 and MPS specs:
    /// head (chin-to-crown) occupies ~2/3 of photo height; only head + neck + collar visible;
    /// small top margin (~5–10% of height) above crown; no shoulders below collar.
    private var idFramingSuffix: String {
        "重新构图为标准证件照：头部（下巴到头顶）占照片高度约2/3，画面仅包含头部和颈部到领口衣领处，不露出肩膀以下，头顶距照片顶边留约5%空白，人脸水平居中。"
    }

    var prompt: String {
        switch self {
        // 居民身份证：26×32mm，白底，深色正装，头部占2/3高度（GA461-2004标准）
        case .chinaID:
            return "将背景替换为纯白色（#FFFFFF），将服装替换为深色系正装衬衫（不着白色或浅色上衣），均匀柔和正面补光，轻微修肤保持自然，输出中国居民身份证标准证件照效果。" + idFramingSuffix + preserveSuffix

        // 一寸照：25×35mm，白底，头部占2/3高度
        case .oneInch:
            return "将背景替换为纯白色（#FFFFFF），将服装替换为正式商务衬衫或上衣，均匀柔和光线，轻微修肤，输出中国标准一寸证件照（25×35mm）效果。" + idFramingSuffix + preserveSuffix

        // 二寸照：35×49mm，白底，头部占2/3高度
        case .twoInch:
            return "将背景替换为纯白色（#FFFFFF），将服装替换为正式商务装，均匀柔和正面光线，输出中国标准二寸证件照（35×49mm）效果。" + idFramingSuffix + preserveSuffix

        // 护照：33×48mm，白底，头部高占总高60-70%（MFA标准：头部高28-33mm）
        case .chinaPassport:
            return "将背景替换为纯白色（#FFFFFF），将服装替换为深色纯色领口上衣（无图案无logo），均匀柔和正面光线，嘴巴自然闭合，输出中国护照申请标准照片效果。重新构图：头部（下巴到头顶）占照片高度约65%，仅含头部到衣领处，头顶距顶边留约8%空白，人脸水平居中。" + preserveSuffix

        // 驾驶证：22×32mm，蓝底，头部占2/3高度（约19-22mm头长）
        case .driverLicense:
            return "将背景替换为纯蓝色（#5395E2），将服装替换为整洁深色上衣（避免白色上衣），均匀柔和光线，输出中国机动车驾驶证标准证件照效果。" + idFramingSuffix + preserveSuffix

        // 学生证：25×35mm，蓝底，与一寸照相同头部比例
        case .studentID:
            return "将背景替换为淡蓝色（#438EDB），将服装替换为整洁学生装或正式上衣，均匀柔和光线，轻微修肤，输出学生证标准证件照效果。" + idFramingSuffix + preserveSuffix

        // 社保卡：26×32mm，白底，与居民身份证相同规格
        case .socialSecurity:
            return "将背景替换为纯白色（#FFFFFF），将服装替换为深色商务上衣，均匀柔和正面光线，输出中国社会保障卡标准证件照效果。" + idFramingSuffix + preserveSuffix

        // 简历照：25×35mm，白底或浅蓝色，头肩构图略宽松，可见上半身
        case .resume:
            return "将背景替换为纯白色或浅蓝色，将服装替换为专业商务装（白衬衫或正装上衣），均匀柔和光线，轻微修肤，输出专业简历标准证件照效果。重新构图：画面包含头部到肩膀以下约一指宽区域，头部居中，面部占照片高度约60%。" + preserveSuffix

        // 证件照胸部以上：35×45mm，白底，含胸部以上
        case .standardPortrait:
            return "将背景替换为纯白色（#FFFFFF），将服装替换为整洁商务装，均匀柔和影棚光线，轻微修肤，输出标准胸部以上证件人像效果。重新构图：画面包含头部到胸口约1/3处，头部占照片上方约55%高度，人物居中。" + preserveSuffix

        // 半身照：89×127mm（3R），白底或浅灰，腰部以上
        case .halfBody:
            return "将背景替换为纯白色或浅灰色影棚背景，将服装替换为专业商务休闲装，均匀柔和影棚光线，轻微修肤，输出专业半身人像效果（腰部以上，完整展示上半身和双手）。" + preserveSuffix

        // 全身照：102×152mm（4R），白底或浅灰，头顶到脚
        case .fullBody:
            return "将背景替换为纯白色或浅灰色影棚背景，将服装替换为专业商务休闲装，均匀柔和影棚光线，轻微修肤，输出专业全身人像效果（头顶到鞋底完整呈现，头顶距上边留约5%空白）。" + preserveSuffix

        // 结婚登记照：35×53mm，红底，双人头肩构图
        case .chinaMarriage:
            return "将背景替换为中国婚姻登记专用纯红色（#C10000），两人服装替换为半正式装（男士衬衫或西装，女士整洁上衣），均匀柔和正面光线，男左女右站立，输出中国结婚登记标准照片效果。重新构图：双人头肩特写，两人头部（下巴到头顶）合计占照片高度约2/3，仅含头部到领口处。" + preserveSuffix

        // 大一寸：33×48mm，白底，与护照规格相近
        case .oneInchLarge:
            return "将背景替换为纯白色（#FFFFFF），将服装替换为正式商务装，均匀柔和正面光线，输出中国大一寸（33×48mm）证件照效果，适用于普通话水平测试及党员申请。" + idFramingSuffix + preserveSuffix

        // 小二寸/ICAO：35×45mm，白底，符合ICAO人脸识别标准
        case .twoInchSmall:
            return "将背景替换为纯白色（#FFFFFF），将服装替换为纯色无图案上衣，均匀柔和正面光线，输出小二寸（35×45mm）证件照效果，符合ICAO生物特征标准。" + idFramingSuffix + preserveSuffix

        // NCRE考试：32×40mm，白底，标准证件照比例
        case .ncreExam:
            return "将背景替换为纯白色（#FFFFFF），将服装替换为正式商务装，均匀柔和正面光线，输出全国计算机等级考试（NCRE）标准报名照片效果。" + idFramingSuffix + preserveSuffix
        }
    }
}

// MARK: - Custom Size Spec (Pro)

struct CustomSizeSpec {
    var widthMM: Double = 35
    var heightMM: Double = 45

    static let minWidth: Double = 20
    static let maxWidth: Double = 60
    static let minHeight: Double = 20
    static let maxHeight: Double = 80

    var sizeLabel: String { "\(Int(widthMM))×\(Int(heightMM)) mm" }
    var photoSizeMM: (width: Double, height: Double) { (widthMM, heightMM) }

    var pixelSize: (width: Int, height: Int) {
        let scale = 300.0 / 25.4
        return (Int((widthMM * scale).rounded()), Int((heightMM * scale).rounded()))
    }

    var backgroundColorHex: String { "ffffff" }

    var prompt: String {
        "生成自定义证件照：纯白色背景，\(Int(widthMM))×\(Int(heightMM))mm，正脸居中，头肩构图，自然表情，均匀柔和光线，专业证件照风格。"
    }
}
