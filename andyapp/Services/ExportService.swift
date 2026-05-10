import SwiftUI
import SwiftData

// MARK: - Export Format

enum ExportFormat: String, CaseIterable {
    case csv = "CSV"
    case json = "JSON"
    case pdf = "PDF"

    var fileExtension: String {
        switch self {
        case .csv:  return "csv"
        case .json: return "json"
        case .pdf:  return "pdf"
        }
    }

    var icon: String {
        switch self {
        case .csv:  return "tablecells"
        case .json: return "curlybraces"
        case .pdf:  return "doc.richtext"
        }
    }

    var description: String {
        switch self {
        case .csv:  return "Spreadsheet"
        case .json: return "Developer"
        case .pdf:  return "Readable"
        }
    }
}

// MARK: - Export Date Range

enum ExportDateRange: String, CaseIterable {
    case lastWeek    = "Last 7 days"
    case lastMonth   = "Last 30 days"
    case last3Months = "Last 90 days"
    case allTime     = "All time"

    func startDate() -> Date? {
        let cal = Calendar.current
        switch self {
        case .lastWeek:    return cal.date(byAdding: .day, value: -7,  to: Date())
        case .lastMonth:   return cal.date(byAdding: .day, value: -30, to: Date())
        case .last3Months: return cal.date(byAdding: .day, value: -90, to: Date())
        case .allTime:     return nil
        }
    }
}

// MARK: - Codable wrappers

private struct ExportableBodySensation: Codable {
    let region: String
    let side: String
    let type: String
    let intensity: Int
    let note: String?
}

private struct ExportableEntry: Codable {
    let id: String
    let createdAt: String
    let emotionalLevel: Int
    let emotions: [String]
    let bodySensations: [ExportableBodySensation]
    let journalText: String
    let promptAnswers: [String: String]
    let sleepBedtime: String?
    let sleepWakeTime: String?
    let sleepDuration: String?
    let sleepQuality: Int?
    let sleepWakeups: Int?
    let sleepHadDreams: Bool?
    let sleepNotes: String?
    let libidoLevel: Int?
    let libidoNotes: String?
}

private struct ExportWrapper: Codable {
    let exportedAt: String
    let appVersion: String
    let entryCount: Int
    let entries: [ExportableEntry]
}

// MARK: - ExportService

enum ExportService {

    private static let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private static func makeExportable(_ entry: DiaryEntry) -> ExportableEntry {
        ExportableEntry(
            id: entry.id.uuidString,
            createdAt: iso8601.string(from: entry.createdAt),
            emotionalLevel: entry.emotionalLevel,
            emotions: entry.emotions.map(\.displayName),
            bodySensations: entry.bodySensations.map {
                ExportableBodySensation(
                    region: $0.region.displayName,
                    side: $0.side.displayName,
                    type: $0.sensationType.displayName,
                    intensity: $0.localIntensity,
                    note: $0.note
                )
            },
            journalText: entry.journalText,
            promptAnswers: entry.promptAnswers,
            sleepBedtime: entry.sleepBedtime.map { iso8601.string(from: $0) },
            sleepWakeTime: entry.sleepWakeTime.map { iso8601.string(from: $0) },
            sleepDuration: entry.sleepDurationFormatted,
            sleepQuality: entry.hasSleepData ? entry.sleepQuality : nil,
            sleepWakeups: entry.hasSleepData ? entry.sleepWakeups : nil,
            sleepHadDreams: entry.hasSleepData ? entry.sleepHadDreams : nil,
            sleepNotes: entry.sleepNotes,
            libidoLevel: entry.libidoLevel,
            libidoNotes: entry.libidoNotes
        )
    }

