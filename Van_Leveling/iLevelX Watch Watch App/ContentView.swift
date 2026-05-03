import SwiftUI
import WatchKit

struct WatchLevelView: View {
    @State private var rx       = WatchConnectivityReceiver()
    @State private var compass  = WatchHeadingManager()
    @State private var runtime  = WatchRuntimeSession()

    // MARK: - Heading delta (Watch minus iPhone, normalised to -180…180)
    var delta: Double {
        guard rx.iPhoneHeading >= 0, compass.heading >= 0 else { return 0 }
        var d = compass.heading - rx.iPhoneHeading
        while d >  180 { d -= 360 }
        while d < -180 { d += 360 }
        return d
    }

    var compassActive: Bool { rx.iPhoneHeading >= 0 && compass.heading >= 0 }

    // MARK: - Rotate phone tilt into user's reference frame
    var userRoll: Double {
        let r = delta * .pi / 180
        return rx.roll * cos(r) + rx.pitch * sin(r)
    }

    var userPitch: Double {
        let r = delta * .pi / 180
        return -rx.roll * sin(r) + rx.pitch * cos(r)
    }

    var userIsRollLevel:  Bool { abs(userRoll)  <= rx.tolerance }
    var userIsPitchLevel: Bool { abs(userPitch) <= rx.tolerance }
    var userIsLevel:      Bool { userIsRollLevel && userIsPitchLevel }

    // MARK: - Arrow + instruction in user's rotated frame
    // Returns (sfSymbol, primaryText, secondaryText?)
    var primary: (arrow: String, text: String, subtext: String?)? {
        let rOver = abs(userRoll)  > rx.tolerance
        let pOver = abs(userPitch) > rx.tolerance && rx.showPitch
        guard rOver || pOver else { return nil }

        let rollText  = userRoll  > 0 ? rx.rollPositive  : rx.rollNegative
        let pitchText = userPitch > 0 ? rx.pitchPositive : rx.pitchNegative

        if rOver && pOver {
            // Diagonal arrow — combine roll and pitch directions
            let arrow: String
            switch (userRoll > 0, userPitch > 0) {
            case (true,  true):  arrow = "arrow.down.right"
            case (true,  false): arrow = "arrow.up.right"
            case (false, true):  arrow = "arrow.down.left"
            case (false, false): arrow = "arrow.up.left"
            }
            return (arrow, rollText, pitchText)
        } else if rOver {
            let arrow = userRoll > 0 ? "arrow.right" : "arrow.left"
            return (arrow, rollText, nil)
        } else {
            let arrow = userPitch > 0 ? "arrow.down" : "arrow.up"
            return (arrow, pitchText, nil)
        }
    }

