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
            "仅对人物面部进行轻微自然修肤：轻柔均匀肤色、淡化轻微泛红。"
            + "严格保留毛孔纹理、雀斑、痣等原有皮肤特征，不得新增任何斑点瑕疵，不得磨皮过度。保持结果真实自然。"
        case .professional:
            "仅对人物面部进行专业级精修：均匀肤色，去除痘痘、临时性泛红等暂时性瑕疵，轻微提亮眼下区域。"
            + "保留自然毛孔纹理，不得磨皮过度。不得新增任何原照片中不存在的斑点、痣或瑕疵。"
            + "不得改变人物面部结构、身份或原有肤色。结果需真实自然，适合正式证件照。"
        }
    }

    func displayName(language: String) -> String {
        switch self {
        case .natural:      return l(zh: "自然",     en: "Natural",       ja: "ナチュラル",   ko: "내추럴",      vi: "Tự nhiên", id: "Natural", pt: "Natural", lang: language)
        case .lightEnhance: return l(zh: "轻微美颜", en: "Light Enhance", ja: "ライト補正",   ko: "라이트 보정", vi: "Làm đẹp nhẹ", id: "Perbaikan Ringan", pt: "Retoque Leve", lang: language)
        case .professional: return l(zh: "专业精修", en: "Pro Retouch",   ja: "プロ補正",     ko: "프로 보정",   vi: "Chỉnh sửa Pro", id: "Retouching Pro", pt: "Retoque Pro", lang: language)
        }
    }

    private func l(zh: String, en: String, ja: String, ko: String,
                   vi: String? = nil, id: String? = nil, pt: String? = nil, lang: String) -> String {
        switch lang { case "zh": zh; case "ja": ja; case "ko": ko; case "vi": vi ?? en; case "id": id ?? en; case "pt": pt ?? en; default: en }
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
        case .keepOriginal:       "忽略任何换装指令，严格保留被摄者原有服装，不得替换或修改服装。"
        case .darkSuit:           "将服装替换为深色正式西装，内搭白色领带衬衫并佩戴领带。"
        case .navySuit:           "将服装替换为藏蓝色正式西装，内搭浅蓝色领口衬衫。"
        case .whiteShirt:         "将服装替换为整洁的白色领口衬衫。"
        case .professionalBlouse: "将服装替换为专业纯色上衣或西装外套，适合正式证件照。"
        }
    }

    func displayName(language: String) -> String {
        switch self {
        case .keepOriginal:       return l(zh: "保持原样", en: "Original",       ja: "そのまま",       ko: "원본 유지",  vi: "Giữ nguyên", id: "Asli", pt: "Original", lang: language)
        case .darkSuit:           return l(zh: "深色西装", en: "Dark Suit",      ja: "ダークスーツ",   ko: "다크 수트",  vi: "Vest tối", id: "Jas Gelap", pt: "Terno Escuro", lang: language)
        case .navySuit:           return l(zh: "藏蓝西装", en: "Navy Suit",      ja: "ネイビースーツ", ko: "네이비 수트", vi: "Vest xanh navy", id: "Jas Navy", pt: "Terno Azul", lang: language)
        case .whiteShirt:         return l(zh: "白衬衫",   en: "White Shirt",    ja: "白シャツ",       ko: "흰 셔츠",    vi: "Áo trắng", id: "Kemeja Putih", pt: "Camisa Branca", lang: language)
        case .professionalBlouse: return l(zh: "正装上衣", en: "Blouse/Blazer", ja: "ブレザー",       ko: "블레이저",   vi: "Áo blazer", id: "Blazer", pt: "Blazer", lang: language)
        }
    }

    private func l(zh: String, en: String, ja: String, ko: String,
                   vi: String? = nil, id: String? = nil, pt: String? = nil, lang: String) -> String {
        switch lang { case "zh": zh; case "ja": ja; case "ko": ko; case "vi": vi ?? en; case "id": id ?? en; case "pt": pt ?? en; default: en }
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
        case .tidyUp:       "整理发型：去除散发和碎发，使发型整洁利落，呈现专业干净的形象。"
        }
    }

    func displayName(language: String) -> String {
        switch self {
        case .keepOriginal: return l(zh: "保持原样", en: "Original",  ja: "そのまま", ko: "원본 유지", vi: "Giữ nguyên", id: "Asli", pt: "Original", lang: language)
        case .tidyUp:       return l(zh: "整理发型", en: "Tidy Up",   ja: "整える",   ko: "정돈",      vi: "Chỉnh tóc", id: "Rapikan", pt: "Arrumar", lang: language)
        }
    }

    private func l(zh: String, en: String, ja: String, ko: String,
                   vi: String? = nil, id: String? = nil, pt: String? = nil, lang: String) -> String {
        switch lang { case "zh": zh; case "ja": ja; case "ko": ko; case "vi": vi ?? en; case "id": id ?? en; case "pt": pt ?? en; default: en }
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

    /// Hex string (no #) sent to backend for background processing. nil = use spec default.
    var bgColorHex: String? {
        switch self {
        case .specDefault: nil
        case .pureWhite:   "ffffff"
        case .lightBlue:   "d4e9f7"
        case .lightGray:   "e8e8e8"
        case .red:         "d03030"
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
        case .specDefault: return l(zh: "规格默认", en: "Default",     ja: "規格標準",       ko: "규격 기본",    vi: "Mặc định", id: "Default", pt: "Padrão", lang: language)
        case .pureWhite:   return l(zh: "纯白",     en: "White",       ja: "白",             ko: "흰색",        vi: "Trắng", id: "Putih", pt: "Branco", lang: language)
        case .lightBlue:   return l(zh: "浅蓝",     en: "Light Blue",  ja: "ライトブルー",   ko: "라이트 블루", vi: "Xanh nhạt", id: "Biru Muda", pt: "Azul Claro", lang: language)
        case .lightGray:   return l(zh: "浅灰",     en: "Light Gray",  ja: "ライトグレー",   ko: "라이트 그레이", vi: "Xám nhạt", id: "Abu Muda", pt: "Cinza Claro", lang: language)
        case .red:         return l(zh: "红色",     en: "Red",          ja: "赤",             ko: "빨간색",      vi: "Đỏ", id: "Merah", pt: "Vermelho", lang: language)
        }
    }

    private func l(zh: String, en: String, ja: String, ko: String,
                   vi: String? = nil, id: String? = nil, pt: String? = nil, lang: String) -> String {
        switch lang { case "zh": zh; case "ja": ja; case "ko": ko; case "vi": vi ?? en; case "id": id ?? en; case "pt": pt ?? en; default: en }
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
        case .removeGlasses: "去除被摄者面部的眼镜，同时保留眼睛区域的自然状态。"
        }
    }

    func displayName(language: String) -> String {
        switch self {
        case .keepAsIs:      return l(zh: "保持原样", en: "Original",         ja: "そのまま",   ko: "원본 유지", vi: "Giữ nguyên", id: "Asli", pt: "Original", lang: language)
        case .removeGlasses: return l(zh: "去眼镜",   en: "Remove Glasses",   ja: "メガネ除去", ko: "안경 제거", vi: "Bỏ kính", id: "Hapus Kacamata", pt: "Remover Óculos", lang: language)
        }
    }

    private func l(zh: String, en: String, ja: String, ko: String,
                   vi: String? = nil, id: String? = nil, pt: String? = nil, lang: String) -> String {
        switch lang { case "zh": zh; case "ja": ja; case "ko": ko; case "vi": vi ?? en; case "id": id ?? en; case "pt": pt ?? en; default: en }
    }
}

