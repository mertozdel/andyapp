import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case german  = "de"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .german:  return "Deutsch"
        }
    }

    var locale: Locale { Locale(identifier: rawValue) }

    static var systemDefault: AppLanguage {
        let code = Locale.current.language.languageCode?.identifier ?? "en"
        return code == "de" ? .german : .english
    }
}
