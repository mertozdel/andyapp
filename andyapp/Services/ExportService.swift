import SwiftUI
import SwiftData

// MARK: - Export Scope

enum ExportScope: CaseIterable, Equatable {
    case last7Days, last30Days, last90Days, allTime, specificDate, singleEntry

    var label: String {
        switch self {
        case .last7Days:    return "Last 7 days"
        case .last30Days:   return "Last 30 days"
        case .last90Days:   return "Last 90 days"
        case .allTime:      return "All time"
        case .specificDate: return "Specific date"
        case .singleEntry:  return "Single entry"
        }
    }

    var icon: String {
        switch self {
        case .last7Days, .last30Days, .last90Days: return "calendar"
        case .allTime:      return "infinity"
        case .specificDate: return "calendar.badge.clock"
        case .singleEntry:  return "doc.text"
        }
    }
}

// MARK: - ExportService

enum ExportService {

    private static func intensityUIColor(for level: Int) -> UIColor {
        switch level {
        case 1...3: return UIColor(red: 85/255,  green: 239/255, blue: 196/255, alpha: 1)
        case 4...6: return UIColor(red: 253/255, green: 203/255, blue: 110/255, alpha: 1)
        case 7...8: return UIColor(red: 232/255, green: 115/255, blue: 90/255,  alpha: 1)
        default:    return UIColor(red: 192/255, green: 57/255,  blue: 43/255,  alpha: 1)
        }
    }

    private static func intensityLabelText(for level: Int) -> String {
        switch level {
        case 1...2: return "Barely there"
        case 3...4: return "Noticeable"
        case 5...6: return "Quite intense"
        case 7...8: return "Very intense"
        default:    return "Overwhelming"
        }
    }

    // MARK: PDF

    static func generatePDF(entries: [DiaryEntry]) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let margin: CGFloat = 48
        let contentWidth = pageRect.width - margin * 2
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let purple    = UIColor(red: 139/255, green: 108/255, blue: 175/255, alpha: 1)
        let df = DateFormatter(); df.dateStyle = .long;   df.timeStyle = .none
        let tf = DateFormatter(); tf.dateStyle = .none;   tf.timeStyle = .short

        let titleFont    = UIFont.boldSystemFont(ofSize: 22)
        let subtitleFont = UIFont.systemFont(ofSize: 11)
        let captionFont2 = UIFont.systemFont(ofSize: 10)
        let entryDateFont = UIFont.boldSystemFont(ofSize: 13)
        let bodyFont     = UIFont.systemFont(ofSize: 11)
        let captionFont  = UIFont.systemFont(ofSize: 10)
        let questionFont = UIFont.italicSystemFont(ofSize: 10)
        let footerFont   = UIFont.systemFont(ofSize: 9)

        var pageNumber = 1
        var y: CGFloat = 0

