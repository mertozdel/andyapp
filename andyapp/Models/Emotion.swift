import Foundation

// MARK: - DBT Module

enum DBTModule: String, Codable {
    case mindfulness
    case distressTolerance
    case emotionRegulation
    case interpersonalEffectiveness

    var displayName: String {
        switch self {
        case .mindfulness:                return "Mindfulness"
        case .distressTolerance:          return "Distress Tolerance"
        case .emotionRegulation:          return "Emotion Regulation"
        case .interpersonalEffectiveness: return "Interpersonal Effectiveness"
        }
    }
}

// MARK: - Emotion

enum Emotion: String, Codable, CaseIterable, Identifiable {
    // Positive
    case joy, calm, gratitude, love, excitement, contentment, hope, pride
    // Negative / activating
    case anxiety, fear, anger, frustration, shame, guilt, disgust, overwhelm
    // Low-energy
    case sadness, loneliness, numbness, emptiness, confusion, grief
    // Mixed / somatic
    case tension, restlessness, vulnerability

    var id: String { rawValue }

    var displayName: String { rawValue.capitalized }

    var emoji: String {
        switch self {
        case .joy:           return "😊"
        case .calm:          return "😌"
        case .gratitude:     return "🙏"
        case .love:          return "❤️"
        case .excitement:    return "✨"
        case .contentment:   return "🌿"
        case .hope:          return "🌤️"
        case .pride:         return "💪"
        case .anxiety:       return "😰"
        case .fear:          return "😨"
        case .anger:         return "😠"
        case .frustration:   return "😤"
        case .shame:         return "😔"
        case .guilt:         return "😞"
        case .disgust:       return "🤢"
        case .overwhelm:     return "🌊"
        case .sadness:       return "😢"
        case .loneliness:    return "🫂"
        case .numbness:      return "🌫️"
        case .emptiness:     return "🕳️"
        case .confusion:     return "😵"
        case .grief:         return "💔"
        case .tension:       return "⚡"
        case .restlessness:  return "🌀"
        case .vulnerability: return "🫀"
        }
    }

    var primaryDBTModule: DBTModule {
        switch self {
        case .anxiety, .fear, .overwhelm, .tension, .restlessness:
            return .distressTolerance
        case .anger, .frustration, .disgust:
            return .distressTolerance
        case .sadness, .loneliness, .grief, .emptiness:
            return .emotionRegulation
        case .shame, .guilt, .vulnerability:
            return .emotionRegulation
        case .numbness, .confusion:
            return .mindfulness
        default:
            return .mindfulness
        }
    }
}
