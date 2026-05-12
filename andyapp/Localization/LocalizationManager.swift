import SwiftUI

@MainActor
final class LocalizationManager: ObservableObject {

    private static let storageKey = "appLanguage"

    @Published var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: Self.storageKey)
        }
    }

    init() {
        if let raw = UserDefaults.standard.string(forKey: Self.storageKey),
           let lang = AppLanguage(rawValue: raw) {
            self.language = lang
        } else {
            self.language = .systemDefault
        }
    }
}
