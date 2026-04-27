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
    case chinaMarriage      // 结婚登记照 35×53 (双人)
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
        case .chinaMarriage:    "35×53 mm"
        case .oneInchLarge:     "33×48 mm"
        case .twoInchSmall:     "35×45 mm"
        case .ncreExam:         "32×40 mm"
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
        case .chinaMarriage:    (35, 53)
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

    /// Suffix that locks face/hair/pose — does NOT restrict outfit, to avoid contradictions.
    private var preserveSuffix: String {
        "保持人物的脸部特征、发型和姿势不变，不要裁剪或缩放画面。"
    }

    var prompt: String {
        switch self {
        case .chinaID:
            return "请将这张照片的背景换为纯白色（#FFFFFF），使其符合中国居民身份证证件照标准。" + preserveSuffix
        case .oneInch:
            return "请将这张照片的背景换为纯白色（#FFFFFF），使其符合中国标准一寸证件照规格（25×35mm）。" + preserveSuffix
        case .twoInch:
            return "请将这张照片的背景换为纯白色（#FFFFFF），使其符合中国标准二寸证件照规格（35×49mm）。" + preserveSuffix
        case .chinaPassport:
            return "请将这张照片的背景换为纯白色（#FFFFFF），使其符合中国护照申请照片标准，表情自然，嘴巴闭合。" + preserveSuffix
        case .driverLicense:
            return "请将这张照片的背景换为纯蓝色（#5395E2），使其符合中国机动车驾驶证照片标准。" + preserveSuffix
        case .studentID:
            return "请将这张照片的背景换为淡蓝色或纯白色，使其符合中国学生证照片标准。" + preserveSuffix
        case .socialSecurity:
            return "请将这张照片的背景换为纯白色（#FFFFFF），使其符合中国社会保障卡照片标准。" + preserveSuffix
        case .resume:
            return "请将这张照片的背景换为纯白色或浅蓝色，生成专业简历标准证件照，整体形象自信大方。" + preserveSuffix
        case .standardPortrait:
            return "请将这张照片的背景换为纯白色（#FFFFFF），生成标准胸部以上证件人像，光线均匀自然。" + preserveSuffix
        case .halfBody:
            return "请将这张照片的背景换为纯白色或浅灰色影棚背景，生成专业半身人像照片，光线均匀。" + preserveSuffix
        case .fullBody:
            return "请将这张照片的背景换为纯白色或浅灰色影棚背景，生成专业全身人像照片，光线均匀。" + preserveSuffix
        case .chinaMarriage:
            return "请将这张双人合照的背景换为中国婚姻登记专用纯红色（#C10000），男左女右，符合中国结婚登记照片标准。" + preserveSuffix
        case .oneInchLarge:
            return "请将这张照片的背景换为纯白色（#FFFFFF），使其符合中国大一寸规格（33×48mm，适用于普通话水平测试及党员申请）。" + preserveSuffix
        case .twoInchSmall:
            return "请将这张照片的背景换为纯白色（#FFFFFF），使其符合小二寸规格（35×45mm），满足ICAO生物特征识别标准。" + preserveSuffix
        case .ncreExam:
            return "请将这张照片的背景换为纯白色（#FFFFFF），使其符合全国计算机等级考试（NCRE）报名照片规格要求。" + preserveSuffix
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

    var prompt: String {
        "生成自定义证件照：纯白色背景，\(Int(widthMM))×\(Int(heightMM))mm，正脸居中，头肩构图，自然表情，均匀柔和光线，专业证件照风格。"
    }
}
