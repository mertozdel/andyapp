import SwiftUI
import SwiftData

struct EntryDetailView: View {
    @Bindable var entry: DiaryEntry
    @Environment(\.modelContext) private var modelContext

    private var intensityColor: Color {
        switch entry.emotionalLevel {
        case 1...3: return Color(hex: "#55EFC4")
        case 4...6: return Color(hex: "#FDCB6E")
        case 7...8: return Color(hex: "#E8735A")
        default:    return Color(hex: "#C0392B")
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                if !entry.bodySensations.isEmpty { bodyMapSection }
                if !entry.journalText.isEmpty    { journalSection }
                if !entry.promptAnswers.isEmpty  { promptAnswersSection }
            }
            .padding(20)
        }
        .background(Color(hex: "#FAF7FD").ignoresSafeArea())
        .navigationTitle(entry.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(entry.createdAt.formatted(
                .dateTime
                    .weekday(.wide)
                    .month(.wide)
                    .day()
                    .hour()
                    .minute()
            ))
            .font(.subheadline)
            .foregroundStyle(.secondary)

            HStack(alignment: .center, spacing: 20) {
                intensityArc
                    .frame(width: 94, height: 94)

                if !entry.emotions.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Feelings")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        emotionRows
                    }
                }
            }
        }
        .padding(18)
        .background(.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    private var intensityArc: some View {
        let fraction = Double(entry.emotionalLevel) / 10.0
        return ZStack {
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(Color(hex: "#F0EAF5"),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(135))
            Circle()
                .trim(from: 0, to: fraction * 0.75)
                .stroke(intensityColor,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(135))
            VStack(spacing: 1) {
                Text("\(entry.emotionalLevel)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(intensityColor)
                Text("/ 10")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var emotionRows: some View {
        let emotions = entry.emotions
        let rows = stride(from: 0, to: emotions.count, by: 3).map {
            Array(emotions[$0..<min($0 + 3, emotions.count)])
        }
        return VStack(alignment: .leading, spacing: 4) {
            ForEach(rows.indices, id: \.self) { i in
                HStack(spacing: 4) {
                    ForEach(rows[i]) { emotion in
                        EmotionPill(emotion: emotion, isSmall: true)
                    }
                }
            }
        }
    }

    // MARK: Body map

    private var bodyMapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Body sensations")
            HStack {
                Spacer()
                BodyMapView(sensations: .constant(entry.bodySensations), isReadOnly: true)
                Spacer()
            }
        }
        .padding(18)
        .background(.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    // MARK: Journal

    private var journalSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Journal")
            Text(entry.journalText)
                .font(.body)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    // MARK: Prompt answers

    private var promptAnswersSection: some View {
        let labelMap: [String: String] = [
            "trigger":   "What triggered it",
            "need":      "What I needed",
            "gratitude": "One thing I noticed",
        ]
        return VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Reflections")
            ForEach(Array(entry.promptAnswers).sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                VStack(alignment: .leading, spacing: 3) {
                    Text(labelMap[key] ?? key.capitalized)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(value)
                        .font(.callout)
                        .lineSpacing(4)
                }
            }
        }
        .padding(18)
        .background(.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    // MARK: Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }
}
