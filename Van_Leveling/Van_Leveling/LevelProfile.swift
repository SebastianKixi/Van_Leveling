import Foundation

struct LevelProfile: Identifiable, Hashable {
    let id: String
    let name: String
    let icon: String          // SF Symbol name
    let tolerance: Double     // degrees
    let isProOnly: Bool
    let rollPositive: String  // instruction when adjustedRoll > 0
    let rollNegative: String  // instruction when adjustedRoll < 0
    let pitchPositive: String // instruction when adjustedPitch > 0
    let pitchNegative: String // instruction when adjustedPitch < 0
    let showPitch: Bool       // false for shelf/picture (single-axis)

    // MARK: - Predefined Profiles

    static let general = LevelProfile(
        id: "general",
        name: "Allgemein",
        icon: "scope",
        tolerance: 0.5,
        isProOnly: false,
        rollPositive: "Rechte Seite heben",
        rollNegative: "Linke Seite heben",
        pitchPositive: "Hinten heben",
        pitchNegative: "Vorne heben",
        showPitch: true
    )

    static let caravan = LevelProfile(
        id: "caravan",
        name: "Wohnwagen",
        icon: "car.side.fill",
        tolerance: 1.0,
        isProOnly: false,
        rollPositive: "Rechte Seite heben",
        rollNegative: "Linke Seite heben",
        pitchPositive: "Hinten heben",
        pitchNegative: "Vorne heben",
        showPitch: true
    )

    static let camera = LevelProfile(
        id: "camera",
        name: "Kamera",
        icon: "camera.fill",
        tolerance: 0.3,
        isProOnly: true,
        rollPositive: "Nach rechts drehen",
        rollNegative: "Nach links drehen",
        pitchPositive: "Nach oben neigen",
        pitchNegative: "Nach unten neigen",
        showPitch: true
    )

    static let appliance = LevelProfile(
        id: "appliance",
        name: "Gerät",
        icon: "washer.fill",
        tolerance: 2.0,
        isProOnly: false,
        rollPositive: "Rechten Fuß verstellen",
        rollNegative: "Linken Fuß verstellen",
        pitchPositive: "Hinteren Fuß verstellen",
        pitchNegative: "Vorderen Fuß verstellen",
        showPitch: true
    )

    static let shelf = LevelProfile(
        id: "shelf",
        name: "Regal",
        icon: "rectangle.portrait.righthalf.inset.filled",
        tolerance: 0.5,
        isProOnly: false,
        rollPositive: "Rechtes Ende absenken",
        rollNegative: "Linkes Ende absenken",
        pitchPositive: "",
        pitchNegative: "",
        showPitch: false
    )

    static let billiard = LevelProfile(
        id: "billiard",
        name: "Billard",
        icon: "smallcircle.filled.circle.fill",
        tolerance: 0.1,
        isProOnly: true,
        rollPositive: "Rechtes Bein verstellen",
        rollNegative: "Linkes Bein verstellen",
        pitchPositive: "Hinteres Bein verstellen",
        pitchNegative: "Vorderes Bein verstellen",
        showPitch: true
    )

    static let all: [LevelProfile] = [
        .general, .caravan, .camera, .appliance, .shelf, .billiard
    ]
}
