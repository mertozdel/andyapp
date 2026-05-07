import Foundation
import SwiftData

@Model
final class DiaryEntry {

    // MARK: Identity & Timing
    var id: UUID
    var createdAt: Date
    /// User-editable title; defaults to formatted date when displayed if blank
    var title: String

    // MARK: Emotional Check-In
    /// Overall intensity 1–10
    var emotionalLevel: Int
    /// Raw values of `Emotion` enum; SwiftData stores [String] natively
    var emotionTags: [String]

    // MARK: Body Map
    /// JSON-encoded [BodySensation] — transformable via SwiftData @Attribute
    @Attribute var bodySensationsData: Data?

    // MARK: Journal / Thoughts
    /// Free-form answer to "How do I feel right now?" — the main diary content
    var journalText: String
    /// JSON-encoded [String: String] — optional guided prompt answers
    /// Keys: "trigger", "need", "gratitude", "future", etc.
    @Attribute var promptAnswersData: Data?

    // MARK: DBT AI Coach (strictly opt-in; nil until user requests)
    var dbtSuggestion: String?
    var dbtSuggestionRequestedAt: Date?
    /// Model identifier for auditability (e.g. "gpt-4o-2024-08-06")
    var dbtSuggestionModel: String?

    // MARK: Init

    init(
        emotionalLevel: Int,
        emotionTags: [Emotion] = [],
        bodySensations: [BodySensation] = [],
        journalText: String = "",
        promptAnswers: [String: String] = [:],
        title: String = ""
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.title = title
        self.emotionalLevel = emotionalLevel
        self.emotionTags = emotionTags.map(\.rawValue)
        self.journalText = journalText
        self.bodySensationsData = try? JSONEncoder().encode(bodySensations)
        self.promptAnswersData = promptAnswers.isEmpty ? nil : try? JSONEncoder().encode(promptAnswers)
    }

    // MARK: Computed helpers

    var emotions: [Emotion] {
        emotionTags.compactMap { Emotion(rawValue: $0) }
    }

    var bodySensations: [BodySensation] {
        get {
            guard let data = bodySensationsData else { return [] }
            return (try? JSONDecoder().decode([BodySensation].self, from: data)) ?? []
        }
        set {
            bodySensationsData = try? JSONEncoder().encode(newValue)
        }
    }

    var promptAnswers: [String: String] {
        get {
            guard let data = promptAnswersData else { return [:] }
            return (try? JSONDecoder().decode([String: String].self, from: data)) ?? [:]
        }
        set {
            promptAnswersData = newValue.isEmpty ? nil : try? JSONEncoder().encode(newValue)
        }
    }

    var hasDbtSuggestion: Bool { dbtSuggestion != nil }

    /// Emotional level ≥ 7 — surfaces a "High Intensity" badge in the timeline
    var isHighIntensity: Bool { emotionalLevel >= 7 }

    /// Formatted display title — falls back to locale-formatted date
    var displayTitle: String {
        title.isEmpty ? diaryEntryDateFormatter.string(from: createdAt) : title
    }

    // MARK: Helpers for AI message assembly

    /// Builds the user message block sent to the DBT AI coach API
    func buildAIUserMessage() -> String {
        var lines: [String] = []
        lines.append("Emotional intensity: \(emotionalLevel)/10")
        lines.append("Emotions tagged: \(emotions.map(\.displayName).joined(separator: ", "))")

        let sensations = bodySensations
        if sensations.isEmpty {
            lines.append("Body sensations: none logged")
        } else {
            lines.append("Body sensations:")
            for s in sensations {
                lines.append("- \(s.sensationType.displayName) in \(s.region.displayName), \(s.side.displayName) (intensity \(s.localIntensity)/5)")
                if let note = s.note, !note.isEmpty {
                    lines.append("  Note: \(note)")
                }
            }
        }

        lines.append("")
        lines.append("Journal entry:")
        lines.append("\"\(journalText)\"")

        let answers = promptAnswers
        if !answers.isEmpty {
            lines.append("")
            lines.append("Additional reflections:")
            let labelMap: [String: String] = [
                "trigger":   "What triggered this feeling",
                "need":      "What I think I need right now",
                "gratitude": "One small thing I noticed today",
                "future":    "What Wise Mind would say"
            ]
            for (key, value) in answers where !value.isEmpty {
                let label = labelMap[key] ?? key.capitalized
                lines.append("- \(label): \(value)")
            }
        }

        return lines.joined(separator: "\n")
    }

}

private let diaryEntryDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateStyle = .medium
    f.timeStyle = .short
    return f
}()
