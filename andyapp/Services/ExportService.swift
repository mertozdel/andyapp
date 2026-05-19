import SwiftUI
import SwiftData

// MARK: - Export Mode

enum ExportMode: Equatable {
    case date
    case entry
    case multiple
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

    private static func intensityLabelText(for level: Int, language: AppLanguage) -> String {
        switch level {
        case 1...2: return L10n.intensityBarely(language)
        case 3...4: return L10n.intensityNoticeable(language)
        case 5...6: return L10n.intensityQuite(language)
        case 7...8: return L10n.intensityVery(language)
        default:    return L10n.intensityOverwhelming(language)
        }
    }

    // MARK: PDF

    static func generatePDF(entries: [DiaryEntry], language: AppLanguage) -> Data {
        let pageRect  = CGRect(x: 0, y: 0, width: 612, height: 792)
        let margin: CGFloat = 50
        let cw        = pageRect.width - margin * 2
        let renderer  = UIGraphicsPDFRenderer(bounds: pageRect)

        // Section accent colors
        let purple   = UIColor(red: 139/255, green: 108/255, blue: 175/255, alpha: 1)
        let indigo   = UIColor(red: 108/255, green: 92/255,  blue: 231/255, alpha: 1)
        let teal     = UIColor(red: 0/255,   green: 184/255, blue: 148/255, alpha: 1)
        let orange   = UIColor(red: 225/255, green: 112/255, blue: 85/255,  alpha: 1)
        let slate    = UIColor(red: 99/255,  green: 110/255, blue: 114/255, alpha: 1)
        let charcoal = UIColor(red: 45/255,  green: 52/255,  blue: 54/255,  alpha: 1)

        // Formatters
        let df = DateFormatter()
        df.locale = language.locale
        df.dateStyle = .long
        df.timeStyle = .none
        let tf = DateFormatter()
        tf.locale = language.locale
        tf.dateStyle = .none
        tf.timeStyle = .short

        // Fonts
        let appFont      = UIFont.boldSystemFont(ofSize: 26)
        let subtitleFont = UIFont.systemFont(ofSize: 11)
        let tsFont       = UIFont.systemFont(ofSize: 10)
        let entryFont    = UIFont.boldSystemFont(ofSize: 14)
        let bodyFont     = UIFont.systemFont(ofSize: 11)
        let captionFont  = UIFont.systemFont(ofSize: 10)
        let sectionFont  = UIFont.boldSystemFont(ofSize: 8)
        let questionFont = UIFont.italicSystemFont(ofSize: 10)
        let footerFont   = UIFont.systemFont(ofSize: 9)

        var pageNumber = 1
        var y: CGFloat = 0

        return renderer.pdfData { ctx in

            // ── Shared helpers ────────────────────────────────────────────────

            func pageDecorations() {
                UIColor(red: 139/255, green: 108/255, blue: 175/255, alpha: 0.04).setFill()
                UIBezierPath(ovalIn: CGRect(x: pageRect.width - 110, y: -55, width: 200, height: 200)).fill()
                UIBezierPath(ovalIn: CGRect(x: -40, y: pageRect.height - 130, width: 140, height: 140)).fill()
            }

            func drawFooter() {
                let text = L10n.pdfFooter(language, pageNumber)
                let attrs: [NSAttributedString.Key: Any] = [.font: footerFont, .foregroundColor: UIColor.lightGray]
                let sa = NSAttributedString(string: text, attributes: attrs)
                let sz = sa.boundingRect(with: CGSize(width: cw, height: 20), options: [], context: nil)
                sa.draw(at: CGPoint(x: pageRect.midX - sz.width / 2, y: pageRect.height - margin + 14))
                UIColor.lightGray.withAlphaComponent(0.35).setStroke()
                let rule = UIBezierPath()
                rule.move(to:    CGPoint(x: margin, y: pageRect.height - margin + 8))
                rule.addLine(to: CGPoint(x: pageRect.width - margin, y: pageRect.height - margin + 8))
                rule.lineWidth = 0.3
                rule.stroke()
            }

            func newPage() {
                drawFooter()
                ctx.beginPage()
                pageNumber += 1
                pageDecorations()
                y = margin
            }

            // Draws wrapped text; triggers page break if needed
            func draw(_ text: String,
                      font: UIFont,
                      color: UIColor = .black,
                      indent: CGFloat = 0,
                      after spacing: CGFloat = 5) {
                guard !text.isEmpty else { return }
                let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
                let sa = NSAttributedString(string: text, attributes: attrs)
                let w  = cw - indent
                let sz = sa.boundingRect(with: CGSize(width: w, height: .greatestFiniteMagnitude),
                                         options: .usesLineFragmentOrigin, context: nil)
                if y + sz.height > pageRect.height - margin - 32 { newPage() }
                sa.draw(in: CGRect(x: margin + indent, y: y, width: w, height: sz.height))
                y += sz.height + spacing
            }

            // Colored label + fading line across the page
            func sectionHeader(_ title: String, color: UIColor) {
                if y + 22 > pageRect.height - margin - 32 { newPage() }
                let attrs: [NSAttributedString.Key: Any] = [.font: sectionFont, .foregroundColor: color]
                let sa = NSAttributedString(string: title, attributes: attrs)
                let sz = sa.size()
                sa.draw(at: CGPoint(x: margin, y: y + 1))
                color.withAlphaComponent(0.22).setStroke()
                let path = UIBezierPath()
                path.move(to:    CGPoint(x: margin + sz.width + 8, y: y + sz.height / 2 + 1))
                path.addLine(to: CGPoint(x: pageRect.width - margin, y: y + sz.height / 2 + 1))
                path.lineWidth = 0.8
                path.stroke()
                y += sz.height + 7
            }

            // ── Page 1 header ────────────────────────────────────────────────

            ctx.beginPage()
            pageDecorations()

            let headerH: CGFloat = 92
            purple.setFill()
            UIBezierPath(rect: CGRect(x: 0, y: 0, width: pageRect.width, height: headerH)).fill()
            // inner highlight strip
            UIColor.white.withAlphaComponent(0.06).setFill()
            UIBezierPath(rect: CGRect(x: 0, y: headerH - 14, width: pageRect.width, height: 14)).fill()

            NSAttributedString(string: L10n.pdfHeaderTitle(language),
                attributes: [.font: appFont, .foregroundColor: UIColor.white]
            ).draw(at: CGPoint(x: margin, y: 13))

            let entryWord = entries.count == 1
                ? L10n.entrySingular(language)
                : L10n.entryPlural(language)
            NSAttributedString(
                string: L10n.pdfSubtitle(language, entries.count, entryWord),
                attributes: [.font: subtitleFont, .foregroundColor: UIColor.white.withAlphaComponent(0.80)]
            ).draw(at: CGPoint(x: margin, y: 48))

            let exportedDateStr = DateFormatter.localizedString(
                from: Date(),
                dateStyle: .long,
                timeStyle: .short
            )
            NSAttributedString(
                string: L10n.pdfExported(language, exportedDateStr),
                attributes: [.font: tsFont, .foregroundColor: UIColor.white.withAlphaComponent(0.52)]
            ).draw(at: CGPoint(x: margin, y: 68))

            y = headerH + 26

            // ── Entries ──────────────────────────────────────────────────────

            for (idx, entry) in entries.enumerated() {

                if y > pageRect.height - margin - 110 { newPage() }

                let iColor = intensityUIColor(for: entry.emotionalLevel)
                let iLabel = intensityLabelText(for: entry.emotionalLevel, language: language)
                let dateStr = df.string(from: entry.createdAt)
                let timeStr = tf.string(from: entry.createdAt)

                // Entry header card (tinted, with intensity left border)
                let cardH: CGFloat = 58
                iColor.withAlphaComponent(0.09).setFill()
                UIBezierPath(roundedRect: CGRect(x: margin - 10, y: y, width: cw + 20, height: cardH),
                             cornerRadius: 10).fill()
                iColor.setFill()
                UIBezierPath(roundedRect: CGRect(x: margin - 10, y: y, width: 4, height: cardH),
                             cornerRadius: 2).fill()

                // Date (left)
                NSAttributedString(string: dateStr,
                    attributes: [.font: entryFont, .foregroundColor: UIColor.black]
                ).draw(at: CGPoint(x: margin + 7, y: y + 8))

                // Time (right)
                let timeSA = NSAttributedString(string: timeStr,
                    attributes: [.font: captionFont, .foregroundColor: UIColor.darkGray])
                timeSA.draw(at: CGPoint(x: pageRect.width - margin - timeSA.size().width, y: y + 10))

                // Intensity pill
                NSAttributedString(
                    string: "●  \(entry.emotionalLevel) / 10  ·  \(iLabel)",
                    attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: iColor]
                ).draw(at: CGPoint(x: margin + 7, y: y + 35))

                y += cardH + 16

                // ── EMOTIONAL CHECK-IN ──────────────────────────────────────
                let emotions = entry.emotions.map { $0.localizedName(language) }
                if !emotions.isEmpty {
                    sectionHeader(L10n.pdfEmotional(language), color: purple)
                    draw(emotions.joined(separator: "  ·  "), font: captionFont, color: .darkGray, after: 12)
                }

                // ── JOURNAL ─────────────────────────────────────────────────
                if !entry.journalText.isEmpty {
                    sectionHeader(L10n.pdfJournal(language), color: charcoal)
                    draw(entry.journalText, font: bodyFont, after: 12)
                }

                // ── BODY SENSATIONS ─────────────────────────────────────────
                let sensations = entry.bodySensations
                if !sensations.isEmpty {
                    sectionHeader(L10n.pdfBodySensations(language), color: teal)
                    let line = sensations.count == 1
                        ? L10n.pdfSensationsNotedSingular(language)
                        : L10n.pdfSensationsNotedPlural(language, sensations.count)
                    draw(line, font: captionFont, color: .darkGray, after: 12)
                }

                // ── SLEEP ───────────────────────────────────────────────────
                if entry.hasSleepData {
                    sectionHeader(L10n.pdfSleep(language), color: indigo)
                    var sleepParts: [String] = []
                    if let dur = entry.sleepDurationFormatted { sleepParts.append(L10n.pdfDuration(language, dur)) }
                    if let q   = entry.sleepQuality           { sleepParts.append(L10n.pdfQuality(language, q)) }
                    if let w   = entry.sleepWakeups           { sleepParts.append(L10n.pdfWakeups(language, w)) }
                    if !sleepParts.isEmpty {
                        draw(sleepParts.joined(separator: "     "), font: captionFont, color: .darkGray, after: 4)
                    }
                    if entry.sleepHadDreams == true {
                        draw(L10n.pdfHadDreams(language), font: captionFont, color: .darkGray, after: 4)
                    }
                    if let notes = entry.sleepNotes, !notes.isEmpty {
                        draw(L10n.pdfNotes(language, notes), font: captionFont, color: .gray, indent: 10, after: 12)
                    } else {
                        y += 8
                    }
                }

                // ── DESIRE ──────────────────────────────────────────────────
                if let lvl = entry.libidoLevel {
                    sectionHeader(L10n.pdfDesire(language), color: orange)
                    var desireParts = [L10n.pdfDesireLevel(language, lvl)]
                    if let tags = entry.libidoContextTags, !tags.isEmpty {
                        desireParts.append(tags.joined(separator: ", "))
                    }
                    draw(desireParts.joined(separator: "   ·   "), font: captionFont, color: .darkGray, after: 4)
                    if let notes = entry.libidoNotes, !notes.isEmpty {
                        draw(L10n.pdfNotes(language, notes), font: captionFont, color: .gray, indent: 10, after: 12)
                    } else {
                        y += 8
                    }
                }

                // ── REFLECTIONS ─────────────────────────────────────────────
                let answers = entry.promptAnswers
                let pairs: [(String, String)] = [
                    (L10n.pdfWhatTriggered(language),  answers["trigger"]   ?? ""),
                    (L10n.pdfWhatNeed(language),       answers["need"]      ?? ""),
                    (L10n.pdfOneSmallThing(language),  answers["gratitude"] ?? ""),
                ].filter { !$0.1.isEmpty }

                if !pairs.isEmpty {
                    sectionHeader(L10n.pdfReflections(language), color: slate)
                    for (q, a) in pairs {
                        draw(q, font: questionFont, color: .gray, after: 2)
                        draw(a, font: bodyFont, indent: 12, after: 8)
                    }
                    y += 2
                }

                // Separator between entries
                if idx < entries.count - 1 {
                    y += 6
                    if y < pageRect.height - margin - 32 {
                        purple.withAlphaComponent(0.18).setStroke()
                        let sep = UIBezierPath()
                        sep.move(to:    CGPoint(x: margin, y: y))
                        sep.addLine(to: CGPoint(x: pageRect.width - margin, y: y))
                        sep.lineWidth = 1
                        sep.stroke()
                    }
                    y += 22
                }
            }

            drawFooter()
        }
    }

    // MARK: Write to temp

    static func writeToTemp(_ data: Data) -> URL? {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("medicus_diary_\(Int(Date().timeIntervalSince1970)).pdf")
        do {
            try data.write(to: url)
            return url
        } catch { return nil }
    }
}

