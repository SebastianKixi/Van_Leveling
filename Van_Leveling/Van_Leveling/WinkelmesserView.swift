import SwiftUI

/// Winkelmesser – Hauptansicht im Querformat. Zeigt die Neigung des iPhones
/// als drehende Skalen-Scheibe plus Pitch/Roll-Werte und Halten-Funktion.
struct WinkelmesserView: View {
    let viewModel: LevelViewModel
    @Binding var showSettings: Bool

    @Environment(\.verticalSizeClass) private var vSize

    @State private var isHeld: Bool = false
    @State private var heldPitch: Double = 0
    @State private var heldRoll: Double = 0

    @State private var tarePitch: Double = 0
    @State private var tareRoll: Double = 0

    private var displayPitch: Double {
        isHeld ? heldPitch : viewModel.motion.pitch - tarePitch
    }

    private var displayRoll: Double {
        isHeld ? heldRoll : viewModel.motion.roll - tareRoll
    }

    private var isLevel: Bool {
        abs(displayPitch) <= 1.0 && abs(displayRoll) <= 1.0
    }

    private var tareActive: Bool {
        tarePitch != 0 || tareRoll != 0
    }

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
            .navigationTitle("Winkelmesser")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gear")
                    }
                }
            }
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: isHeld)
        .lockOrientation(.landscape)
    }

    // MARK: - Landscape (Hauptansicht)

    private var landscapeLayout: some View {
        HStack(spacing: 16) {
            // Linke Spalte: Skalen-Scheibe
            ProtractorDial(
                rollDeg: displayRoll,
                pitchDeg: displayPitch,
                isLevel: isLevel
            )
            .padding(.vertical, 8)
            .padding(.leading, 8)

            // Rechte Spalte: Status, Werte, Buttons
            VStack(spacing: 10) {
                // Status
                HStack(spacing: 6) {
                    Image(systemName: isHeld ? "lock.fill" : "dot.radiowaves.left.and.right")
                        .foregroundStyle(isHeld ? .orange : .green)
                    Text(isHeld ? "Gehalten" : "Live")
                        .font(.caption.bold())
                        .foregroundStyle(isHeld ? .orange : .green)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.regularMaterial, in: Capsule())

                // Pitch
                AngleChip(
                    icon: "arrow.up.and.down",
                    label: "Pitch",
                    sublabel: "Vorne / Hinten",
                    value: displayPitch,
                    accent: .blue
                )

                // Roll
                AngleChip(
                    icon: "arrow.left.and.right",
                    label: "Roll",
                    sublabel: "Links / Rechts",
                    value: displayRoll,
                    accent: .orange
                )

                // Buttons
                HStack(spacing: 8) {
                    Button {
                        if isHeld {
                            isHeld = false
                        } else {
                            heldPitch = viewModel.motion.pitch - tarePitch
                            heldRoll  = viewModel.motion.roll  - tareRoll
                            isHeld = true
                        }
                    } label: {
                        Label(isHeld ? "Lösen" : "Halten",
                              systemImage: isHeld ? "lock.open.fill" : "lock.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(isHeld ? .orange : .accentColor)

                    Button {
                        if tareActive {
                            tarePitch = 0
                            tareRoll = 0
                        } else {
                            tarePitch = viewModel.motion.pitch
                            tareRoll = viewModel.motion.roll
                        }
                    } label: {
                        Label(
                            tareActive ? "Reset" : "Nullen",
                            systemImage: tareActive
                                ? "arrow.counterclockwise"
                                : "scope"
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isHeld)
                }
            }
            .padding(.trailing, 12)
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Portrait (Hinweis)

    private var portraitHint: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "rotate.right")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("iPhone quer drehen")
                .font(.title2.bold())

            Text("Der Winkelmesser arbeitet im Querformat\nfür die genaueste Anzeige.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Image(systemName: "iphone.gen3.landscape")
                .font(.system(size: 80))
                .foregroundStyle(.tint)
                .padding(.top, 8)

            Spacer()
        }
    }
}

// MARK: - Protractor Dial (Hero-Element)

private struct ProtractorDial: View {
    let rollDeg: Double
    let pitchDeg: Double
    let isLevel: Bool

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let radius = size / 2
            ZStack {
                // Hintergrund-Scheibe
                Circle()
                    .fill(LinearGradient(
                        colors: [
                            Color(.systemGray6),
                            Color(.systemGray5)
                        ],
                        startPoint: .top, endPoint: .bottom))
                Circle()
                    .stroke(Color.secondary.opacity(0.25), lineWidth: 1.5)

                // Skala
                ScaleMarks(radius: radius)

                // Horizont-Linie (rotiert mit Roll)
                HorizonGroup(
                    pitchDeg: pitchDeg,
                    radius: radius,
                    isLevel: isLevel
                )
                .rotationEffect(.degrees(-rollDeg))
                .animation(.interpolatingSpring(stiffness: 120, damping: 16), value: rollDeg)
                .animation(.interpolatingSpring(stiffness: 120, damping: 16), value: pitchDeg)
                .clipShape(Circle())

                // Mittiger Wert
                VStack(spacing: 2) {
                    Text(String(format: "%+.1f°", abs(rollDeg) >= abs(pitchDeg) ? rollDeg : pitchDeg))
                        .font(.system(size: 32, weight: .heavy, design: .monospaced))
                        .foregroundStyle(isLevel ? .green : .primary)
                        .contentTransition(.numericText())
                    Text(abs(rollDeg) >= abs(pitchDeg) ? "Roll" : "Pitch")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(.thinMaterial, in: Capsule())

                // Fixer iPhone-Marker oben
                VStack {
                    Image(systemName: "iphone.gen3")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(Color.accentColor, in: Circle())
                        .shadow(radius: 2)
                    Spacer()
                }
                .padding(.top, 4)
            }
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Skala

private struct ScaleMarks: View {
    let radius: CGFloat

    var body: some View {
        ZStack {
            ForEach(0..<72) { i in
                let deg = Double(i) * 5
                let isMajor = i % 6 == 0
                let isMid = i % 2 == 0
                let length: CGFloat = isMajor ? 12 : (isMid ? 8 : 4)
                let width: CGFloat = isMajor ? 2 : 1
                let opacity = isMajor ? 0.85 : (isMid ? 0.55 : 0.3)

                Rectangle()
                    .fill(Color.primary.opacity(opacity))
                    .frame(width: width, height: length)
                    .offset(y: -radius + length / 2 + 4)
                    .rotationEffect(.degrees(deg))
            }

            ForEach([0, 30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330], id: \.self) { deg in
                Text(label(for: deg))
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .offset(y: -radius + 26)
                    .rotationEffect(.degrees(Double(deg)))
            }
        }
    }

    private func label(for deg: Int) -> String {
        let d = deg <= 180 ? deg : deg - 360
        return "\(abs(d))"
    }
}

// MARK: - Horizont

private struct HorizonGroup: View {
    let pitchDeg: Double
    let radius: CGFloat
    let isLevel: Bool

    private var pitchOffset: CGFloat {
        let clamped = max(-30.0, min(30.0, pitchDeg))
        return CGFloat(clamped) * (radius / 60)
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(LinearGradient(
                    colors: [Color(red: 0.42, green: 0.65, blue: 0.95),
                             Color(red: 0.62, green: 0.78, blue: 0.98)],
                    startPoint: .top, endPoint: .bottom))
                .frame(width: radius * 3, height: radius * 3)
                .offset(y: -radius * 1.5 + pitchOffset)

            Rectangle()
                .fill(LinearGradient(
                    colors: [Color(red: 0.55, green: 0.42, blue: 0.30),
                             Color(red: 0.40, green: 0.30, blue: 0.22)],
                    startPoint: .top, endPoint: .bottom))
                .frame(width: radius * 3, height: radius * 3)
                .offset(y: radius * 1.5 + pitchOffset)

            Rectangle()
                .fill(isLevel ? Color.green : Color.white.opacity(0.95))
                .frame(width: radius * 2.4, height: 2.5)
                .offset(y: pitchOffset)
                .shadow(color: isLevel ? Color.green.opacity(0.7) : .clear, radius: 6)

            ForEach([-20, -10, 10, 20], id: \.self) { mark in
                let y = pitchOffset - CGFloat(mark) * (radius / 60)
                Rectangle()
                    .fill(Color.white.opacity(0.7))
                    .frame(width: 24, height: 1.5)
                    .offset(y: y)
                Text("\(abs(mark))")
                    .font(.system(size: 8, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.85))
                    .offset(x: 22, y: y)
            }
        }
    }
}

// MARK: - Werte-Chip

private struct AngleChip: View {
    let icon: String
    let label: String
    let sublabel: String
    let value: Double
    let accent: Color

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.15))
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(accent)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption.bold())
                Text(sublabel)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Text(String(format: "%+.1f°", value))
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    WinkelmesserView(
        viewModel: LevelViewModel(),
        showSettings: .constant(false)
    )
}
