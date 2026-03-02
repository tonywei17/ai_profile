import SwiftUI

// MARK: - Supported Languages

enum AppLanguage: String, CaseIterable, Identifiable {
    case system          = "system"
    case chineseSimplified = "zh"
    case english         = "en"
    case japanese        = "ja"
    case korean          = "ko"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system:            return "跟随系统 / Follow System"
        case .chineseSimplified: return "中文（简体）"
        case .english:           return "English"
        case .japanese:          return "日本語"
        case .korean:            return "한국어"
        }
    }

    var flag: String {
        switch self {
        case .system:            return "🌐"
        case .chineseSimplified: return "🇨🇳"
        case .english:           return "🇺🇸"
        case .japanese:          return "🇯🇵"
        case .korean:            return "🇰🇷"
        }
    }
}

// MARK: - Appearance Mode

enum AppearanceMode: String, CaseIterable {
    case system = "system"
    case light  = "light"
    case dark   = "dark"

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    func displayName(language: String) -> String {
        switch self {
        case .system:
            switch language {
            case "zh": return "跟随系统"
            case "ja": return "システムに従う"
            case "ko": return "시스템 설정"
            default:   return "System"
            }
        case .light:
            switch language {
            case "zh": return "浅色模式"
            case "ja": return "ライトモード"
            case "ko": return "라이트 모드"
            default:   return "Light"
            }
        case .dark:
            switch language {
            case "zh": return "深色模式"
            case "ja": return "ダークモード"
            case "ko": return "다크 모드"
            default:   return "Dark"
            }
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        }
    }
}

// MARK: - Language Manager

@MainActor
final class LanguageManager: ObservableObject {
    /// Persisted preference. "system" means follow device locale.
    @AppStorage("appLanguage") var language: AppLanguage = .system

    /// Persisted appearance preference.
    @AppStorage("appearanceMode") var appearance: AppearanceMode = .system

    /// Resolved 2-letter language code (e.g. "zh", "en", "ja", "ko").
    var effectiveCode: String {
        if language == .system {
            // Use device's preferred display language, not locale region.
            let preferred = Locale.preferredLanguages.first ?? "en"
            if preferred.hasPrefix("zh") { return "zh" }
            if preferred.hasPrefix("ja") { return "ja" }
            if preferred.hasPrefix("ko") { return "ko" }
            return "en"
        }
        return language.rawValue
    }
}