        return renderer.pdfData { ctx in

            func drawFooter() {
                let text = "Page \(pageNumber)"
                let attrs: [NSAttributedString.Key: Any] = [.font: footerFont, .foregroundColor: UIColor.lightGray]
                let str = NSAttributedString(string: text, attributes: attrs)
                let sz = str.boundingRect(with: CGSize(width: contentWidth, height: 20), options: [], context: nil)
                str.draw(at: CGPoint(x: pageRect.midX - sz.width / 2, y: pageRect.height - margin + 14))
            }

            func beginNewPage() {
                drawFooter()
                ctx.beginPage()
                pageNumber += 1
                y = margin
            }

            func draw(_ text: String,
                      font: UIFont,
                      color: UIColor = .black,
                      indent: CGFloat = 0,
                      spacing: CGFloat = 5) {
                guard !text.isEmpty else { return }
                let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
                let str = NSAttributedString(string: text, attributes: attrs)
                let w = contentWidth - indent
                let sz = str.boundingRect(
                    with: CGSize(width: w, height: .greatestFiniteMagnitude),
                    options: .usesLineFragmentOrigin, context: nil
                )
                if y + sz.height > pageRect.height - margin - 28 {
                    beginNewPage()
                }
                str.draw(in: CGRect(x: margin + indent, y: y, width: w, height: sz.height))
                y += sz.height + spacing
            }

            // ── First page ──────────────────────────────────────────────────────────

            ctx.beginPage()

            // Purple header
            let headerH: CGFloat = 84
            purple.setFill()
            UIBezierPath(rect: CGRect(x: 0, y: 0, width: pageRect.width, height: headerH)).fill()

            NSAttributedString(
                string: "Personal Diary",
                attributes: [.font: titleFont, .foregroundColor: UIColor.white]
            ).draw(at: CGPoint(x: margin, y: 16))

            NSAttributedString(
                string: "PDF Export  ·  \(entries.count) \(entries.count == 1 ? "entry" : "entries")",
                attributes: [.font: subtitleFont, .foregroundColor: UIColor.white.withAlphaComponent(0.85)]
            ).draw(at: CGPoint(x: margin, y: 47))

            NSAttributedString(
                string: "Exported \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))",
                attributes: [.font: captionFont2, .foregroundColor: UIColor.white.withAlphaComponent(0.6)]
            ).draw(at: CGPoint(x: margin, y: 64))

            y = headerH + 22

            // ── Entries ──────────────────────────────────────────────────────────────

            for (idx, entry) in entries.enumerated() {

                // Ensure at least 90pt of room; otherwise start fresh page
                if y > pageRect.height - margin - 90 { beginNewPage() }

                // Date + time
                let dateStr = df.string(from: entry.createdAt)
                let timeStr = tf.string(from: entry.createdAt)
                let dateAttrs: [NSAttributedString.Key: Any] = [.font: entryDateFont, .foregroundColor: UIColor.black]
                let timeAttrs: [NSAttributedString.Key: Any] = [.font: captionFont,   .foregroundColor: UIColor.darkGray]
                NSAttributedString(string: dateStr, attributes: dateAttrs).draw(at: CGPoint(x: margin, y: y))
                let timeSA = NSAttributedString(string: timeStr, attributes: timeAttrs)
                timeSA.draw(at: CGPoint(x: pageRect.width - margin - timeSA.size().width, y: y + 2))
                y += 20

                // Intensity pill
                let iColor = intensityUIColor(for: entry.emotionalLevel)
                let iLabel = intensityLabelText(for: entry.emotionalLevel)
                let iText  = "● \(entry.emotionalLevel)/10  ·  \(iLabel)"
                NSAttributedString(
                    string: iText,
                    attributes: [.font: UIFont.systemFont(ofSize: 11, weight: .semibold), .foregroundColor: iColor]
                ).draw(at: CGPoint(x: margin, y: y))
                y += 18

                // Emotions
                let emotionStr = entry.emotions.map(\.displayName).joined(separator: "  ·  ")
                draw(emotionStr, font: captionFont, color: .darkGray, spacing: 6)

                // Journal
                if !entry.journalText.isEmpty {
                    y += 2
                    draw(entry.journalText, font: bodyFont, spacing: 6)
                }

                // Body sensations
                let sensations = entry.bodySensations
                if !sensations.isEmpty {
                    draw("Body sensations: \(sensations.count) area\(sensations.count == 1 ? "" : "s") noted",
                         font: captionFont, color: .darkGray, spacing: 4)
                }

                // Sleep box
                if entry.hasSleepData {
                    var parts = ["Sleep"]
                    if let dur = entry.sleepDurationFormatted { parts.append(dur) }
                    if let q   = entry.sleepQuality            { parts.append("Quality \(q)/10") }
                    if let w   = entry.sleepWakeups             { parts.append("Wakeups: \(w)") }
                    if entry.sleepHadDreams == true            { parts.append("Had dreams") }
                    let sleepLine = parts.joined(separator: "  ·  ")

                    let sleepAttrs: [NSAttributedString.Key: Any] = [.font: captionFont, .foregroundColor: UIColor.darkGray]
                    let sleepSA = NSAttributedString(string: sleepLine, attributes: sleepAttrs)
                    let sleepSz = sleepSA.boundingRect(
                        with: CGSize(width: contentWidth - 20, height: .greatestFiniteMagnitude),
                        options: .usesLineFragmentOrigin, context: nil
                    )
                    if y + sleepSz.height + 20 > pageRect.height - margin - 28 { beginNewPage() }

                    let boxRect = CGRect(x: margin - 10, y: y - 5, width: contentWidth + 20, height: sleepSz.height + 18)
                    UIColor(white: 0.94, alpha: 1).setFill()
                    UIBezierPath(roundedRect: boxRect, cornerRadius: 7).fill()
                    sleepSA.draw(in: CGRect(x: margin, y: y + 4, width: contentWidth - 20, height: sleepSz.height))
                    y += sleepSz.height + 22

                    if let notes = entry.sleepNotes, !notes.isEmpty {
                        draw("Sleep notes: \(notes)", font: captionFont, color: .gray, indent: 8, spacing: 4)
                    }
                }

                // Libido
                if let lvl = entry.libidoLevel {
                    var libidoParts = ["Desire  \(lvl)/10"]
                    if let tags = entry.libidoContextTags, !tags.isEmpty {
                        libidoParts.append(tags.joined(separator: ", "))
                    }
                    draw(libidoParts.joined(separator: "  ·  "), font: captionFont, color: .darkGray, spacing: 4)
                    if let notes = entry.libidoNotes, !notes.isEmpty {
                        draw("Desire notes: \(notes)", font: captionFont, color: .gray, indent: 8, spacing: 6)
                    }
                }

                // Prompt answers
                let answers = entry.promptAnswers
                let promptPairs: [(String, String)] = [
                    ("What triggered this?",        answers["trigger"]   ?? ""),
                    ("What do you need right now?", answers["need"]      ?? ""),
                    ("One small thing noticed",     answers["gratitude"] ?? ""),
                ].filter { !$0.1.isEmpty }

                if !promptPairs.isEmpty {
                    y += 2
                    for (question, answer) in promptPairs {
                        draw(question, font: questionFont, color: .gray, spacing: 2)
                        draw(answer,   font: bodyFont, indent: 12, spacing: 6)
                    }
                }

                // Separator
                if idx < entries.count - 1 {
                    y += 6
                    if y < pageRect.height - margin - 28 {
                        UIColor.lightGray.setStroke()
                        let path = UIBezierPath()
                        path.move(to:    CGPoint(x: margin, y: y))
                        path.addLine(to: CGPoint(x: pageRect.width - margin, y: y))
                        path.lineWidth = 0.5
                        path.stroke()
                    }
                    y += 18
                }
            }

            drawFooter()
        }
    }

    // MARK: Write to temp

    static func writeToTemp(_ data: Data) -> URL? {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("diary_export_\(Int(Date().timeIntervalSince1970)).pdf")
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

    @State private var scope: ExportScope = .allTime
    @State private var pickedDate: Date = Date()
    @State private var pickedEntry: DiaryEntry? = nil
    @State private var showEntryPicker = false
    @State private var shareItem: IdentifiableURL?
    @State private var isGenerating = false

    // MARK: Filtered entries

    private var entriesToExport: [DiaryEntry] {
        let cal = Calendar.current
        switch scope {
        case .last7Days:
            guard let start = cal.date(byAdding: .day, value: -7, to: Date()) else { return [] }
            return entries.filter { $0.createdAt >= start }
        case .last30Days:
            guard let start = cal.date(byAdding: .day, value: -30, to: Date()) else { return [] }
            return entries.filter { $0.createdAt >= start }
        case .last90Days:
            guard let start = cal.date(byAdding: .day, value: -90, to: Date()) else { return [] }
            return entries.filter { $0.createdAt >= start }
        case .allTime:
            return entries
        case .specificDate:
            return entries.filter { cal.isDate($0.createdAt, inSameDayAs: pickedDate) }
        case .singleEntry:
            return pickedEntry.map { [$0] } ?? []
        }
    }

    private var previewText: String {
        if scope == .singleEntry {
            if let e = pickedEntry {
                let df = DateFormatter()
                df.dateStyle = .medium; df.timeStyle = .none
                return "1 entry · \(df.string(from: e.createdAt))"
            }
            return "No entry selected"
        }
        let c = entriesToExport.count
        if c == 0 { return "No entries for this period" }
        return "\(c) \(c == 1 ? "entry" : "entries")"
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#160D27").ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        scopeSection

                        if scope == .specificDate {
                            datePickerCard
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        if scope == .singleEntry {
                            entryPickerButton
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        previewChip
                            .frame(maxWidth: .infinity, alignment: .center)

                        exportButton
                    }
                    .padding(20)
                    .animation(.spring(response: 0.35), value: scope)
                }
            }
            .navigationTitle("Export PDF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.secondary)
                }
            }
            .sheet(item: $shareItem) { item in ShareSheet(url: item.url) }
            .sheet(isPresented: $showEntryPicker) { entryPickerSheet }
        }
    }

    // MARK: Scope section

    private var scopeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Export Scope")
            VStack(spacing: 0) {
                ForEach(Array(ExportScope.allCases.enumerated()), id: \.offset) { idx, s in
                    Button {
                        withAnimation(.spring(response: 0.3)) { scope = s }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: s.icon)
                                .font(.callout)
                                .foregroundStyle(scope == s ? Color(hex: "#C4A0E8") : .secondary)
                                .frame(width: 24)
                            Text(s.label)
                                .font(.subheadline)
                                .foregroundStyle(scope == s ? Color(hex: "#C4A0E8") : .primary)
                            Spacer()
                            if scope == s {
                                Image(systemName: "checkmark")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color(hex: "#C4A0E8"))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    if idx < ExportScope.allCases.count - 1 {
                        Divider().padding(.horizontal, 16)
                    }
                }
            }
            .background(Color(hex: "#231441"), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: Date picker card

    private var datePickerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Pick a Date")
            DatePicker("", selection: $pickedDate, in: ...Date(), displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(Color(hex: "#8B6CAF"))
                .padding(12)
                .background(Color(hex: "#231441"), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: Entry picker button

    private var entryPickerButton: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Select Entry")
            Button { showEntryPicker = true } label: {
                HStack(spacing: 12) {
                    if let e = pickedEntry {
                        Circle()
                            .fill(levelColor(for: e.emotionalLevel))
                            .frame(width: 8, height: 8)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(DateFormatter.localizedString(from: e.createdAt, dateStyle: .medium, timeStyle: .short))
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                            if !e.journalText.isEmpty {
                                Text(e.journalText)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    } else {
                        Image(systemName: "doc.text")
                            .foregroundStyle(.secondary)
                        Text("Choose an entry…")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(16)
                .background(Color(hex: "#231441"), in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Preview chip

    private var previewChip: some View {
        let empty = entriesToExport.isEmpty && !(scope == .singleEntry && pickedEntry == nil)
        return HStack(spacing: 6) {
            Image(systemName: entriesToExport.isEmpty ? "exclamationmark.circle" : "doc.richtext.fill")
                .font(.caption)
            Text(previewText)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(entriesToExport.isEmpty ? .secondary : Color(hex: "#C4A0E8"))
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(entriesToExport.isEmpty ? Color(hex: "#2B1B50").opacity(0.5) : Color(hex: "#8B6CAF").opacity(0.18))
        )
        .overlay(
            Capsule()
                .stroke(entriesToExport.isEmpty ? Color.clear : Color(hex: "#C4A0E8").opacity(0.4), lineWidth: 1)
        )
        .animation(.spring(response: 0.25), value: entriesToExport.count)
    }

    // MARK: Export button

    private var exportButton: some View {
        Button { exportData() } label: {
            HStack(spacing: 8) {
                if isGenerating {
                    ProgressView().tint(.white).scaleEffect(0.85)
                } else {
                    Image(systemName: "square.and.arrow.up")
                }
                Text(isGenerating ? "Generating PDF…" : "Export PDF")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                entriesToExport.isEmpty
                    ? Color(hex: "#8B6CAF").opacity(0.4)
                    : Color(hex: "#8B6CAF"),
                in: RoundedRectangle(cornerRadius: 14)
            )
        }
        .buttonStyle(.plain)
        .disabled(entriesToExport.isEmpty || isGenerating)
    }

    // MARK: Entry picker sheet

    private var entryPickerSheet: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#160D27").ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 1) {
                        ForEach(entries) { entry in
                            Button {
                                pickedEntry = entry
                                showEntryPicker = false
                            } label: {
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(levelColor(for: entry.emotionalLevel))
                                        .frame(width: 8, height: 8)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(DateFormatter.localizedString(
                                            from: entry.createdAt,
                                            dateStyle: .medium,
                                            timeStyle: .short
                                        ))
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.primary)

                                        HStack(spacing: 6) {
                                            Text("\(entry.emotionalLevel)/10")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(levelColor(for: entry.emotionalLevel))
                                            if !entry.journalText.isEmpty {
                                                Text("·").foregroundStyle(.tertiary)
                                                Text(entry.journalText)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                                    .lineLimit(1)
                                            }
                                        }
                                    }
                                    Spacer()
                                    if pickedEntry?.id == entry.id {
                                        Image(systemName: "checkmark")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(Color(hex: "#C4A0E8"))
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(hex: "#231441"))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(20)
                }
            }
            .navigationTitle("Choose Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showEntryPicker = false }
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }

    private func levelColor(for level: Int) -> Color {
        switch level {
        case 1...3: return Color(hex: "#55EFC4")
        case 4...6: return Color(hex: "#FDCB6E")
        case 7...8: return Color(hex: "#E8735A")
        default:    return Color(hex: "#C0392B")
        }
    }

    private func exportData() {
        guard !entriesToExport.isEmpty, !isGenerating else { return }
        isGenerating = true
        let toExport = entriesToExport
        Task { @MainActor in
            let data = ExportService.generatePDF(entries: toExport)
            if let url = ExportService.writeToTemp(data) {
                shareItem = IdentifiableURL(url: url)
            }
            isGenerating = false
        }
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
    func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
}
