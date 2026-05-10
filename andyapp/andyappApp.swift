import SwiftUI
import SwiftData

@main
struct MedicusApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: DiaryEntry.self)
    }
}
