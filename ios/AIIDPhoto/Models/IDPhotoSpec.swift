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

    // MARK: - Generation Prompt (English for best AI results)

    var prompt: String {
        switch self {
        case .chinaID:
            return "Generate a Chinese resident ID card photo: pure white background, 26×32mm, face centered front-on, head occupies about 2/3 of the photo height, head top 2-4mm from top edge, even soft lighting, natural skin tone, professional ID photo style."
        case .oneInch:
            return "Generate a standard Chinese 1-inch ID photo: pure white background, 25×35mm, face centered front-on, head-and-shoulders, natural relaxed expression, even soft lighting, professional appearance suitable for resumes, student IDs, and exam registrations."
        case .twoInch:
            return "Generate a standard Chinese 2-inch ID photo: pure white background, 35×49mm, face centered front-on, head-and-shoulders, natural professional expression, even soft lighting, suitable for civil servant exams, teacher certification, and official applications."
        case .chinaPassport:
            return "Generate a Chinese passport photo: pure white background, 33×48mm, face centered, head-and-shoulders composition, eyes aligned slightly above center, even lighting, natural relaxed expression, meets Chinese passport and Hong Kong/Macao travel permit standards."
        case .driverLicense:
            return "Generate a Chinese driver's license photo: light blue solid background (#5395E2), 22×32mm (小一寸), face centered front-on, head-and-shoulders, natural expression, even soft lighting, no hat, meets PRC driver's license photo requirements."
        case .studentID:
            return "Generate a Chinese student ID photo: pure white or light blue solid background, 25×35mm (1-inch), face centered front-on, head-and-shoulders, calm natural expression, even soft lighting, neat appearance suitable for school student ID cards."
        case .socialSecurity:
            return "Generate a Chinese social security card photo: pure white background, 26×32mm, face centered front-on, head occupies about 2/3 of frame, even soft lighting, natural professional expression, meets PRC social security card photo standards (same as resident ID card)."
        case .resume:
            return "Generate a professional resume photo: pure white or light blue solid background, 25×35mm (1-inch), face centered front-on, head-and-shoulders, confident calm expression, even soft lighting, neat business-casual attire, suitable for Chinese job applications."
        case .standardPortrait:
            return "Generate a standard chest-up ID portrait: pure white background, 35×45mm, head-and-shoulders to upper chest visible, face centered front-on, head occupies 70-80% of upper frame, eyes looking directly at camera, natural professional expression, even soft lighting, neat business attire, suitable for general identification and document photos."
        case .halfBody:
            return "Generate a half-body portrait photo: clean white or light gray background, 89×127mm (3R/3.5×5 inch), framing from waist or hips up, person facing camera with relaxed natural posture, head and torso clearly visible, professional or smart-casual attire, even soft lighting, gentle natural smile, sharp focus on face, magazine-quality portrait composition."
        case .fullBody:
            return "Generate a full-body portrait photo: clean white or light studio background, 102×152mm (4R/4×6 inch), full figure from head to feet visible and centered, person standing naturally facing the camera, well-proportioned framing with comfortable spacing above head and below feet, professional or smart-casual outfit, even studio lighting, natural pose, sharp focus throughout, professional portrait photography quality."
        case .chinaMarriage:
            return "Generate a Chinese marriage registration couple photo: solid red background (#C10000), 35×53mm, two people side by side with the man on the left and woman on the right, both facing the camera directly, head-and-shoulders composition centered in the frame, shoulders gently touching, even soft lighting, natural warm smiles, both wearing semi-formal attire, suitable for official Chinese civil affairs marriage registration."
        case .oneInchLarge:
            return "Generate a Chinese 大一寸 (Large 1-Inch) ID photo: pure white background, 33×48mm, face centered front-on, head-and-shoulders, natural professional expression, even soft lighting, suitable for Putonghua proficiency test (普通话证) and Communist Party member applications."
        case .twoInchSmall:
            return "Generate a Chinese 小二寸 (Small 2-Inch) ID photo: pure white background, 35×45mm, face centered front-on, head-and-shoulders, natural calm expression, even soft lighting, meets ICAO biometric standards suitable for overseas visa applications."
        case .ncreExam:
            return "Generate a Chinese NCRE (computer rank examination) ID photo: pure white background, 32×40mm, face centered front-on, head-and-shoulders, natural calm expression, even soft lighting, professional appearance meeting NCRE registration photo requirements."
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
