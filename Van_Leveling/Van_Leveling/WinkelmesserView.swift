import SwiftUI

/// Winkelmesser – Hauptansicht im Querformat. Zeigt die Neigung des iPhones
/// als drehende Skalen-Scheibe plus Pitch/Roll-Werte und Halten-Funktion.
///
/// Achs-Mapping (Querformat): aus Anwendersicht entspricht die seitliche
/// Neigung der Geräte-Pitch und die Vorne/Hinten-Neigung der Geräte-Roll.
struct WinkelmesserView: View {
    let viewModel: LevelViewModel
    @Binding var showSettings: Bool

    @State private var isHeld: Bool = false
    @State private var heldFwdBack: Double = 0
    @State private var heldLeftRight: Double = 0

    @State private var tareFwdBack: Double = 0
    @State private var tareLeftRight: Double = 0

    /// Vorne/Hinten-Neigung aus dem Gravitations-Vektor.
    /// Im Querformat aufrecht: gz = 0. Kippt das iPhone die Front weg
    /// vom Anwender, gz wird positiv.
    private var rawFwdBack: Double {
        let g = max(-1.0, min(1.0, viewModel.motion.gravityZ))
        return asin(g) * 180.0 / .pi
    }

    /// Links/Rechts-Neigung aus dem Gravitations-Vektor.
    /// Im Querformat aufrecht: gy = 0. Kippt das iPhone seitlich,
    /// wandert gy entsprechend.
    private var rawLeftRight: Double {
        let g = max(-1.0, min(1.0, viewModel.motion.gravityY))
        return asin(g) * 180.0 / .pi
    }

    private var fwdBackTilt: Double {
        isHeld ? heldFwdBack : rawFwdBack - tareFwdBack
    }

    private var leftRightTilt: Double {
        isHeld ? heldLeftRight : rawLeftRight - tareLeftRight
    }

    private var isLevel: Bool {
        abs(fwdBackTilt) <= 1.0 && abs(leftRightTilt) <= 1.0
    }

    private var tareActive: Bool {
        tareFwdBack != 0 || tareLeftRight != 0
    }

    /// Erkennt ob das iPhone physisch hochkant im Querformat (auf der langen
    /// Kante) liegt. Wenn flach hingelegt, ergibt die Anzeige keinen Sinn.
    private var phoneOnLongEdge: Bool {
        abs(viewModel.motion.gravityX) > 0.6
    }

