import SwiftUI

struct EntryCardView: View {
    let entry: DiaryEntry

    private var intensityColor: Color {
        switch entry.emotionalLevel {
        case 1...3: return Color(hex: "#55EFC4")
        case 4...6: return Color(hex: "#FDCB6E")
        case 7...8: return Color(hex: "#E8735A")
        default:    return Color(hex: "#C0392B")
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Left intensity accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(intensityColor)
                .frame(width: 3)
                .padding(.vertical, 4)
                .padding(.trailing, 12)

            VStack(alignment: .leading, spacing: 8) {
                // Header row
                HStack(spacing: 6) {
                    Text(entry.createdAt, style: .time)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Level \(entry.emotionalLevel)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(intensityColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(intensityColor.opacity(0.12), in: Capsule())
                }

                // Emotion pills (up to 4)
                if !entry.emotions.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(Array(entry.emotions.prefix(4))) { emotion in
                            EmotionPill(emotion: emotion, isSmall: true)
                        }
                        if entry.emotions.count > 4 {
                            Text("+\(entry.emotions.count - 4)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Journal preview + mini body map
                HStack(alignment: .top, spacing: 10) {
                    if !entry.journalText.isEmpty {
                        Text(entry.journalText)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if !entry.bodySensations.isEmpty {
                        MiniBodyMapView(sensations: entry.bodySensations)
                            .layoutPriority(-1)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(hex: "#231441"), in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.35), radius: 8, y: 2)
    }
}
