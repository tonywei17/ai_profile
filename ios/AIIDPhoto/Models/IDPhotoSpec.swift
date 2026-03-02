import Foundation

// MARK: - ID Photo Spec

enum IDPhotoSpec: String, CaseIterable, Identifiable {
    // China
    case chinaID
    case chinaPassport
    case chinaMarriage       // PRO — couple photo
    // Japan
    case japanMyNumber
    case japanPassport
    case japanResume         // 履歴書
    case japanDriverLicense  // 運転免許証
    case japanResidenceCard  // 在留カード
    // Korea
    case koreaID
    case koreaResume         // 이력서
    // USA
    case usPassport
    // UK
    case ukPassport
    // Schengen / EU
    case schengenVisa
    // Australia / NZ
    case ausPassport
    // Universal exam
    case exam

    var id: String { rawValue }

    /// Pro-only specs require subscription to use.
    var isPro: Bool {
        switch self {
        case .chinaMarriage: true
        default:             false
        }
    }

    /// Whether this spec is a couple/two-person photo.
    var isCouplePhoto: Bool {
        switch self {
        case .chinaMarriage: true
        default:             false
        }
    }

    // MARK: - Localized Display Name

    func displayName(language: String) -> String {
        switch self {
        case .chinaID:
            return names(zh: "居民身份证", en: "China ID Card",  ja: "中国居民身份証", ko: "중국 신분증", lang: language)
        case .chinaPassport:
            return names(zh: "中国护照",   en: "China Passport", ja: "中国旅券",       ko: "중국 여권",   lang: language)
        case .chinaMarriage:
            return names(zh: "结婚登记照", en: "Marriage Photo",  ja: "結婚届写真",     ko: "결혼 등록 사진", lang: language)
        case .japanMyNumber:
            return names(zh: "My Number", en: "My Number Card", ja: "マイナンバー",   ko: "마이넘버 카드", lang: language)
        case .japanPassport:
            return names(zh: "日本护照",   en: "Japan Passport", ja: "日本旅券",       ko: "일본 여권",    lang: language)
        case .japanResume:
            return names(zh: "日本履历书", en: "Japan Resume",   ja: "履歴書",         ko: "일본 이력서",  lang: language)
        case .japanDriverLicense:
            return names(zh: "日本驾照",   en: "JP License",     ja: "運転免許証",     ko: "일본 운전면허", lang: language)
        case .japanResidenceCard:
            return names(zh: "日本在留卡", en: "Residence Card",  ja: "在留カード",     ko: "재류 카드",    lang: language)
        case .koreaID:
            return names(zh: "韩国身份证", en: "Korea ID Card",  ja: "韓国住民票",     ko: "주민등록증",   lang: language)
        case .koreaResume:
            return names(zh: "韩国履历书", en: "Korea Resume",   ja: "韓国履歴書",     ko: "이력서",       lang: language)
        case .usPassport:
            return names(zh: "美国护照",   en: "US Passport",    ja: "アメリカ旅券",   ko: "미국 여권",    lang: language)
        case .ukPassport:
            return names(zh: "英国护照",   en: "UK Passport",    ja: "英国旅券",       ko: "영국 여권",    lang: language)
        case .schengenVisa:
            return names(zh: "欧洲申根",   en: "Schengen Visa",  ja: "シェンゲンVISA", ko: "쉥겐 비자",    lang: language)
        case .ausPassport:
            return names(zh: "澳洲护照",   en: "AU Passport",    ja: "オーストラリア旅券", ko: "호주 여권", lang: language)
        case .exam:
            return names(zh: "考试证件照", en: "Exam / Test",    ja: "試験用写真",     ko: "시험용 증명사진", lang: language)
        }
    }

    private func names(zh: String, en: String, ja: String, ko: String, lang: String) -> String {
        switch lang {
        case "zh": return zh
        case "ja": return ja
        case "ko": return ko
        default:   return en
        }
    }

    // MARK: - SF Symbol Icon

