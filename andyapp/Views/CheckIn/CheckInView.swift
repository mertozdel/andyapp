import SwiftUI
import SwiftData

// MARK: - CheckInView

struct CheckInView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var currentStep = 0
    @State private var emotionalLevel: Int = 5
    @State private var selectedEmotions: Set<Emotion> = []
    @State private var bodySensations: [BodySensation] = []
    @State private var journalText: String = ""
    @State private var promptAnswers: [String: String] = [:]
    @State private var isSaved = false
    @State private var saveError: String?

    // Sleep tracking
    @State private var sleepEnabled: Bool = false
    @State private var sleepBedtime: Date = Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var sleepWakeTime: Date = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var sleepQuality: Int = 5
    @State private var sleepWakeups: Int = 0
    @State private var sleepDreams: SleepDreams = .none
    @State private var sleepNotes: String = ""

    // Libido tracking
    @State private var libidoEnabled: Bool = false
    @State private var libidoLevel: Int = 5
    @State private var libidoContextTags: Set<String> = []
    @State private var libidoNotes: String = ""

    private let totalSteps = 6

    private var stepTitles: [String] {
        [
            "How intense is it?",
            "What are you feeling?",
            "Where do you feel it?",
            "How did you sleep?",
            "Desire & libido",
            "Tell me more"
        ]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#160D27").ignoresSafeArea()

                if isSaved {
                    savedConfirmation
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.97)),
                            removal: .opacity
                        ))
                } else {
                    VStack(spacing: 0) {
                        progressDots
                            .padding(.top, 8)
                            .padding(.bottom, 24)

                        stepContent
                            .frame(maxHeight: .infinity)
                            .padding(.horizontal, 20)
                            .id(currentStep)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal:   .move(edge: .leading).combined(with: .opacity)
                            ))

                        navigationButtons
                            .padding(.horizontal, 20)
                            .padding(.bottom, 28)
                            .padding(.top, 16)
                    }
                }
            }
            .navigationTitle(isSaved ? "" : stepTitles[currentStep])
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !isSaved {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .animation(.spring(response: 0.42, dampingFraction: 0.88), value: currentStep)
            .animation(.spring(response: 0.42), value: isSaved)
            .alert("Couldn't save entry", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) { saveError = nil }
            } message: {
                Text(saveError ?? "")
            }
        }
    }

    // MARK: Progress dots

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { i in
                Capsule()
                    .fill(i <= currentStep ? Color(hex: "#8B6CAF") : Color.white.opacity(0.20))
                    .frame(width: i == currentStep ? 28 : 8, height: 8)
                    .animation(.spring(response: 0.3), value: currentStep)
            }
        }
    }

    // MARK: Step content router

    @ViewBuilder private var stepContent: some View {
        switch currentStep {
        case 0: IntensityStepView(level: $emotionalLevel)
        case 1: EmotionsStepView(selectedEmotions: $selectedEmotions)
        case 2: BodyMapStepView(sensations: $bodySensations)
        case 3: SleepStepView(
            enabled: $sleepEnabled,
            bedtime: $sleepBedtime,
            wakeTime: $sleepWakeTime,
            quality: $sleepQuality,
            wakeups: $sleepWakeups,
            dreams: $sleepDreams,
            notes: $sleepNotes
        )
        case 4: LibidoStepView(
            enabled: $libidoEnabled,
            level: $libidoLevel,
            contextTags: $libidoContextTags,
            notes: $libidoNotes
        )
        default: JournalStepView(
            journalText: $journalText,
            promptAnswers: $promptAnswers
        )
        }
    }

    // MARK: Navigation buttons

    private var navigationButtons: some View {
        HStack(spacing: 10) {
            if currentStep > 0 {
                Button {
                    currentStep -= 1
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 52, height: 54)
                        .background(Color(hex: "#2B1B50"), in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(Color(hex: "#C4A0E8"))
                }
                .buttonStyle(.plain)
            }

            Button {
                if currentStep < totalSteps - 1 {
                    currentStep += 1
                } else {
                    saveEntry()
                }
            } label: {
                Text(currentStep == totalSteps - 1 ? "Save Entry" : "Continue")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color(hex: "#8B6CAF"), in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Saved confirmation

    private var savedConfirmation: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color(hex: "#55EFC4"))
            VStack(spacing: 8) {
                Text("Entry saved")
                    .font(.title2.weight(.semibold))
                Text("You checked in with yourself.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Done") { dismiss() }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color(hex: "#8B6CAF"), in: RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
        }
    }

    // MARK: Save

    private func saveEntry() {
        let entry = DiaryEntry(
            emotionalLevel: emotionalLevel,
            emotionTags: Array(selectedEmotions),
            bodySensations: bodySensations,
            journalText: journalText,
            promptAnswers: promptAnswers,
            sleepBedtime: sleepEnabled ? sleepBedtime : nil,
            sleepWakeTime: sleepEnabled ? sleepWakeTime : nil,
            sleepQuality: sleepEnabled ? sleepQuality : nil,
            sleepWakeups: sleepEnabled ? sleepWakeups : nil,
            sleepHadDreams: sleepEnabled ? (sleepDreams != .none) : nil,
            sleepNotes: (sleepEnabled && !sleepNotes.isEmpty) ? sleepNotes : nil,
            libidoLevel: libidoEnabled ? libidoLevel : nil,
            libidoContextTags: (libidoEnabled && !libidoContextTags.isEmpty) ? Array(libidoContextTags) : nil,
            libidoNotes: (libidoEnabled && !libidoNotes.isEmpty) ? libidoNotes : nil
        )
        modelContext.insert(entry)
        do {
            try modelContext.save()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation { isSaved = true }
        } catch {
            print("SAVE ERROR: \(error)")
            modelContext.delete(entry)
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            saveError = error.localizedDescription
        }
    }
}