// MARK: - ExportView

struct ExportView: View {
    let entries: [DiaryEntry]
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var loc: LocalizationManager

    @State private var exportMode: ExportMode
    @State private var pickedDate: Date = Date()
    @State private var pickedEntry: DiaryEntry? = nil
    @State private var selectedIDs: Set<UUID>
    @State private var showEntryPicker = false
    @State private var showMultiPicker = false
    @State private var shareItem: IdentifiableURL?
    @State private var isGenerating = false

    init(entries: [DiaryEntry],
         initialMode: ExportMode = .date,
         preselected: Set<UUID> = []) {
        self.entries = entries
        _exportMode  = State(initialValue: initialMode)
        _selectedIDs = State(initialValue: preselected)
    }

    // MARK: Filtered entries

    private var entriesToExport: [DiaryEntry] {
        switch exportMode {
        case .date:
            return entries.filter { Calendar.current.isDate($0.createdAt, inSameDayAs: pickedDate) }
        case .entry:
            return pickedEntry.map { [$0] } ?? []
        case .multiple:
            return entries.filter { selectedIDs.contains($0.id) }
        }
    }

    private var previewText: String {
        let lang = loc.language
        switch exportMode {
        case .date:
            let c = entriesToExport.count
            let df = DateFormatter(); df.locale = lang.locale; df.dateStyle = .medium; df.timeStyle = .none
            if c == 0 { return L10n.noEntriesOn(lang, df.string(from: pickedDate)) }
            if c == 1 { return L10n.entryOnDate(lang, df.string(from: pickedDate)) }
            return L10n.entriesOnDate(lang, c, df.string(from: pickedDate))
        case .entry:
            guard let e = pickedEntry else { return L10n.noEntrySelected(lang) }
            let df = DateFormatter(); df.locale = lang.locale; df.dateStyle = .medium; df.timeStyle = .none
            return L10n.entryOnDate(lang, df.string(from: e.createdAt))
        case .multiple:
            let c = entriesToExport.count
            if c == 0 { return L10n.noEntriesSelected(lang) }
            return L10n.entriesCountSelected(lang, c)
        }
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#160D27").ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        modeToggle

                        switch exportMode {
                        case .date:
                            calendarCard
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        case .entry:
                            entryPickerCard
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        case .multiple:
                            multiplePickerCard
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        previewChip
                            .frame(maxWidth: .infinity, alignment: .center)

                        sendButton
                    }
                    .padding(20)
                    .iPadCentered(maxWidth: 680)
                    .animation(.spring(response: 0.38, dampingFraction: 0.88), value: exportMode)
                }
            }
            .navigationTitle(L10n.sendTitle(loc.language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.cancel(loc.language)) { dismiss() }
                        .foregroundStyle(.secondary)
                }
            }
            .sheet(item: $shareItem) { item in ShareSheet(url: item.url) }
            .sheet(isPresented: $showEntryPicker) { entryPickerSheet }
            .sheet(isPresented: $showMultiPicker) { multiPickerSheet }
        }
    }

    // MARK: Mode toggle

    private var modeToggle: some View {
        HStack(spacing: 6) {
            modeButton(L10n.calendar(loc.language), icon: "calendar", mode: .date)
            modeButton(L10n.selectEntry(loc.language), icon: "doc.text", mode: .entry)
            modeButton(L10n.multiple(loc.language), icon: "checklist", mode: .multiple)
        }
    }

    private func modeButton(_ label: String, icon: String, mode: ExportMode) -> some View {
        let on = exportMode == mode
        return Button {
            withAnimation(.spring(response: 0.3)) { exportMode = mode }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.caption.weight(.bold))
                Text(label)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(on ? .white : Color(hex: "#C4A0E8").opacity(0.75))
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(on ? Color(hex: "#8B6CAF") : Color(hex: "#2B1B50"))
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.2), value: on)
    }

    // MARK: Calendar card

    private var calendarCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel(L10n.pickADate(loc.language))
            DatePicker("", selection: $pickedDate, in: ...Date(), displayedComponents: .date)
                .datePickerStyle(.graphical)
                .environment(\.locale, loc.language.locale)
                .tint(Color(hex: "#8B6CAF"))
                .padding(14)
                .background(Color(hex: "#1E1040"), in: RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color(hex: "#2B1B50"), lineWidth: 1)
                )
        }
    }

    // MARK: Entry picker card

    private var entryPickerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel(L10n.selectEntryLabel(loc.language))
            Button { showEntryPicker = true } label: {
                HStack(spacing: 12) {
                    if let e = pickedEntry {
                        Circle()
                            .fill(levelColor(for: e.emotionalLevel))
                            .frame(width: 9, height: 9)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(DateFormatter.localizedString(from: e.createdAt, dateStyle: .medium, timeStyle: .short))
                                .font(.subheadline.weight(.semibold))
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
                            .font(.callout)
                            .foregroundStyle(Color(hex: "#C4A0E8").opacity(0.6))
                        Text(L10n.chooseAnEntry(loc.language))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(hex: "#C4A0E8").opacity(0.5))
                }
                .padding(18)
                .background(Color(hex: "#1E1040"), in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "#2B1B50"), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Multiple picker card

    private var multiplePickerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel(L10n.chooseEntriesTitle(loc.language))
            Button { showMultiPicker = true } label: {
                HStack(spacing: 12) {
                    Image(systemName: "checklist")
                        .font(.callout)
                        .foregroundStyle(Color(hex: "#C4A0E8").opacity(0.7))
                    Text(selectedIDs.isEmpty
                         ? L10n.chooseEntriesTitle(loc.language)
                         : L10n.entriesCountSelected(loc.language, selectedIDs.count))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(selectedIDs.isEmpty ? .secondary : .primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(hex: "#C4A0E8").opacity(0.5))
                }
                .padding(18)
                .background(Color(hex: "#1E1040"), in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "#2B1B50"), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Preview chip

    private var previewChip: some View {
        HStack(spacing: 6) {
            Image(systemName: entriesToExport.isEmpty ? "exclamationmark.circle" : "doc.richtext.fill")
                .font(.caption.weight(.semibold))
            Text(previewText)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(entriesToExport.isEmpty ? Color.secondary : Color(hex: "#C4A0E8"))
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(
            Capsule()
                .fill(entriesToExport.isEmpty
                      ? Color(hex: "#2B1B50").opacity(0.5)
                      : Color(hex: "#8B6CAF").opacity(0.18))
        )
        .overlay(
            Capsule()
                .stroke(entriesToExport.isEmpty ? Color.clear : Color(hex: "#C4A0E8").opacity(0.4), lineWidth: 1)
        )
        .animation(.spring(response: 0.25), value: previewText)
    }

    // MARK: Send button

    private var sendButton: some View {
        Button { exportData() } label: {
            HStack(spacing: 8) {
                if isGenerating {
                    ProgressView().tint(.white).scaleEffect(0.85)
                } else {
                    Image(systemName: "paperplane.fill")
                }
                Text(isGenerating ? L10n.generating(loc.language) : L10n.send(loc.language))
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                entriesToExport.isEmpty
                    ? Color(hex: "#8B6CAF").opacity(0.38)
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
                                entryRow(entry, isSelected: pickedEntry?.id == entry.id)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "#2B1B50"), lineWidth: 1)
                    )
                    .padding(20)
                }
            }
            .navigationTitle(L10n.chooseEntryTitle(loc.language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.cancel(loc.language)) { showEntryPicker = false }
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: Multi picker sheet

    private var multiPickerSheet: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#160D27").ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 1) {
                        ForEach(entries) { entry in
                            Button {
                                if selectedIDs.contains(entry.id) {
                                    selectedIDs.remove(entry.id)
                                } else {
                                    selectedIDs.insert(entry.id)
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                entryRow(entry, isSelected: selectedIDs.contains(entry.id))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "#2B1B50"), lineWidth: 1)
                    )
                    .padding(20)
                }
            }
            .navigationTitle(L10n.chooseEntriesTitle(loc.language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.cancel(loc.language)) { showMultiPicker = false }
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.done(loc.language)) { showMultiPicker = false }
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(hex: "#C4A0E8"))
                }
            }
        }
    }

    private func entryRow(_ entry: DiaryEntry, isSelected: Bool) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(levelColor(for: entry.emotionalLevel))
                .frame(width: 9, height: 9)
            VStack(alignment: .leading, spacing: 4) {
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
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color(hex: "#C4A0E8"))
            } else {
                Image(systemName: "circle")
                    .foregroundStyle(Color(hex: "#C4A0E8").opacity(0.3))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(Color(hex: "#1E1040"))
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
        let lang = loc.language
        Task { @MainActor in
            let data = ExportService.generatePDF(entries: toExport, language: lang)
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
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
