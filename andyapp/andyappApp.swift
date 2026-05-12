import SwiftUI
import SwiftData

@main
struct MedicusApp: App {
    @StateObject private var loc = LocalizationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(loc)
                .environment(\.locale, loc.language.locale)
        }
        .modelContainer(for: DiaryEntry.self)
    }
}
