import SwiftUI

/// Klassische Wasserwaage – iPhone wird auf der langen Kante (Querformat) auf
/// eine horizontale Fläche gelegt. Die Bläschen-Anzeige zeigt die Neigung dieser
/// Fläche entlang der langen Achse des iPhones.
struct WasserwaageView: View {
    let viewModel: LevelViewModel
    @Binding var showSettings: Bool

    @Environment(\.verticalSizeClass) private var vSize

    /// Tilt entlang der iPhone-Längsachse (Y-Achse des Geräts) in Grad.
    /// `gravityY = sin(tiltAngle)` wenn das iPhone hochkant auf der langen Kante steht.
    private var tilt: Double {
        asin(max(-1.0, min(1.0, viewModel.motion.gravityY))) * 180.0 / .pi
    }

    private let tolerance: Double = 0.5
    private var isLevel: Bool { abs(tilt) <= tolerance }

    var body: some View {
        NavigationStack {
            Group {
                if vSize == .compact {
                    landscapeLayout
                } else {
                    portraitHint
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .navigationTitle("Wasserwaage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gear")
                    }
                }
            }
        }
        .sensoryFeedback(.success, trigger: isLevel) { _, new in new }
    }

    // MARK: - Landscape (Hauptansicht)

    private var landscapeLayout: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 0)

            // Großer Grad-Wert
            Text(String(format: "%+.1f°", tilt))
                .font(.system(size: 64, weight: .heavy, design: .monospaced))
                .foregroundStyle(isLevel ? .green : .primary)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.1), value: tilt)

            // Bläschen-Tube
            BubbleVial(tilt: tilt, tolerance: tolerance, isLevel: isLevel)
                .frame(height: 60)
                .padding(.horizontal, 32)

            // Status-Text
            Text(isLevel ? "WAAGERECHT" : statusHint)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(isLevel ? .green : .secondary)
                .animation(.easeInOut, value: isLevel)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
    }

    private var statusHint: String {
        if tilt > 0 { return "Linke Seite anheben" }
        if tilt < 0 { return "Rechte Seite anheben" }
        return ""
    }

    // MARK: - Portrait (Hinweis zum Drehen)

    private var portraitHint: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "rotate.right")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("iPhone quer drehen")
                .font(.title2.bold())

            Text("Lege das iPhone auf die lange Kante\nauf die Fläche, die du prüfen möchtest.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Mini-Diagramm
            Image(systemName: "iphone.gen3.landscape")
                .font(.system(size: 80))
                .foregroundStyle(.tint)
                .padding(.top, 8)

            Spacer()
        }
    }
}

// MARK: - Bubble Vial

private struct BubbleVial: View {
    let tilt: Double
    let tolerance: Double
    let isLevel: Bool

    /// Maximaler Auslenkbereich der Anzeige in Grad
    private let maxDeg: Double = 8.0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let bubbleSize = h * 0.85
            let track = w - bubbleSize - 8

            // Bläschen wandert zur HOHEN Seite (entgegengesetzt zur Neigung)
            let normalized = max(-1.0, min(1.0, -tilt / maxDeg))
            let xOffset = CGFloat(normalized) * (track / 2)

            let tolFrac = CGFloat(tolerance / maxDeg)
            let tolWidth = bubbleSize * (1 + tolFrac * 6)

            ZStack {
                // Hintergrund (Glaskörper)
                Capsule()
                    .fill(Color.secondary.opacity(0.12))
                Capsule()
                    .stroke(Color.secondary.opacity(0.35), lineWidth: 1)

                // Toleranz-Zone
                Capsule()
                    .fill(Color.green.opacity(isLevel ? 0.25 : 0.10))
                    .frame(width: tolWidth, height: bubbleSize + 4)

                // Mittellinien
                Rectangle()
                    .fill(Color.secondary.opacity(0.5))
                    .frame(width: 1, height: h * 0.55)
                    .offset(x: -tolWidth / 2)
                Rectangle()
                    .fill(Color.secondary.opacity(0.5))
                    .frame(width: 1, height: h * 0.55)
                    .offset(x: tolWidth / 2)

                // Das Bläschen
                Circle()
                    .fill(isLevel ? Color.green : Color.yellow.opacity(0.95))
                    .frame(width: bubbleSize, height: bubbleSize)
                    .shadow(color: isLevel ? Color.green.opacity(0.6) : .clear, radius: 8)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                    )
                    .offset(x: xOffset)
                    .animation(.interpolatingSpring(stiffness: 220, damping: 22), value: xOffset)
            }
        }
    }
}

#Preview {
    WasserwaageView(
        viewModel: LevelViewModel(),
        showSettings: .constant(false)
    )
}