// MARK: - Sleep dreams option

enum SleepDreams: String, CaseIterable {
    case none = "None"
    case pleasant = "Pleasant"
    case disturbing = "Disturbing"
}

// MARK: - Step 1: Intensity

private struct IntensityStepView: View {
    @Binding var level: Int

    private var fraction: Double { Double(level) / 10.0 }

    private var arcColor: Color {
        switch level {
        case 1...3: return Color(hex: "#55EFC4")
        case 4...6: return Color(hex: "#FDCB6E")
        case 7...8: return Color(hex: "#E8735A")
        default:    return Color(hex: "#C0392B")
        }
    }

    private var label: String {
        switch level {
        case 1...2: return "Barely there"
        case 3...4: return "Noticeable"
        case 5...6: return "Quite intense"
        case 7...8: return "Very intense"
        default:    return "Overwhelming"
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                ZStack {
                    Circle()
                        .trim(from: 0.0, to: 0.75)
                        .stroke(
                            Color.white.opacity(0.12),
                            style: StrokeStyle(lineWidth: 14, lineCap: .round)
                        )
                        .rotationEffect(.degrees(135))

                    Circle()
                        .trim(from: 0.0, to: fraction * 0.75)
                        .stroke(
                            arcColor,
                            style: StrokeStyle(lineWidth: 14, lineCap: .round)
                        )
                        .rotationEffect(.degrees(135))
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: level)

                    VStack(spacing: 2) {
                        Text("\(level)")
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .foregroundStyle(arcColor)
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.25), value: level)
                        Text(label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 180, height: 180)

                // 1–10 button grid
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5),
                    spacing: 8
                ) {
                    ForEach(1...10, id: \.self) { n in
                        intensityButton(n)
                    }
                }

                // Drag scrubber
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.12))
                            .frame(height: 16)
                        RoundedRectangle(cornerRadius: 8)
                            .fill(arcColor)
                            .frame(width: geo.size.width * CGFloat(level) / 10.0, height: 16)
                            .animation(.spring(response: 0.2), value: level)
                        Circle()
                            .fill(.white)
                            .frame(width: 28, height: 28)
                            .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                            .offset(x: (geo.size.width - 28) * CGFloat(level - 1) / 9.0)
                            .animation(.spring(response: 0.2), value: level)
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let fraction = max(0.0, min(1.0, value.location.x / geo.size.width))
                                let raw = Int((fraction * 9).rounded(.toNearestOrAwayFromZero)) + 1
                                let newLevel = max(1, min(10, raw))
                                if newLevel != level {
                                    level = newLevel
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                            }
                    )
                }
                .frame(height: 28)

                Spacer(minLength: 12)
            }
            .padding(.bottom, 8)
        }
    }

    private func intensityButton(_ n: Int) -> some View {
        let on = level == n
        return Button {
            level = n
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Text("\(n)")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(on ? .white : Color(hex: "#C4A0E8").opacity(0.8))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(on ? arcColor : Color(hex: "#2B1B50"))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(on ? arcColor.opacity(0.6) : .clear, lineWidth: 1.5)
                )
                .scaleEffect(on ? 1.04 : 1.0)
                .animation(.spring(response: 0.2), value: on)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Step 2: Emotions

private struct EmotionsStepView: View {
    @Binding var selectedEmotions: Set<Emotion>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select all that apply")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ScrollView(showsIndicators: false) {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 108, maximum: 150), spacing: 8)],
                    spacing: 8
                ) {
                    ForEach(Emotion.allCases) { emotion in
                        emotionChip(emotion)
                    }
                }
                .padding(.bottom, 8)
            }
        }
    }

    private func emotionChip(_ emotion: Emotion) -> some View {
        let on = selectedEmotions.contains(emotion)
        return Button {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            if on { selectedEmotions.remove(emotion) } else { selectedEmotions.insert(emotion) }
        } label: {
            HStack(spacing: 6) {
                Text(emotion.emoji).font(.system(size: 16))
                Text(emotion.displayName).font(.subheadline.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(on ? Color(hex: "#8B6CAF").opacity(0.40) : Color(hex: "#2B1B50"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(on ? Color(hex: "#C4A0E8").opacity(0.8) : .clear, lineWidth: 1.5)
            )
            .foregroundStyle(on ? Color(hex: "#C4A0E8") : .primary)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.2), value: on)
    }
}

// MARK: - Step 3: Body Map

private struct BodyMapStepView: View {
    @Binding var sensations: [BodySensation]

    var body: some View {
        VStack(spacing: 10) {
            Text("Optional — skip if you don't feel it in your body")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            BodyMapView(sensations: $sensations)
        }
    }
}

// MARK: - Step 4: Sleep

private struct SleepStepView: View {
    @Binding var enabled: Bool
    @Binding var bedtime: Date
    @Binding var wakeTime: Date
    @Binding var quality: Int
    @Binding var wakeups: Int
    @Binding var dreams: SleepDreams
    @Binding var notes: String

    private let accent = Color(hex: "#6C5CE7")

    private var durationFormatted: String {
        let diff = wakeTime.timeIntervalSince(bedtime)
        let adjusted = diff < 0 ? diff + 86400 : diff
        let hours = adjusted / 3600
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        return m > 0 ? "\(h)h \(m)m" : "\(h)h"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                yesSkipToggle

                if enabled {
                    bedWakeRow
                    durationCard
                    qualitySection
                    wakeupsSection
                    dreamsSection
                    notesSection
                }

                Spacer(minLength: 16)
            }
            .padding(.bottom, 8)
        }
    }

    private var yesSkipToggle: some View {
        HStack(spacing: 8) {
            yesSkipButton(label: "Yes, log sleep", isOn: enabled) { enabled = true }
            yesSkipButton(label: "Skip", isOn: !enabled) { enabled = false }
        }
    }

    private func yesSkipButton(label: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            action()
        } label: {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isOn ? .white : Color(hex: "#C4A0E8").opacity(0.8))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isOn ? accent : Color(hex: "#2B1B50"))
                )
        }
        .buttonStyle(.plain)
    }

    private var bedWakeRow: some View {
        HStack(spacing: 12) {
            timeCard(title: "Bedtime", binding: $bedtime)
            timeCard(title: "Wake time", binding: $wakeTime)
        }
    }

    private func timeCard(title: String, binding: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            DatePicker("", selection: binding, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .datePickerStyle(.compact)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "#231441"), in: RoundedRectangle(cornerRadius: 14))
    }

    private var durationCard: some View {
        HStack {
            Image(systemName: "clock.fill")
                .foregroundStyle(accent)
            Text("Duration")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Spacer()
            Text(durationFormatted)
                .font(.title3.weight(.semibold))
                .foregroundStyle(accent)
        }
        .padding(14)
        .background(Color(hex: "#231441"), in: RoundedRectangle(cornerRadius: 14))
    }

    private var qualitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Sleep quality")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Spacer()
                Text("\(quality)/10")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accent)
            }
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 5),
                spacing: 6
            ) {
                ForEach(1...10, id: \.self) { n in
                    qualityButton(n)
                }
            }
        }
    }

    private func qualityButton(_ n: Int) -> some View {
        let on = quality == n
        return Button {
            quality = n
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Text("\(n)")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(on ? .white : Color(hex: "#C4A0E8").opacity(0.8))
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(on ? accent : Color(hex: "#2B1B50"))
                )
                .scaleEffect(on ? 1.04 : 1.0)
                .animation(.spring(response: 0.2), value: on)
        }
        .buttonStyle(.plain)
    }

    private var wakeupsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Times woken up")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            HStack(spacing: 8) {
                ForEach(0...5, id: \.self) { n in
                    wakeupPill(n)
                }
            }
        }
    }

    private func wakeupPill(_ n: Int) -> some View {
        let displayValue = n == 5 ? (wakeups >= 5) : (wakeups == n)
        let label = n == 5 ? "5+" : "\(n)"
        return Button {
            wakeups = n
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(displayValue ? .white : Color(hex: "#C4A0E8").opacity(0.8))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(displayValue ? accent : Color(hex: "#2B1B50"))
                )
        }
        .buttonStyle(.plain)
    }

    private var dreamsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Dreams")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            HStack(spacing: 8) {
                ForEach(SleepDreams.allCases, id: \.rawValue) { option in
                    dreamButton(option)
                }
            }
        }
    }

    private func dreamButton(_ option: SleepDreams) -> some View {
        let on = dreams == option
        return Button {
            dreams = option
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        } label: {
            Text(option.rawValue)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(on ? .white : Color(hex: "#C4A0E8").opacity(0.8))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(on ? accent : Color(hex: "#2B1B50"))
                )
        }
        .buttonStyle(.plain)
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            TextField("Anything else about your sleep…", text: $notes, axis: .vertical)
                .lineLimit(1...4)
                .font(.callout)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color(hex: "#231441"), in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Step 5: Libido

