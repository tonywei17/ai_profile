import SwiftUI

// MARK: - Beauty Level

enum BeautyLevel: String, CaseIterable, Identifiable {
    case natural
    case lightEnhance
    case professional

    var id: String { rawValue }
    var isPro: Bool { self != .natural }

    var icon: String {
        switch self {
        case .natural:      "face.smiling"
        case .lightEnhance: "sparkles"
        case .professional: "wand.and.stars"
        }
    }

    var promptSuffix: String? {
        switch self {
        case .natural:      nil
        case .lightEnhance:
            "Perform a subtle natural skin retouch on the subject's face only. "
            + "Gently even out skin tone and reduce minor redness. "
            + "Strictly preserve pore texture, freckles, moles, and all natural skin features. "
            + "Do not add any new marks, spots, or blemishes that are not in the original photo. "
            + "Do not smooth the skin to a plastic finish. Keep the result photorealistic."
        case .professional:
            "Perform professional portrait retouching on the subject's face only. "
            + "Even out skin tone, remove only transient blemishes such as acne or temporary redness, "
            + "and apply subtle brightening under the eyes. "
            + "Preserve natural pore texture and skin micro-detail — do not smooth to a plastic finish. "
            + "Do not add any new marks, spots, moles, or blemishes that are not in the original photo. "
            + "Do not alter the subject's facial structure, identity, or expression. "
            + "Respect the subject's original skin tone; do not wash out the complexion. "
            + "The result must look photorealistic and suitable for official ID documents."
        }
    }

    func displayName(language: String) -> String {
        switch self {
        case .natural:      return l(zh: "自然",     en: "Natural",       ja: "ナチュラル",   ko: "내추럴",      lang: language)
        case .lightEnhance: return l(zh: "轻微美颜", en: "Light Enhance", ja: "ライト補正",   ko: "라이트 보정", lang: language)
        case .professional: return l(zh: "专业精修", en: "Pro Retouch",   ja: "プロ補正",     ko: "프로 보정",   lang: language)
        }
    }

    private func l(zh: String, en: String, ja: String, ko: String, lang: String) -> String {
        switch lang { case "zh": zh; case "ja": ja; case "ko": ko; default: en }
    }
}

// MARK: - Attire

enum Attire: String, CaseIterable, Identifiable {
    case keepOriginal
    case darkSuit
    case navySuit
    case whiteShirt
    case professionalBlouse

    var id: String { rawValue }
    var isPro: Bool { self != .keepOriginal }

    var icon: String {
        switch self {
        case .keepOriginal:       "tshirt.fill"
        case .darkSuit:           "briefcase.fill"
        case .navySuit:           "briefcase.fill"
        case .whiteShirt:         "shirt.fill"
        case .professionalBlouse: "person.fill"
        }
    }

    var promptSuffix: String? {
        switch self {
        case .keepOriginal:       nil
        case .darkSuit:           "The subject should be wearing a dark formal business suit with a white collared shirt and tie."
        case .navySuit:           "The subject should be wearing a navy blue formal business suit with a light blue collared dress shirt."
        case .whiteShirt:         "The subject should be wearing a clean white collared dress shirt."
        case .professionalBlouse: "The subject should be wearing a professional solid-color blouse or blazer suitable for official documents."
        }
    }

    func displayName(language: String) -> String {
        switch self {
        case .keepOriginal:       return l(zh: "保持原样", en: "Original",       ja: "そのまま",       ko: "원본 유지",  lang: language)
        case .darkSuit:           return l(zh: "深色西装", en: "Dark Suit",      ja: "ダークスーツ",   ko: "다크 수트",  lang: language)
        case .navySuit:           return l(zh: "藏蓝西装", en: "Navy Suit",      ja: "ネイビースーツ", ko: "네이비 수트", lang: language)
        case .whiteShirt:         return l(zh: "白衬衫",   en: "White Shirt",    ja: "白シャツ",       ko: "흰 셔츠",    lang: language)
        case .professionalBlouse: return l(zh: "正装上衣", en: "Blouse/Blazer", ja: "ブレザー",       ko: "블레이저",   lang: language)
        }
    }

    private func l(zh: String, en: String, ja: String, ko: String, lang: String) -> String {
        switch lang { case "zh": zh; case "ja": ja; case "ko": ko; default: en }
    }
}

// MARK: - Hair Grooming

enum HairGrooming: String, CaseIterable, Identifiable {
    case keepOriginal
    case tidyUp

    var id: String { rawValue }
    var isPro: Bool { self != .keepOriginal }

    var icon: String {
        switch self {
        case .keepOriginal: "comb.fill"
        case .tidyUp:       "scissors"
        }
    }

    var promptSuffix: String? {
        switch self {
        case .keepOriginal: nil
        case .tidyUp:       "Neatly groom the hair: remove stray hairs, smooth flyaways, and ensure a clean professional appearance."
        }
    }

