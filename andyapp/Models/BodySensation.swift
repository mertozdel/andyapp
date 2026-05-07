import Foundation
import SwiftUI

// MARK: - Body Side

enum BodySide: String, Codable, CaseIterable {
    case front, back
    var displayName: String { rawValue.capitalized }
}

// MARK: - Body Region

enum BodyRegion: String, Codable, CaseIterable {
    // Front regions
    case head, jaw, throat, shoulders, chest, heart
    case stomach, abdomen, hips, arms, hands, legs, feet
    // Back regions
    case upperBack, lowerBack, neckBack, shoulderBlades, glutes, calves

    var displayName: String {
        switch self {
        case .upperBack:       return "Upper Back"
        case .lowerBack:       return "Lower Back"
        case .neckBack:        return "Back of Neck"
        case .shoulderBlades:  return "Shoulder Blades"
        default:               return rawValue.capitalized
        }
    }

    var defaultSide: BodySide {
        switch self {
        case .upperBack, .lowerBack, .neckBack, .shoulderBlades, .glutes, .calves:
            return .back
        default:
            return .front
        }
    }
}

// MARK: - Sensation Type

enum SensationType: String, Codable, CaseIterable {
    // Tension / constriction
    case tightness, pressure, constriction, heaviness, knot
    // Activation
    case tingling, vibration, fluttering, racing, pulsing
    // Temperature
    case warmth, heat, coldness, chills
    // Relaxation
    case lightness, openness, softness, expansion
    // Pain / discomfort
    case pain, ache, nausea, dizziness, numbness

    var displayName: String { rawValue.capitalized }

    var emoji: String {
        switch self {
        case .tightness, .constriction: return "🔒"
        case .pressure:                 return "⬇️"
        case .heaviness:                return "🪨"
        case .knot:                     return "🪢"
        case .tingling:                 return "⚡"
        case .vibration, .pulsing:      return "〰️"
        case .fluttering:               return "🦋"
        case .racing:                   return "💨"
        case .warmth, .heat:            return "🔥"
        case .coldness, .chills:        return "❄️"
        case .lightness, .openness:     return "🕊️"
        case .softness, .expansion:     return "🌸"
        case .pain, .ache:              return "🩹"
        case .nausea:                   return "🌀"
        case .dizziness:                return "💫"
        case .numbness:                 return "🌫️"
        }
    }

    /// SwiftUI Color for the dot rendered on the body map
    var dotColor: Color {
        switch self {
        case .tightness, .pressure, .constriction:
            return Color(hex: "#E8735A")
        case .pain, .ache:
            return Color(hex: "#C0392B")
        case .warmth, .heat:
            return Color(hex: "#F4A261")
        case .coldness, .chills:
            return Color(hex: "#74B9FF")
        case .tingling, .vibration, .pulsing:
            return Color(hex: "#A29BFE")
        case .heaviness, .numbness:
            return Color(hex: "#636E72")
        case .lightness, .openness, .expansion, .softness:
            return Color(hex: "#55EFC4")
        case .fluttering, .racing:
            return Color(hex: "#FDCB6E")
        case .nausea, .dizziness:
            return Color(hex: "#00B894")
        case .knot:
            return Color(hex: "#E17055")
        }
    }
}

// MARK: - Body Sensation

struct BodySensation: Codable, Identifiable {
    var id: UUID = UUID()
    var side: BodySide
    /// Normalised position on the silhouette canvas (0.0–1.0)
    var normalizedX: Double
    var normalizedY: Double
    /// Closest named region — auto-derived from tap, editable by user
    var region: BodyRegion
    var sensationType: SensationType
    /// 1–5; drives dot border ring thickness on the body map
    var localIntensity: Int
    var note: String? = nil
}

// MARK: - Color+Hex helper

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
