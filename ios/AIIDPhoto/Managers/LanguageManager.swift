import SwiftUI

// MARK: - Supported Languages

enum AppLanguage: String, CaseIterable, Identifiable {
    case system            = "system"
    case chineseSimplified = "zh"
    case english           = "en"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system:            return "跟随系统 / Follow System"
        case .chineseSimplified: return "中文（简体）"
        case .english:           return "English"
        }
    }

    var flag: String {
        switch self {
        case .system:            return "🌐"
        case .chineseSimplified: return "🇨🇳"
        case .english:           return "🇺🇸"
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
            return language == "zh" ? "跟随系统" : "System"
        case .light:
            return language == "zh" ? "浅色模式" : "Light"
        case .dark:
            return language == "zh" ? "深色模式" : "Dark"
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

    /// Resolved 2-letter language code: "zh" or "en".
    var effectiveCode: String {
        if language == .system {
            let preferred = Locale.preferredLanguages.first ?? "zh"
            return preferred.hasPrefix("zh") ? "zh" : "en"
        }
        return language.rawValue
    }
}