    func displayName(language: String) -> String {
        switch self {
        case .keepOriginal: return l(zh: "保持原样", en: "Original",  ja: "そのまま", ko: "원본 유지", lang: language)
        case .tidyUp:       return l(zh: "整理发型", en: "Tidy Up",   ja: "整える",   ko: "정돈",      lang: language)
        }
    }

    private func l(zh: String, en: String, ja: String, ko: String, lang: String) -> String {
        switch lang { case "zh": zh; case "ja": ja; case "ko": ko; default: en }
    }
}

// MARK: - Background Color

enum BackgroundColorOption: String, CaseIterable, Identifiable {
    case specDefault
    case pureWhite
    case lightBlue
    case lightGray
    case red

    var id: String { rawValue }
    var isPro: Bool { self != .specDefault }

    var icon: String {
        switch self {
        case .specDefault: "rectangle.dashed"
        case .pureWhite:   "rectangle.fill"
        case .lightBlue:   "rectangle.fill"
        case .lightGray:   "rectangle.fill"
        case .red:         "rectangle.fill"
        }
    }

    /// Swatch color for UI rendering. nil means "auto" icon.
    var swatchColor: Color? {
        switch self {
        case .specDefault: nil
        case .pureWhite:   .white
        case .lightBlue:   Color(red: 0.83, green: 0.91, blue: 0.97)
        case .lightGray:   Color(red: 0.91, green: 0.91, blue: 0.91)
        case .red:         Color(red: 0.81, green: 0.19, blue: 0.19)
        }
    }

    var promptSuffix: String? {
        switch self {
        case .specDefault: nil
        case .pureWhite:   "Use a pure #FFFFFF white background."
        case .lightBlue:   "Use a light sky-blue (#D4E9F7) solid background."
        case .lightGray:   "Use a neutral light gray (#E8E8E8) solid background."
        case .red:         "Use a vivid red (#D03030) solid background."
        }
    }

    func displayName(language: String) -> String {
        switch self {
        case .specDefault: return l(zh: "规格默认", en: "Default",     ja: "規格標準",       ko: "규격 기본",    lang: language)
        case .pureWhite:   return l(zh: "纯白",     en: "White",       ja: "白",             ko: "흰색",        lang: language)
        case .lightBlue:   return l(zh: "浅蓝",     en: "Light Blue",  ja: "ライトブルー",   ko: "라이트 블루", lang: language)
        case .lightGray:   return l(zh: "浅灰",     en: "Light Gray",  ja: "ライトグレー",   ko: "라이트 그레이", lang: language)
        case .red:         return l(zh: "红色",     en: "Red",          ja: "赤",             ko: "빨간색",      lang: language)
        }
    }

    private func l(zh: String, en: String, ja: String, ko: String, lang: String) -> String {
        switch lang { case "zh": zh; case "ja": ja; case "ko": ko; default: en }
    }
}

// MARK: - Accessories Cleanup

enum AccessoriesCleanup: String, CaseIterable, Identifiable {
    case keepAsIs
    case removeGlasses

    var id: String { rawValue }
    var isPro: Bool { self != .keepAsIs }

    var icon: String {
        switch self {
        case .keepAsIs:        "hand.raised.fill"
        case .removeGlasses:   "eyeglasses"
        }
    }

    var promptSuffix: String? {
        switch self {
        case .keepAsIs:      nil
        case .removeGlasses: "Remove eyeglasses from the subject's face while preserving the natural eye area."
        }
    }

    func displayName(language: String) -> String {
        switch self {
        case .keepAsIs:      return l(zh: "保持原样", en: "Original",         ja: "そのまま",   ko: "원본 유지", lang: language)
        case .removeGlasses: return l(zh: "去眼镜",   en: "Remove Glasses",   ja: "メガネ除去", ko: "안경 제거", lang: language)
        }
    }

    private func l(zh: String, en: String, ja: String, ko: String, lang: String) -> String {
        switch lang { case "zh": zh; case "ja": ja; case "ko": ko; default: en }
    }
}

// MARK: - Aggregated Options

struct PhotoOptions {
    var beauty: BeautyLevel = .natural
    var attire: Attire = .keepOriginal
    var hair: HairGrooming = .keepOriginal
    var background: BackgroundColorOption = .specDefault
    var accessories: AccessoriesCleanup = .keepAsIs

    static let defaults = PhotoOptions()

    var hasProSelection: Bool {
        beauty.isPro || attire.isPro || hair.isPro
            || background.isPro || accessories.isPro
    }

    private static let safetyConstraint =
        "IMPORTANT: Preserve the subject's exact facial identity, structure, and natural expression throughout all edits. "
        + "Do not add any new facial features, marks, or blemishes that are not present in the original photo."

    func buildPromptSuffix() -> String {
        let suffixes = [
            beauty.promptSuffix,
            attire.promptSuffix,
            hair.promptSuffix,
            background.promptSuffix,
            accessories.promptSuffix,
        ].compactMap { $0 }

        guard !suffixes.isEmpty else { return "" }
        return " " + suffixes.joined(separator: " ") + " " + Self.safetyConstraint
    }
}