private struct LibidoStepView: View {
    @Binding var enabled: Bool
    @Binding var level: Int
    @Binding var contextTags: Set<String>
    @Binding var notes: String

    private let accent = Color(hex: "#E17055")

    private let availableTags = ["Spontaneous", "Responsive", "Low", "Distracted", "Connected"]

    private var levelLabel: String {
        switch level {
        case 1...2: return "Very low"
        case 3...4: return "Low"
        case 5...6: return "Moderate"
        case 7...8: return "High"
        default:    return "Very high"
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                yesSkipToggle

                if enabled {
                    levelSection
                    tagsSection
                    notesSection
                }

                Spacer(minLength: 16)
            }
            .padding(.bottom, 8)
        }
    }

    private var yesSkipToggle: some View {
        HStack(spacing: 8) {
            yesSkipButton(label: "Yes, track desire", isOn: enabled) { enabled = true }
            yesSkipButton(label: "Skip", isOn: !enabled) { enabled = false }
        }
    }

    private func yesSkipButton(label: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            action()
        } label: {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isOn ? .white : Color(hex: "#C4A0E8").opacity(0.8))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isOn ? accent : Color(hex: "#2B1B50"))
                )
        }
        .buttonStyle(.plain)
    }

    private var levelSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Desire level")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Spacer()
                Text("\(level)/10 · \(levelLabel)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accent)
            }
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 5),
                spacing: 6
            ) {
                ForEach(1...10, id: \.self) { n in
                    levelButton(n)
                }
            }
        }
    }

    private func levelButton(_ n: Int) -> some View {
        let on = level == n
        return Button {
            level = n
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Text("\(n)")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(on ? .white : Color(hex: "#C4A0E8").opacity(0.8))
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(on ? accent : Color(hex: "#2B1B50"))
                )
                .scaleEffect(on ? 1.04 : 1.0)
                .animation(.spring(response: 0.2), value: on)
        }
        .buttonStyle(.plain)
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Context")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 100, maximum: 160), spacing: 8)],
                spacing: 8
            ) {
                ForEach(availableTags, id: \.self) { tag in
                    contextChip(tag)
                }
            }
        }
    }

    private func contextChip(_ tag: String) -> some View {
        let on = contextTags.contains(tag)
        return Button {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            if on { contextTags.remove(tag) } else { contextTags.insert(tag) }
        } label: {
            Text(tag)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(on ? .white : Color(hex: "#C4A0E8").opacity(0.8))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(on ? accent.opacity(0.85) : Color(hex: "#2B1B50"))
                )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.2), value: on)
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            TextField("Any thoughts…", text: $notes, axis: .vertical)
                .lineLimit(1...4)
                .font(.callout)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color(hex: "#231441"), in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Step 6: Journal