    var body: some View {
        NavigationStack {
            Group {
                if phoneOnLongEdge {
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
    }

    // MARK: - Landscape (Hauptansicht)

    private var landscapeLayout: some View {
        GeometryReader { geo in
            let dialSize = min(geo.size.width * 0.42, geo.size.height - 16)

            HStack(alignment: .center, spacing: 18) {
                // Linke Spalte: Skalen-Scheibe
                ProtractorDial(
                    fwdBackTilt: fwdBackTilt,
                    leftRightTilt: leftRightTilt,
                    isLevel: isLevel
                )
                .frame(width: dialSize, height: dialSize)

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
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Vorne/Hinten (Nicken)
                    AngleChip(
                        illustration: AnyView(TiltIllustration(axis: .forwardBack)),
                        label: "Vorne / Hinten",
                        sublabel: "wie Nicken",
                        value: fwdBackTilt,
                        accent: .accentColor
                    )

                    // Links/Rechts (Rollen)
                    AngleChip(
                        illustration: AnyView(TiltIllustration(axis: .leftRight)),
                        label: "Links / Rechts",
                        sublabel: "wie Schaukeln",
                        value: leftRightTilt,
                        accent: .orange
                    )

                    // Buttons
                    HStack(spacing: 8) {
                        Button {
                            if isHeld {
                                isHeld = false
                            } else {
                                heldFwdBack   = rawFwdBack   - tareFwdBack
                                heldLeftRight = rawLeftRight - tareLeftRight
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
                                tareFwdBack = 0
                                tareLeftRight = 0
                            } else {
                                tareFwdBack = rawFwdBack
                                tareLeftRight = rawLeftRight
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
                .frame(maxWidth: .infinity)
                .padding(.trailing, 4)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(width: geo.size.width, height: geo.size.height)
        }
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

            Text("Halte das iPhone auf der langen Kante\nan die Fläche, deren Neigung du messen möchtest.")
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

// MARK: - Protractor Dial

private struct ProtractorDial: View {
    let fwdBackTilt: Double      // entspricht Geräte-Roll im Querformat
    let leftRightTilt: Double    // entspricht Geräte-Pitch im Querformat
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

                // Horizont (rotiert mit links/rechts-Neigung,
                // verschiebt sich mit vorne/hinten-Neigung)
                HorizonGroup(
                    fwdBackTilt: fwdBackTilt,
                    radius: radius,
                    isLevel: isLevel
                )
                .rotationEffect(.degrees(-leftRightTilt))
                .animation(.interpolatingSpring(stiffness: 120, damping: 16), value: leftRightTilt)
                .animation(.interpolatingSpring(stiffness: 120, damping: 16), value: fwdBackTilt)
                .clipShape(Circle())

                // Mittiger Wert (zeigt die größere Abweichung)
                let dominant = abs(leftRightTilt) >= abs(fwdBackTilt) ? leftRightTilt : fwdBackTilt
                let dominantLabel = abs(leftRightTilt) >= abs(fwdBackTilt) ? "L / R" : "V / H"

                VStack(spacing: 2) {
                    Text(String(format: "%+.1f°", dominant))
                        .font(.system(size: min(radius * 0.32, 32), weight: .heavy, design: .monospaced))
                        .foregroundStyle(isLevel ? .green : .primary)
                        .contentTransition(.numericText())
                    Text(dominantLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(.thinMaterial, in: Capsule())

                // Fixer iPhone-Marker oben
                VStack {
                    Image(systemName: "iphone.gen3")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(5)
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

// MARK: - Horizont (zwei dezent-graue Halften, app-konform)

private struct HorizonGroup: View {
    let fwdBackTilt: Double
    let radius: CGFloat
    let isLevel: Bool

    private var pitchOffset: CGFloat {
        let clamped = max(-30.0, min(30.0, fwdBackTilt))
        return CGFloat(clamped) * (radius / 60)
    }

    var body: some View {
        ZStack {
            // Obere Hälfte (Himmel): heller Akzent-Ton
            Rectangle()
                .fill(LinearGradient(
                    colors: [
                        Color.accentColor.opacity(0.18),
                        Color.accentColor.opacity(0.08)
                    ],
                    startPoint: .top, endPoint: .bottom))
                .frame(width: radius * 3, height: radius * 3)
                .offset(y: -radius * 1.5 + pitchOffset)

            // Untere Hälfte (Boden): neutrale Grau-Töne
            Rectangle()
                .fill(LinearGradient(
                    colors: [
                        Color(.systemGray3),
                        Color(.systemGray2)
                    ],
                    startPoint: .top, endPoint: .bottom))
                .frame(width: radius * 3, height: radius * 3)
                .offset(y: radius * 1.5 + pitchOffset)

            // Horizont-Linie
            Rectangle()
                .fill(isLevel ? Color.green : Color.primary)
                .frame(width: radius * 2.4, height: 2.5)
                .offset(y: pitchOffset)
                .shadow(color: isLevel ? Color.green.opacity(0.7) : .clear, radius: 6)

            // Pitch-Skala-Striche
            ForEach([-20, -10, 10, 20], id: \.self) { mark in
                let y = pitchOffset - CGFloat(mark) * (radius / 60)
                Rectangle()
                    .fill(Color.primary.opacity(0.5))
                    .frame(width: 24, height: 1.5)
                    .offset(y: y)
                Text("\(abs(mark))")
                    .font(.system(size: 8, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .offset(x: 22, y: y)
            }
        }
    }
}

// MARK: - Werte-Chip

private struct AngleChip: View {
    let illustration: AnyView
    let label: String
    let sublabel: String
    let value: Double
    let accent: Color

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.15))
                    .frame(width: 38, height: 38)
                illustration
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption.bold())
                    .lineLimit(1)
                Text(sublabel)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
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

// MARK: - Tilt-Illustration für die Chips

private struct TiltIllustration: View {
    enum Axis { case forwardBack, leftRight }
    let axis: Axis

    var body: some View {
        ZStack {
            // Referenz-Bodenlinie
            Rectangle()
                .fill(Color.secondary.opacity(0.45))
                .frame(width: 22, height: 1)
                .offset(y: 8)

            switch axis {
            case .forwardBack:
                // Seitenansicht: schmales Rechteck (iPhone von der Kante) leicht nach vorne gekippt
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(.primary)
                    .frame(width: 5, height: 18)
                    .rotationEffect(.degrees(-22))
                    .offset(y: -1)

                // Geschwungener Pfeil zeigt die Bewegung an
                Image(systemName: "arrow.uturn.right")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.tint)
                    .rotationEffect(.degrees(-90))
                    .offset(x: 9, y: -3)

            case .leftRight:
                // Frontansicht: breites Rechteck (iPhone landscape) seitlich gekippt
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(.primary)
                    .frame(width: 22, height: 6)
                    .rotationEffect(.degrees(-18))
                    .offset(y: -1)

                Image(systemName: "arrow.left.and.right")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(.tint)
                    .offset(y: 11)
            }
        }
        .frame(width: 32, height: 28)
    }
}

#Preview {
    WinkelmesserView(
        viewModel: LevelViewModel(),
        showSettings: .constant(false)
    )
}
