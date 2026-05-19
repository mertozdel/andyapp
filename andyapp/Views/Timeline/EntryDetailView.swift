import SwiftUI
import SwiftData

struct EntryDetailView: View {
    @Bindable var entry: DiaryEntry
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var loc: LocalizationManager

    @State private var showExport = false

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
                if entry.hasSleepData            { sleepSection }
                if entry.hasLibidoData           { libidoSection }
                if !entry.promptAnswers.isEmpty  { promptAnswersSection }
            }
            .padding(20)
            .iPadCentered(maxWidth: 680)
        }
        .background(Color(hex: "#160D27").ignoresSafeArea())
        .navigationTitle(entry.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showExport = true } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(Color(hex: "#C4A0E8"))
                }
            }
        }
        .sheet(isPresented: $showExport) {
            ExportView(entries: [entry], initialMode: .multiple, preselected: [entry.id])
        }
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
                        Text(L10n.feelings(loc.language))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        emotionRows
                    }
                }
            }
        }
        .padding(18)
        .background(Color(hex: "#231441"), in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.35), radius: 6, y: 2)
    }

    private var intensityArc: some View {
        let fraction = Double(entry.emotionalLevel) / 10.0
        return ZStack {
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(Color.white.opacity(0.12),
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
            sectionLabel(L10n.bodySensationsLabel(loc.language))
            HStack {
                Spacer()
                BodyMapView(sensations: .constant(entry.bodySensations), isReadOnly: true)
                Spacer()
            }
        }
        .padding(18)
        .background(Color(hex: "#231441"), in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.35), radius: 6, y: 2)
    }

    // MARK: Journal

    private var journalSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel(L10n.journalLabel(loc.language))
            Text(entry.journalText)
                .font(.body)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(Color(hex: "#231441"), in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.35), radius: 6, y: 2)
    }

    // MARK: Prompt answers

    private var promptAnswersSection: some View {
        let labelMap: [String: String] = [
            "trigger":   L10n.detailTriggerLabel(loc.language),
            "need":      L10n.detailNeedLabel(loc.language),
            "gratitude": L10n.detailGratitudeLabel(loc.language),
        ]
        return VStack(alignment: .leading, spacing: 12) {
            sectionLabel(L10n.reflectionsLabel(loc.language))
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
        .background(Color(hex: "#231441"), in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.35), radius: 6, y: 2)
    }

    // MARK: Sleep

    private var sleepSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel(L10n.pdfSleep(loc.language))
            if let formatted = entry.sleepDurationFormatted {
                detailRow(label: L10n.duration(loc.language), value: formatted)
            }
            if let q = entry.sleepQuality {
                detailRow(label: L10n.sleepQuality(loc.language), value: "\(q) / 10")
            }
            if let w = entry.sleepWakeups {
                detailRow(label: L10n.timesWokenUp(loc.language), value: "\(w)")
            }
            if entry.sleepHadDreams == true {
                Text(L10n.pdfHadDreams(loc.language))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            if let n = entry.sleepNotes, !n.isEmpty {
                Text(n)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
            }
        }
        .padding(18)
        .background(Color(hex: "#231441"), in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.35), radius: 6, y: 2)
    }

    // MARK: Libido

    private var libidoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel(L10n.pdfDesire(loc.language))
            if let lvl = entry.libidoLevel {
                detailRow(label: L10n.desireLevel(loc.language), value: "\(lvl) / 10")
            }
            if let tags = entry.libidoContextTags, !tags.isEmpty {
                Text(tags.joined(separator: ", "))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            if let n = entry.libidoNotes, !n.isEmpty {
                Text(n)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
            }
        }
        .padding(18)
        .background(Color(hex: "#231441"), in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.35), radius: 6, y: 2)
    }

    // MARK: Helpers

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.callout.weight(.semibold))
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }
}