    static func generateCSV(entries: [DiaryEntry]) -> String {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .none
        let tf = DateFormatter()
        tf.dateStyle = .none
        tf.timeStyle = .short

        func esc(_ s: String) -> String {
            "\"\(s.replacingOccurrences(of: "\"", with: "\"\""))\""
        }

        var rows = ["ID,Date,Time,EmotionalLevel,Emotions,JournalText,SleepBedtime,SleepWakeTime,SleepDuration,SleepQuality,SleepWakeups,SleepHadDreams,SleepNotes,LibidoLevel,LibidoNotes,BodySensationCount,TriggerAnswer,NeedAnswer,GratitudeAnswer"]

        for entry in entries {
            let answers = entry.promptAnswers
            let row = [
                entry.id.uuidString,
                df.string(from: entry.createdAt),
                tf.string(from: entry.createdAt),
                "\(entry.emotionalLevel)",
                esc(entry.emotions.map(\.displayName).joined(separator: "; ")),
                esc(entry.journalText),
                entry.sleepBedtime.map { tf.string(from: $0) } ?? "",
                entry.sleepWakeTime.map { tf.string(from: $0) } ?? "",
                entry.sleepDurationFormatted ?? "",
                entry.hasSleepData ? "\(entry.sleepQuality)" : "",
                entry.hasSleepData ? "\(entry.sleepWakeups)" : "",
                entry.hasSleepData ? (entry.sleepHadDreams ? "yes" : "no") : "",
                esc(entry.sleepNotes ?? ""),
                entry.libidoLevel.map { "\($0)" } ?? "",
                esc(entry.libidoNotes ?? ""),
                "\(entry.bodySensations.count)",
                esc(answers["trigger"] ?? ""),
                esc(answers["need"] ?? ""),
                esc(answers["gratitude"] ?? ""),
            ].joined(separator: ",")
            rows.append(row)
        }
        return rows.joined(separator: "\n")
    }

    static func generateJSON(entries: [DiaryEntry]) -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let wrapper = ExportWrapper(
            exportedAt: iso8601.string(from: Date()),
            appVersion: "1.0.0",
            entryCount: entries.count,
            entries: entries.map(makeExportable)
        )
        return try? encoder.encode(wrapper)
    }

    static func generatePDF(entries: [DiaryEntry]) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let margin: CGFloat = 48
        let width = pageRect.width - margin * 2
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { ctx in
            ctx.beginPage()
            var y: CGFloat = margin

            func draw(_ text: String, font: UIFont, color: UIColor = .white) {
                let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
                let str = NSAttributedString(string: text, attributes: attrs)
                let size = str.boundingRect(
                    with: CGSize(width: width, height: .greatestFiniteMagnitude),
                    options: .usesLineFragmentOrigin, context: nil)
                if y + size.height > pageRect.height - margin {
                    ctx.beginPage()
                    y = margin
                }
                str.draw(in: CGRect(x: margin, y: y, width: width, height: size.height))
                y += size.height + 4
            }

            let titleFont = UIFont.boldSystemFont(ofSize: 20)
            let headFont  = UIFont.boldSystemFont(ofSize: 13)
            let bodyFont  = UIFont.systemFont(ofSize: 11)
            let metaFont  = UIFont.systemFont(ofSize: 10)

            draw("Medicus — Diary Export", font: titleFont)
            draw(
                "Exported \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short)) · \(entries.count) entries",
                font: metaFont, color: .lightGray
            )
            y += 12

            for entry in entries {
                draw(entry.displayTitle, font: headFont)
                let emotionStr = entry.emotions.map(\.displayName).joined(separator: ", ")
                draw("Intensity \(entry.emotionalLevel)/10\(emotionStr.isEmpty ? "" : "  |  \(emotionStr)")",
                     font: metaFont, color: .lightGray)
                if !entry.journalText.isEmpty {
                    draw(entry.journalText, font: bodyFont)
                }
                if entry.hasSleepData, let dur = entry.sleepDurationFormatted {
                    draw("Sleep: \(dur)  Quality: \(entry.sleepQuality)/10  Wakeups: \(entry.sleepWakeups)",
                         font: metaFont, color: .lightGray)
                }
                if let lvl = entry.libidoLevel {
                    draw("Desire level: \(lvl)/10", font: metaFont, color: .lightGray)
                }
                y += 10
            }
        }
    }

    static func writeToTemp(_ data: Data, format: ExportFormat) -> URL? {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("medicus_export_\(Int(Date().timeIntervalSince1970)).\(format.fileExtension)")
        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }
}

