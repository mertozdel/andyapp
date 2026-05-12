import SwiftUI

struct EntryCardView: View {
    let entry: DiaryEntry
    var isSelectionMode: Bool = false
    var isSelected: Bool = false
    var onMenuExport: (() -> Void)? = nil
    var onMenuSelect: (() -> Void)? = nil

    @EnvironmentObject private var loc: LocalizationManager

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
            if isSelectionMode {
                selectionCheckmark
                    .padding(.trailing, 10)
                    .transition(.scale.combined(with: .opacity))
            }

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
                    Text(L10n.levelN(loc.language, entry.emotionalLevel))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(intensityColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(intensityColor.opacity(0.12), in: Capsule())
                    if !isSelectionMode && (onMenuExport != nil || onMenuSelect != nil) {
                        cardMenu
                    }
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
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isSelected ? Color(hex: "#C4A0E8").opacity(0.7) : .clear, lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.35), radius: 8, y: 2)
        .animation(.spring(response: 0.25), value: isSelectionMode)
        .animation(.spring(response: 0.25), value: isSelected)
    }

    private var cardBackground: Color {
        if isSelected { return Color(hex: "#3A2168") }
        return Color(hex: "#231441")
    }

    private var selectionCheckmark: some View {
        ZStack {
            Circle()
                .stroke(Color(hex: "#C4A0E8").opacity(0.6), lineWidth: 1.5)
                .frame(width: 24, height: 24)
            if isSelected {
                Circle()
                    .fill(Color(hex: "#8B6CAF"))
                    .frame(width: 24, height: 24)
                Image(systemName: "checkmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
            }
        }
        .padding(.top, 2)
    }

    private var cardMenu: some View {
        Menu {
            if let onMenuExport {
                Button {
                    onMenuExport()
                } label: {
                    Label(L10n.exportThisEntry(loc.language), systemImage: "square.and.arrow.up")
                }
            }
            if let onMenuSelect {
                Button {
                    onMenuSelect()
                } label: {
                    Label(L10n.selectMultiple(loc.language), systemImage: "checklist")
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color(hex: "#C4A0E8").opacity(0.75))
                .frame(width: 28, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
    }
}