private struct JournalStepView: View {
    @Binding var journalText: String
    @Binding var promptAnswers: [String: String]

    @FocusState private var editorFocused: Bool

    private let placeholders = [
        "What's on your mind?",
        "Where are you right now?",
        "What does your body want you to know?",
        "How did your day unfold?",
    ]
    @State private var placeholderIdx = 0

    private let prompts: [(key: String, question: String)] = [
        ("trigger",   "What triggered this feeling?"),
        ("need",      "What do you think you need right now?"),
        ("gratitude", "One small thing you noticed today"),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                ZStack(alignment: .topLeading) {
                    if journalText.isEmpty {
                        Text(placeholders[placeholderIdx])
                            .font(.body)
                            .foregroundStyle(Color(hex: "#6D5F80"))
                            .padding(.top, 8)
                            .padding(.leading, 5)
                    }
                    TextEditor(text: $journalText)
                        .font(.body)
                        .frame(minHeight: 140)
                        .focused($editorFocused)
                        .scrollContentBackground(.hidden)
                }
                .padding(16)
                .background(Color(hex: "#231441"), in: RoundedRectangle(cornerRadius: 16))
                .onAppear { placeholderIdx = Int.random(in: 0..<placeholders.count) }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Optional reflections")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    ForEach(prompts, id: \.key) { prompt in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(prompt.question)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                            TextField("", text: Binding(
                                get: { promptAnswers[prompt.key] ?? "" },
                                set: { v in
                                    if v.isEmpty { promptAnswers.removeValue(forKey: prompt.key) }
                                    else { promptAnswers[prompt.key] = v }
                                }
                            ), axis: .vertical)
                            .lineLimit(1...3)
                            .font(.callout)
                            .textFieldStyle(.plain)
                            .padding(10)
                            .background(Color(hex: "#2B1B50"), in: RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
            }
            .padding(.bottom, 8)
        }
    }
}
