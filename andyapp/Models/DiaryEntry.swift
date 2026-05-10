import Foundation
import SwiftData

@Model
final class DiaryEntry {

    // MARK: Identity & Timing
    var id: UUID
    var createdAt: Date
    var title: String

    // MARK: Emotional Check-In
    var emotionalLevel: Int
    var emotionTags: [String]

    // MARK: Body Map
    @Attribute var bodySensationsData: Data?

    // MARK: Journal / Thoughts
    var journalText: String
    @Attribute var promptAnswersData: Data?

    // MARK: Sleep Tracking
    var sleepBedtime: Date?
    var sleepWakeTime: Date?
    var sleepQuality: Int
    var sleepWakeups: Int
    var sleepHadDreams: Bool
    var sleepNotes: String?

    // MARK: Libido / Desire Tracking
    var libidoLevel: Int?
    var libidoNotes: String?

    // MARK: DBT AI Coach (strictly opt-in; nil until user requests)
    var dbtSuggestion: String?
    var dbtSuggestionRequestedAt: Date?
    var dbtSuggestionModel: String?

    // MARK: Init

    init(
        emotionalLevel: Int,
        emotionTags: [Emotion] = [],
        bodySensations: [BodySensation] = [],
        journalText: String = "",
        promptAnswers: [String: String] = [:],
        title: String = "",
        sleepBedtime: Date? = nil,
        sleepWakeTime: Date? = nil,
        sleepQuality: Int = 5,
        sleepWakeups: Int = 0,
        sleepHadDreams: Bool = false,
        sleepNotes: String? = nil,
        libidoLevel: Int? = nil,
        libidoNotes: String? = nil
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.title = title
        self.emotionalLevel = emotionalLevel
        self.emotionTags = emotionTags.map(\.rawValue)
        self.journalText = journalText
        self.bodySensationsData = try? JSONEncoder().encode(bodySensations)
        self.promptAnswersData = promptAnswers.isEmpty ? nil : try? JSONEncoder().encode(promptAnswers)
        self.sleepBedtime = sleepBedtime
        self.sleepWakeTime = sleepWakeTime
        self.sleepQuality = sleepQuality
        self.sleepWakeups = sleepWakeups
        self.sleepHadDreams = sleepHadDreams
        self.sleepNotes = sleepNotes
        self.libidoLevel = libidoLevel
        self.libidoNotes = libidoNotes
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
    var isHighIntensity: Bool { emotionalLevel >= 7 }

    var displayTitle: String {
        title.isEmpty ? diaryEntryDateFormatter.string(from: createdAt) : title
    }

    var hasSleepData: Bool { sleepBedtime != nil && sleepWakeTime != nil }

    var sleepDurationHours: Double? {
        guard let bed = sleepBedtime, let wake = sleepWakeTime else { return nil }
        let diff = wake.timeIntervalSince(bed)
        let adjusted = diff < 0 ? diff + 86400 : diff
        return adjusted / 3600
    }

    var sleepDurationFormatted: String? {
        guard let hours = sleepDurationHours else { return nil }
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        return m > 0 ? "\(h)h \(m)m" : "\(h)h"
    }

    var hasLibidoData: Bool { libidoLevel != nil }

    // MARK: AI message assembly

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

        if hasSleepData, let duration = sleepDurationFormatted {
            lines.append("")
            lines.append("Sleep: \(duration) · quality \(sleepQuality)/10 · wakeups \(sleepWakeups)")
            if sleepHadDreams { lines.append("Had dreams: yes") }
            if let notes = sleepNotes, !notes.isEmpty { lines.append("Sleep notes: \(notes)") }
        }

        if let lvl = libidoLevel {
            lines.append("")
            lines.append("Desire/libido level: \(lvl)/10")
            if let notes = libidoNotes, !notes.isEmpty { lines.append("Libido notes: \(notes)") }
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
                lines.append("- \(labelMap[key] ?? key.capitalized): \(value)")
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
