import SwiftUI

struct ContentView: View {
    var body: some View {
        DiaryTimelineView()
            .preferredColorScheme(.dark)
    }
}

// MARK: - iPad reading-width helper

struct IPadCentered: ViewModifier {
    @Environment(\.horizontalSizeClass) private var hSizeClass
    let maxWidth: CGFloat

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: hSizeClass == .regular ? maxWidth : .infinity)
            .frame(maxWidth: .infinity)
    }
}

extension View {
    func iPadCentered(maxWidth: CGFloat = 680) -> some View {
        modifier(IPadCentered(maxWidth: maxWidth))
    }
}