    var icon: String {
        switch self {
        case .chinaID:            "creditcard.fill"
        case .chinaPassport:      "books.vertical.fill"
        case .chinaMarriage:      "heart.fill"
        case .japanMyNumber:      "checkmark.seal.fill"
        case .japanPassport:      "airplane.departure"
        case .japanResume:        "doc.text.fill"
        case .japanDriverLicense: "car.fill"
        case .japanResidenceCard: "person.crop.rectangle.fill"
        case .koreaID:            "person.text.rectangle.fill"
        case .koreaResume:        "doc.text.fill"
        case .usPassport:         "globe.americas.fill"
        case .ukPassport:         "globe.europe.africa.fill"
        case .schengenVisa:       "mappin.and.ellipse"
        case .ausPassport:        "sun.max.fill"
        case .exam:               "pencil.and.list.clipboard"
        }
    }

    // MARK: - Size Label (universal, no i18n needed)

    var sizeLabel: String {
        switch self {
        case .chinaID:            "26×32 mm"
        case .chinaPassport:      "33×48 mm"
        case .chinaMarriage:      "35×53 mm"
        case .japanMyNumber:      "35×45 mm"
        case .japanPassport:      "35×45 mm"
        case .japanResume:        "30×40 mm"
        case .japanDriverLicense: "24×30 mm"
        case .japanResidenceCard: "30×40 mm"
        case .koreaID:            "35×45 mm"
        case .koreaResume:        "30×40 mm"
        case .usPassport:         "51×51 mm"
        case .ukPassport:         "35×45 mm"
        case .schengenVisa:       "35×45 mm"
        case .ausPassport:        "35×45 mm"
        case .exam:               "25×35 mm"
        }
    }

    /// Physical dimensions in millimeters (width × height).
    var photoSizeMM: (width: Double, height: Double) {
        switch self {
        case .chinaID:            (26, 32)
        case .chinaPassport:      (33, 48)
        case .chinaMarriage:      (35, 53)
        case .japanMyNumber:      (35, 45)
        case .japanPassport:      (35, 45)
        case .japanResume:        (30, 40)
        case .japanDriverLicense: (24, 30)
        case .japanResidenceCard: (30, 40)
        case .koreaID:            (35, 45)
        case .koreaResume:        (30, 40)
        case .usPassport:         (51, 51)
        case .ukPassport:         (35, 45)
        case .schengenVisa:       (35, 45)
        case .ausPassport:        (35, 45)
        case .exam:               (25, 35)
        }
    }

    // MARK: - Regions

    /// Primary region codes (ISO 3166-1 alpha-2) this spec is most relevant to.
    var primaryRegions: Set<String> {
        switch self {
        case .chinaID:            ["CN"]
        case .chinaPassport:      ["CN", "TW", "HK", "MO"]
        case .chinaMarriage:      ["CN"]
        case .japanMyNumber:      ["JP"]
        case .japanPassport:      ["JP"]
        case .japanResume:        ["JP"]
        case .japanDriverLicense: ["JP"]
        case .japanResidenceCard: ["JP"]
        case .koreaID:            ["KR"]
        case .koreaResume:        ["KR"]
        case .usPassport:         ["US"]
        case .ukPassport:         ["GB"]
        case .schengenVisa:       ["AT","BE","CZ","DK","EE","FI","FR","DE","GR",
                                   "HU","IS","IT","LV","LI","LT","LU","MT","NL",
                                   "NO","PL","PT","SK","SI","ES","SE","CH"]
        case .ausPassport:        ["AU","NZ"]
        case .exam:               []   // universal — always appears near the end
        }
    }

    // MARK: - Locale-Aware Sorting

    /// Return all cases sorted so the device's local region specs appear first.
    /// Pro specs sort to the end within their region group.
    static func sorted(for locale: Locale) -> [IDPhotoSpec] {
        let region = locale.region?.identifier ?? ""
        return allCases.sorted { a, b in
            let aRegion = a.primaryRegions.contains(region) ? 1 : 0
            let bRegion = b.primaryRegions.contains(region) ? 1 : 0
            if aRegion != bRegion { return aRegion > bRegion }
            // Within same region group, free specs first
            if a.isPro != b.isPro { return !a.isPro }
            // Preserve original declaration order as tie-break
            return allCases.firstIndex(of: a)! < allCases.firstIndex(of: b)!
        }
    }