    var bgColor: Color {
        guard rx.isConnected else { return Color(white: 0.15) }
        if userIsLevel { return .green }
        let maxOff = max(abs(userRoll), abs(userPitch))
        return maxOff > rx.tolerance * 5 ? .red.opacity(0.85) : .orange.opacity(0.75)
    }

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            if !rx.isConnected {
                notConnectedView
            } else {
                TabView {
                    // Page 1: level indicator or guidance
                    Group {
                        if userIsLevel { levelView } else { guidanceView }
                    }
                    .tag(0)

                    // Page 2: diagram — stays visible even when level
                    diagramPageView
                        .tag(1)

                    // Page 3: connection & app info
                    infoPageView
                        .tag(2)
                }
                .tabViewStyle(.page)
            }
        }
        .onAppear {
            compass.start()
            runtime.start()
        }
        .onDisappear {
            compass.stop()
            runtime.stop()
        }
        .sensoryFeedback(.success, trigger: userIsLevel) { _, new in new }
    }

    // MARK: - Sub-views

    private var notConnectedView: some View {
        VStack(spacing: 8) {
            Image(systemName: "iphone.slash")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text("iLevelX auf dem\niPhone öffnen")
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
    }

    private var levelView: some View {
        VStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(.white)
                .shadow(color: .white.opacity(0.4), radius: 8)
            Text("WAAGERECHT")
                .font(.system(.headline, design: .rounded, weight: .black))
                .foregroundStyle(.white)
            Text(String(format: "±%.1f°", rx.tolerance))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    // MARK: - Page 1: Bubble + Arrow

    private var guidanceView: some View {
        VStack(spacing: 2) {
            // Profile + compass indicator
            HStack(spacing: 4) {
                Image(systemName: rx.profileIcon).font(.system(size: 9))
                Text(rx.profileName).font(.system(size: 10, weight: .medium))
                Spacer()
                Image(systemName: compassActive ? "location.north.fill" : "location.slash")
                    .font(.system(size: 8))
                    .foregroundStyle(.white.opacity(compassActive ? 0.6 : 0.3))
            }
            .foregroundStyle(.white.opacity(0.7))
            .padding(.horizontal, 4)

            // Bubble level
            WatchBubbleView(
                roll: userRoll,
                pitch: userPitch,
                tolerance: rx.tolerance,
                showPitch: rx.showPitch
            )
            .frame(width: 70, height: 70)

            // Primary correction
            if let p = primary {
                VStack(spacing: 2) {
                    Image(systemName: p.arrow)
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 3)
                    Text(p.text)
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                        .padding(.horizontal, 4)
                    if let sub = p.subtext {
                        Text(sub)
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.75)
                            .padding(.horizontal, 4)
                    }
                }
            }

            Spacer(minLength: 4)
        }
    }

    // MARK: - Page 2: Top-down diagram (always black background)

    private var diagramPageView: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: rx.profileIcon).font(.system(size: 9))
                    Text(rx.profileName).font(.system(size: 10, weight: .medium))
                    Spacer()
                    Image(systemName: compassActive ? "location.north.fill" : "location.slash")
                        .font(.system(size: 8))
                        .foregroundStyle(.white.opacity(compassActive ? 0.5 : 0.2))
                }
                .foregroundStyle(.white.opacity(0.6))
                .padding(.horizontal, 4)

                WatchTopDownView(
                    roll: userRoll,
                    pitch: userPitch,
                    tolerance: rx.tolerance,
                    showPitch: rx.showPitch
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 4)

                Spacer(minLength: 4)
            }
        }
    }

    // MARK: - Page 3: Connection & App Info

    private var infoPageView: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 10) {

                // App title + version
                HStack(spacing: 6) {
                    Image(systemName: "scope")
                        .font(.system(size: 11))
                    Text("iLevelX")
                        .font(.system(size: 13, weight: .bold))
                    Spacer()
                    Text("v1.0.1")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .foregroundStyle(.white)

                Divider().overlay(Color.white.opacity(0.2))

                // iPhone connection
                InfoRow(
                    icon: rx.isConnected ? "iphone" : "iphone.slash",
                    iconColor: rx.isConnected ? .green : .red,
                    label: "iPhone",
                    value: rx.isConnected ? "Verbunden" : "Getrennt"
                )

                // Compass
                InfoRow(
                    icon: compassActive ? "location.north.fill" : "location.slash",
                    iconColor: compassActive ? .blue : .gray,
                    label: "Kompass",
                    value: compassActive
                        ? String(format: "%.0f°", compass.heading)
                        : "Nicht verfügbar"
                )

                // Active profile
                InfoRow(
                    icon: rx.profileIcon,
                    iconColor: .orange,
                    label: "Profil",
                    value: rx.isConnected ? rx.profileName : "–"
                )

                // Tolerance
                InfoRow(
                    icon: "plusminus",
                    iconColor: .yellow,
                    label: "Toleranz",
                    value: rx.isConnected
                        ? String(format: "±%.1f°", rx.tolerance)
                        : "–"
                )

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)
        }
    }
}

// MARK: - Info Row Helper

private struct InfoRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(iconColor)
                .frame(width: 16)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
    }
}

// MARK: - Watch Top-Down Diagram

struct WatchTopDownView: View {
    let roll: Double
    let pitch: Double
    let tolerance: Double
    let showPitch: Bool

    private var leftLow:  Bool { roll < -tolerance }
    private var rightLow: Bool { roll >  tolerance }
    private var frontLow: Bool { showPitch && pitch < -tolerance }
    private var backLow:  Bool { showPitch && pitch >  tolerance }

    private func edgeColor(_ isLow: Bool, _ degrees: Double) -> Color {
        guard isLow else { return .green }
        return abs(degrees) > tolerance * 4 ? .red : .orange
    }

