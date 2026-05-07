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

    private let totalSteps = 4

    private var stepTitles: [String] {
        ["How intense is it?", "What are you feeling?", "Where do you feel it?", "Tell me more"]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#FAF7FD").ignoresSafeArea()

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
        }
    }

    // MARK: Progress dots

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { i in
                Capsule()
                    .fill(i <= currentStep ? Color(hex: "#8B6CAF") : Color(hex: "#D5C8E4"))
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
        default: JournalStepView(journalText: $journalText, promptAnswers: $promptAnswers)
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
                        .background(Color(hex: "#F0EAF5"), in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(Color(hex: "#8B6CAF"))
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
            promptAnswers: promptAnswers
        )
        modelContext.insert(entry)
        try? modelContext.save()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation { isSaved = true }
    }
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
        VStack(spacing: 44) {
            ZStack {
                Circle()
                    .trim(from: 0.0, to: 0.75)
                    .stroke(
                        Color(hex: "#F0EAF5"),
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
                        .font(.system(size: 68, weight: .bold, design: .rounded))
                        .foregroundStyle(arcColor)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.25), value: level)
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 210, height: 210)

            HStack(spacing: 7) {
                ForEach(1...10, id: \.self) { lv in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        level = lv
                    } label: {
                        Circle()
                            .fill(level >= lv ? arcColor : Color(hex: "#F0EAF5"))
                            .frame(width: 26, height: 26)
                            .overlay(
                                Text("\(lv)")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(level >= lv ? .white : Color(hex: "#C0B4D0"))
                            )
                            .scaleEffect(level == lv ? 1.22 : 1.0)
                            .animation(.spring(response: 0.2), value: level)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
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
                    .fill(on ? Color(hex: "#8B6CAF").opacity(0.12) : Color(hex: "#F7F3FA"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(on ? Color(hex: "#8B6CAF").opacity(0.6) : .clear, lineWidth: 1.5)
            )
            .foregroundStyle(on ? Color(hex: "#8B6CAF") : .primary)
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

// MARK: - Step 4: Journal

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
                // Free-form entry
                ZStack(alignment: .topLeading) {
                    if journalText.isEmpty {
                        Text(placeholders[placeholderIdx])
                            .font(.body)
                            .foregroundStyle(Color(hex: "#C0B4D0"))
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
                .background(Color(hex: "#F7F3FA"), in: RoundedRectangle(cornerRadius: 16))
                .onAppear { placeholderIdx = Int.random(in: 0..<placeholders.count) }

                // Optional depth prompts
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
                            .background(Color(hex: "#F0EAF5"), in: RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
            }
            .padding(.bottom, 8)
        }
    }
}