// MARK: - ExportView

struct ExportView: View {
    let entries: [DiaryEntry]
    @Environment(\.dismiss) private var dismiss

    @State private var selectedFormat: ExportFormat = .csv
    @State private var selectedRange: ExportDateRange = .allTime
    @State private var shareItem: IdentifiableURL?
    @State private var isGenerating = false

    private var filteredEntries: [DiaryEntry] {
        guard let start = selectedRange.startDate() else { return entries }
        return entries.filter { $0.createdAt >= start }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#160D27").ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        formatPicker
                        rangePicker
                        Text("\(filteredEntries.count) \(filteredEntries.count == 1 ? "entry" : "entries") will be exported")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        exportButton
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.secondary)
                }
            }
            .sheet(item: $shareItem) { item in
                ShareSheet(url: item.url)
            }
        }
    }

    private var formatPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Format")
            HStack(spacing: 10) {
                ForEach(ExportFormat.allCases, id: \.rawValue) { fmt in
                    formatCard(fmt)
                }
            }
        }
    }

    private func formatCard(_ fmt: ExportFormat) -> some View {
        let on = selectedFormat == fmt
        return Button { selectedFormat = fmt } label: {
            VStack(spacing: 6) {
                Image(systemName: fmt.icon)
                    .font(.title2)
                    .foregroundStyle(on ? Color(hex: "#C4A0E8") : .secondary)
                Text(fmt.rawValue)
                    .font(.caption.weight(.semibold))
                Text(fmt.description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(on ? Color(hex: "#8B6CAF").opacity(0.30) : Color(hex: "#231441"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(on ? Color(hex: "#C4A0E8").opacity(0.8) : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.2), value: on)
    }

    private var rangePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Date Range")
            VStack(spacing: 0) {
                ForEach(Array(ExportDateRange.allCases.enumerated()), id: \.element.rawValue) { idx, range in
                    Button { selectedRange = range } label: {
                        HStack {
                            Text(range.rawValue)
                                .font(.subheadline)
                                .foregroundStyle(selectedRange == range ? Color(hex: "#C4A0E8") : .primary)
                            Spacer()
                            if selectedRange == range {
                                Image(systemName: "checkmark")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color(hex: "#C4A0E8"))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    if idx < ExportDateRange.allCases.count - 1 {
                        Divider().padding(.horizontal, 16)
                    }
                }
            }
            .background(Color(hex: "#231441"), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private var exportButton: some View {
        Button {
            exportData()
        } label: {
            HStack(spacing: 8) {
                if isGenerating {
                    ProgressView().tint(.white).scaleEffect(0.85)
                } else {
                    Image(systemName: "square.and.arrow.up")
                }
                Text(isGenerating ? "Generating…" : "Export")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                filteredEntries.isEmpty
                    ? Color(hex: "#8B6CAF").opacity(0.4)
                    : Color(hex: "#8B6CAF"),
                in: RoundedRectangle(cornerRadius: 14)
            )
        }
        .buttonStyle(.plain)
        .disabled(filteredEntries.isEmpty || isGenerating)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }

    private func exportData() {
        isGenerating = true
        var url: URL?
        switch selectedFormat {
        case .csv:
            let str = ExportService.generateCSV(entries: filteredEntries)
            if let data = str.data(using: .utf8) {
                url = ExportService.writeToTemp(data, format: .csv)
            }
        case .json:
            if let data = ExportService.generateJSON(entries: filteredEntries) {
                url = ExportService.writeToTemp(data, format: .json)
            }
        case .pdf:
            let data = ExportService.generatePDF(entries: filteredEntries)
            url = ExportService.writeToTemp(data, format: .pdf)
        }
        if let url { shareItem = IdentifiableURL(url: url) }
        isGenerating = false
    }
}

// MARK: - Helpers

struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
