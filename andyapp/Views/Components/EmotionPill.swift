import SwiftUI

struct EmotionPill: View {
    let emotion: Emotion
    var isSelected: Bool = false
    var isSmall: Bool = false

    var body: some View {
        HStack(spacing: isSmall ? 3 : 5) {
            Text(emotion.emoji)
                .font(.system(size: isSmall ? 10 : 14))
            Text(emotion.displayName)
                .font(isSmall ? .caption2.weight(.medium) : .caption.weight(.medium))
        }
        .padding(.horizontal, isSmall ? 7 : 10)
        .padding(.vertical, isSmall ? 3 : 6)
        .background(
            Capsule().fill(
                isSelected ? Color(hex: "#8B6CAF").opacity(0.40) : Color(hex: "#2B1B50")
            )
        )
        .overlay(
            Capsule().stroke(
                isSelected ? Color(hex: "#C4A0E8").opacity(0.80) : .clear,
                lineWidth: 1
            )
        )
        .foregroundStyle(isSelected ? Color(hex: "#C4A0E8") : .primary)
    }
}