    /// Convenience: the first spec for a given locale (used as default selection).
    static func defaultSpec(for locale: Locale) -> IDPhotoSpec {
        sorted(for: locale).first ?? .chinaID
    }

    // MARK: - Gemini Prompt (always English for best API results)

    var prompt: String {
        switch self {
        case .chinaID:
            return "Generate a Chinese resident ID card application photo: pure white background, 26×32mm, face centered front-on, head occupies about 2/3 of the photo height, head top 2-4mm from top edge, even soft lighting, natural skin tone, professional ID photo style."
        case .chinaPassport:
            return "Generate a Chinese passport photo: pure white background, 33×48mm, face centered, head-and-shoulders composition, eyes aligned slightly above center, even lighting, natural relaxed expression, meets Chinese passport standards."
        case .chinaMarriage:
            return "Generate a Chinese marriage registration couple photo: solid red background (#C10000), 35×53mm, two people side by side with the man on the left and woman on the right, both facing the camera directly, head-and-shoulders composition centered in the frame, shoulders gently touching, even soft lighting, natural warm smiles, both wearing semi-formal attire, suitable for official Chinese civil affairs marriage registration."
        case .japanMyNumber:
            return "Generate a Japan My Number card photo: pure white background, 35×45mm, face centered, head occupies upper 70-80% of frame, natural expression, even lighting, no shadows, meets Japanese My Number card photo requirements."
        case .japanPassport:
            return "Generate a Japan passport photo: pure white background, 35×45mm, face centered, head-and-shoulders, eyes at center-to-upper area of frame, natural expression, even lighting, no shadows, meets Japan Ministry of Foreign Affairs passport photo standards."
        case .japanResume:
            return "Generate a Japanese resume (履歴書) photo: plain white or light blue solid background, 30×40mm, face centered front-on, head-and-shoulders with upper chest visible, natural calm expression, even soft lighting, professional business appearance, suitable for Japanese job applications."
        case .japanDriverLicense:
            return "Generate a Japanese driver's license photo: plain solid color background, 24×30mm, face centered, upper body (上三分身), head top 2-3mm from top edge, no hat, natural expression, even lighting, meets Japanese police driver's license photo requirements."
        case .japanResidenceCard:
            return "Generate a Japanese residence card (在留カード) photo: plain white background, 30×40mm, face centered front-on, head-and-shoulders, head top 2-4mm from top edge, no hat, natural expression with mouth closed, even soft lighting, no shadows, meets Japanese Immigration Services Agency residence card photo requirements."
        case .koreaID:
            return "Generate a Korean national ID registration photo: white background, 35×45mm (3.5×4.5cm), face centered front-on, natural expression, even soft lighting, no accessories covering face, meets Korean resident registration card standards."
        case .koreaResume:
            return "Generate a Korean resume (이력서) photo: plain white or light solid background, 30×40mm, face centered front-on, head-and-shoulders, calm professional expression, even soft lighting, suitable for Korean job applications."
        case .usPassport:
            return "Generate a US passport photo: white background, 2×2 inch (51×51mm), head centered, face occupies 50-70% of frame height, neutral expression, eyes open and looking directly at camera, even lighting, no shadows on background, meets US State Department standards."
        case .ukPassport:
            return "Generate a UK passport photo: light grey or white background, 35×45mm, face centered, head and shoulders, natural expression with mouth closed, even lighting, no shadows, meets UK Identity and Passport Service requirements."
        case .schengenVisa:
            return "Generate a Schengen visa photo: light plain background, 35×45mm, face centered, head and shoulders, relaxed natural expression, even lighting, meets ICAO biometric photo standards for EU Schengen visa applications."
        case .ausPassport:
            return "Generate an Australian passport photo: plain white or off-white background, 35×45mm, face centered with head covering 70-80% of height, neutral expression, even lighting, no shadows, meets Australian Passport Office photo requirements."
        case .exam:
            return "Generate a standard 1-inch exam registration photo: white background, 25×35mm, face centered, head-and-shoulders, natural expression, even lighting, suitable for TOEFL, IELTS, CET, and other exam registrations."
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