// MARK: - Expression Style

enum ExpressionStyle: String, CaseIterable, Identifiable {
    case neutral
    case subtleSmile
    case naturalSmile

    var id: String { rawValue }
    var isPro: Bool { false }

    var icon: String {
        switch self {
        case .neutral:     "face.smiling.inverse"
        case .subtleSmile: "face.smiling"
        case .naturalSmile:"mouth.fill"
        }
    }

    var promptSuffix: String? {
        switch self {
        case .neutral:
            "面部表情保持自然沉稳，放松但不微笑，适合正式证件照要求。"
        case .subtleSmile:
            "面部表情呈现轻微微笑：嘴角轻微上扬，自然亲切，不夸张。"
        case .naturalSmile:
            "面部表情呈现自然开朗的微笑：真实友好，可适当露齿（若自然的话）。"
        }
    }

    func displayName(language: String) -> String {
        switch self {
        case .neutral:     return l(zh: "不笑",   en: "Neutral",       ja: "無表情",     ko: "무표정",   vi: "Bình thường", id: "Netral",  pt: "Neutro",  lang: language)
        case .subtleSmile: return l(zh: "微笑",   en: "Subtle Smile",  ja: "微笑み",     ko: "미소",     vi: "Cười nhẹ",    id: "Senyum",  pt: "Sorriso", lang: language)
        case .naturalSmile:return l(zh: "自然笑", en: "Natural Smile", ja: "自然な笑顔", ko: "자연 미소", vi: "Cười tự nhiên",id: "Senyum Alami", pt: "Sorriso Natural", lang: language)
        }
    }

    private func l(zh: String, en: String, ja: String, ko: String,
                   vi: String? = nil, id: String? = nil, pt: String? = nil, lang: String) -> String {
        switch lang { case "zh": zh; case "ja": ja; case "ko": ko; case "vi": vi ?? en; case "id": id ?? en; case "pt": pt ?? en; default: en }
    }
}

// MARK: - Aggregated Options

struct PhotoOptions {
    var beauty: BeautyLevel = .natural
    var attire: Attire = .keepOriginal
    var hair: HairGrooming = .keepOriginal
    var background: BackgroundColorOption = .specDefault
    var accessories: AccessoriesCleanup = .keepAsIs
    var expression: ExpressionStyle = .neutral

    static let defaults = PhotoOptions()

    var hasProSelection: Bool {
        beauty.isPro || attire.isPro || hair.isPro
            || background.isPro || accessories.isPro
    }

    /// 是否有任何"外观编辑"选项处于非默认状态。
    /// HivisionIDPhotos 不接受 prompt，只做抠图+尺寸+底色，
    /// 当此属性为 true 时应跳过 Hivision，改走 Qwen/Bailian 以令选项生效。
    var hasCosmeticEdits: Bool {
        beauty != .natural
            || attire != .keepOriginal
            || hair != .keepOriginal
            || accessories != .keepAsIs
            || expression != .neutral
    }

    private static let safetyConstraint =
        "重要：全程保持被摄者的面部身份和五官结构完全不变。不得添加原照片中不存在的任何新面部特征、斑点或瑕疵。"

    /// 仅包含外观编辑指令（表情/美颜/服装/发型/配饰），用于 Hivision 之后的第二阶段处理。
    /// 背景色由 Hivision 直接处理，不需要出现在此 prompt 中。
    func buildCosmeticPrompt() -> String? {
        let suffixes = [
            expression.promptSuffix,
            beauty.promptSuffix,
            attire.promptSuffix,
            hair.promptSuffix,
            accessories.promptSuffix,
        ].compactMap { $0 }
        guard !suffixes.isEmpty else { return nil }
        return suffixes.joined(separator: " ") + " " + Self.safetyConstraint
    }

    func buildPromptSuffix() -> String {
        let suffixes = [
            expression.promptSuffix,
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