    var body: some View {
        VStack(spacing: 2) {
            if showPitch {
                WatchEdgeBar(isLow: frontLow, label: "V",
                             degrees: abs(pitch),
                             color: edgeColor(frontLow, pitch),
                             axis: .horizontal)
            }
            HStack(spacing: 2) {
                WatchEdgeBar(isLow: leftLow, label: "L",
                             degrees: abs(roll),
                             color: edgeColor(leftLow, roll),
                             axis: .vertical)

                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.08))
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    Image(systemName: "iphone")
                        .font(.system(size: 18))
                        .foregroundStyle(.white.opacity(0.3))
                }

                WatchEdgeBar(isLow: rightLow, label: "R",
                             degrees: abs(roll),
                             color: edgeColor(rightLow, roll),
                             axis: .vertical)
            }
            if showPitch {
                WatchEdgeBar(isLow: backLow, label: "H",
                             degrees: abs(pitch),
                             color: edgeColor(backLow, pitch),
                             axis: .horizontal)
            }
        }
    }
}

private struct WatchEdgeBar: View {
    let isLow: Bool
    let label: String
    let degrees: Double
    let color: Color
    let axis: Axis

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(color.opacity(isLow ? 0.25 : 0.35))
            RoundedRectangle(cornerRadius: 4)
                .stroke(color.opacity(isLow ? 0.6 : 0.85), lineWidth: 1)

            if axis == .horizontal {
                HStack(spacing: 3) {
                    if isLow {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(color)
                    }
                    Text(label)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(isLow ? color : .white.opacity(0.4))
                    if isLow {
                        Text(String(format: "%.1f°", degrees))
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundStyle(color.opacity(0.9))
                    }
                }
            } else {
                VStack(spacing: 1) {
                    if isLow {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(color)
                    }
                    Text(label)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(isLow ? color : .white.opacity(0.4))
                    if isLow {
                        Text(String(format: "%.0f°", degrees))
                            .font(.system(size: 7, design: .monospaced))
                            .foregroundStyle(color.opacity(0.9))
                    }
                }
            }
        }
        .frame(
            width:  axis == .vertical   ? 28 : nil,
            height: axis == .horizontal ? 24 : nil
        )
    }
}

// MARK: - Watch Bubble View

struct WatchBubbleView: View {
    let roll: Double
    let pitch: Double
    let tolerance: Double
    let showPitch: Bool

    private let maxDeg: Double   = 10.0
    private let bubSize: CGFloat = 13

    var isLevel: Bool { abs(roll) <= tolerance && (!showPitch || abs(pitch) <= tolerance) }

    var body: some View {
        GeometryReader { geo in
            let size   = min(geo.size.width, geo.size.height)
            let radius = size / 2
            let maxOff = radius - bubSize / 2 - 2

            let rawX = CGFloat(-roll  / maxDeg) * maxOff
            let rawY = CGFloat((showPitch ? pitch : 0) / maxDeg) * maxOff
            let mag  = sqrt(rawX * rawX + rawY * rawY)
            let sc   = mag > maxOff ? maxOff / mag : 1.0
            let bx   = rawX * sc
            let by   = rawY * sc

            let tolZone = size * CGFloat(tolerance / maxDeg) * 2

            ZStack {
                Circle().stroke(Color.white.opacity(0.35), lineWidth: 1)

                Path { p in
                    p.move(to: CGPoint(x: radius * 0.25, y: radius))
                    p.addLine(to: CGPoint(x: radius * 1.75, y: radius))
                    p.move(to: CGPoint(x: radius, y: radius * 0.25))
                    p.addLine(to: CGPoint(x: radius, y: radius * 1.75))
                }
                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)

                Circle()
                    .fill(Color.green.opacity(isLevel ? 0.25 : 0.12))
                    .frame(width: tolZone, height: tolZone)
                Circle()
                    .stroke(Color.green.opacity(isLevel ? 0.7 : 0.3), lineWidth: 0.8)
                    .frame(width: tolZone, height: tolZone)

                Circle()
                    .fill(isLevel ? Color.green : Color.white)
                    .frame(width: bubSize, height: bubSize)
                    .shadow(color: isLevel ? Color.green.opacity(0.7) : .clear, radius: 4)
                    .offset(x: bx, y: by)
                    .animation(.interpolatingSpring(stiffness: 220, damping: 24), value: bx)
                    .animation(.interpolatingSpring(stiffness: 220, damping: 24), value: by)

                Circle()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 3, height: 3)
            }
            .frame(width: size, height: size)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

#Preview {
    WatchLevelView()
}
