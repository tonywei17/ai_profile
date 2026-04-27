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

    /// Common suffix instructing the model to preserve identity & framing.
    private var preserveSuffix: String {
        " Preserve the person's face, identity, hairstyle, and current framing exactly. Do not change the pose or crop."
    }

    var prompt: String {
        switch self {
        case .chinaID:
            return "Replace the background with a pure solid white (#FFFFFF). Change the outfit to a neat dark-colored business shirt or blouse. Apply even soft frontal lighting and clean the skin while keeping it natural. Output as a Chinese resident ID card photo style." + preserveSuffix
        case .oneInch:
            return "Replace the background with a pure solid white (#FFFFFF). Change the outfit to professional business attire (white shirt or dark blouse). Apply even soft lighting, remove harsh shadows, and lightly retouch the skin while keeping it natural. Output as a standard Chinese 1-inch ID photo." + preserveSuffix
        case .twoInch:
            return "Replace the background with a pure solid white (#FFFFFF). Change the outfit to formal business attire suitable for an official Chinese 2-inch ID photo. Apply even soft frontal lighting, remove shadows, and lightly retouch the skin." + preserveSuffix
        case .chinaPassport:
            return "Replace the background with a pure solid white (#FFFFFF) meeting Chinese passport standards. Change the outfit to a plain dark-colored top with collar (no patterns, no logos). Apply even soft frontal lighting with no shadows on background. Set a neutral relaxed expression with mouth closed." + preserveSuffix
        case .driverLicense:
            return "Replace the background with a solid light blue color (#5395E2) matching PRC driver's license requirements. Change the outfit to a neat top. Apply even soft lighting and remove any hat or head covering." + preserveSuffix
        case .studentID:
            return "Replace the background with a solid pure white or light blue. Change the outfit to a neat school-appropriate top. Apply even soft lighting and lightly retouch the skin to look fresh and natural." + preserveSuffix
        case .socialSecurity:
            return "Replace the background with a pure solid white (#FFFFFF). Change the outfit to a plain dark business top. Apply even soft frontal lighting matching PRC social security card photo requirements (same standard as resident ID card)." + preserveSuffix
        case .resume:
            return "Replace the background with a pure solid white or light blue. Change the outfit to professional business-casual attire (white shirt, blazer, or smart blouse). Apply even soft lighting and lightly retouch the skin. Make the person look confident and approachable for a Chinese resume photo." + preserveSuffix
        case .standardPortrait:
            return "Replace the background with a pure solid white (#FFFFFF). Change the outfit to neat business attire. Apply even soft studio lighting, remove harsh shadows, and lightly retouch the skin while keeping it natural. Output as a standard chest-up ID portrait." + preserveSuffix
        case .halfBody:
            return "Replace the background with a clean solid white or light gray studio backdrop. Change the outfit to professional or smart-casual attire. Apply even soft studio lighting, retouch the skin lightly, and produce magazine-quality portrait colors." + preserveSuffix
        case .fullBody:
            return "Replace the background with a clean solid white or light gray studio backdrop. Change the outfit to professional or smart-casual attire. Apply even soft studio lighting, retouch the skin lightly, and produce professional portrait photography colors and quality." + preserveSuffix
        case .chinaMarriage:
            return "Replace the background with a solid red color (#C10000) for Chinese marriage registration. Change both people's outfits to semi-formal attire (the man in a shirt or light suit, the woman in a red top or smart blouse). Apply even soft frontal lighting and add natural warm smiles. Keep the man on the left and the woman on the right with shoulders gently touching." + preserveSuffix
        case .oneInchLarge:
            return "Replace the background with a pure solid white (#FFFFFF). Change the outfit to formal business attire. Apply even soft frontal lighting matching the Chinese 大一寸 standard used for Putonghua proficiency tests and Communist Party member applications." + preserveSuffix
        case .twoInchSmall:
            return "Replace the background with a pure solid white (#FFFFFF). Change the outfit to a plain solid-color top with no patterns. Apply even soft frontal lighting with no shadows, meeting ICAO biometric standards for overseas visa applications." + preserveSuffix
        case .ncreExam:
            return "Replace the background with a pure solid white (#FFFFFF). Change the outfit to neat formal business attire. Apply even soft frontal lighting matching Chinese NCRE (Computer Rank Examination) registration photo requirements." + preserveSuffix
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
        "Generate a custom ID photo: plain white background, \(Int(widthMM))×\(Int(heightMM))mm, face centered front-on, head-and-shoulders composition, natural expression, even soft lighting, professional ID photo style."
    }
}
