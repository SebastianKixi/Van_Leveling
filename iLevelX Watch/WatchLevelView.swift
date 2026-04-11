import SwiftUI

struct WatchLevelView: View {
    @State private var rx = WatchConnectivityReceiver()

    // The axis that is furthest off-level → shown as primary instruction
    private var primary: (arrow: String, text: String, degrees: Double)? {
        let rOff = abs(rx.roll)
        let pOff = abs(rx.pitch)
        let rOver = rOff > rx.tolerance
        let pOver = pOff > rx.tolerance && rx.showPitch

        guard rOver || pOver else { return nil }

        if rOff >= pOff || !pOver {
            let arrow = rx.roll > 0 ? "arrow.left" : "arrow.right"
            return (arrow, rx.rollInstruction, rx.roll)
        } else {
            let arrow = rx.pitch > 0 ? "arrow.down" : "arrow.up"
            return (arrow, rx.pitchInstruction, rx.pitch)
        }
    }

    // Secondary axis (the other one, shown small)
    private var secondary: (arrow: String, degrees: Double, isLevel: Bool)? {
        guard !rx.isLevel, let p = primary else { return nil }
        if p.arrow == "arrow.left" || p.arrow == "arrow.right" {
            guard rx.showPitch else { return nil }
            let arrow = rx.pitch > 0 ? "arrow.down" : "arrow.up"
            return (arrow, rx.pitch, rx.isPitchLevel)
        } else {
            let arrow = rx.roll > 0 ? "arrow.left" : "arrow.right"
            return (arrow, rx.roll, rx.isRollLevel)
        }
    }

    var bgColor: Color {
        guard rx.isConnected else { return Color(.darkGray) }
        if rx.isLevel { return .green }
        let maxOff = max(abs(rx.roll), abs(rx.pitch))
        return maxOff > rx.tolerance * 5 ? .red.opacity(0.85) : .orange.opacity(0.75)
    }

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            if !rx.isConnected {
                notConnectedView
            } else if rx.isLevel {
                levelView
            } else {
                guidanceView
            }
        }
        // Haptic when becoming level
        .sensoryFeedback(.success, trigger: rx.isLevel) { _, new in new }
        // Continuous haptic hint while very far off
        .sensoryFeedback(.warning, trigger: rx.isLevel) { old, new in old && !new }
    }

    // MARK: - Sub-views

    private var notConnectedView: some View {
        VStack(spacing: 8) {
            Image(systemName: "iphone.slash")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text("Open iLevelX\non iPhone")
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
    }

    private var levelView: some View {
        VStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(.white)
                .shadow(color: .white.opacity(0.4), radius: 8)
            Text("LEVEL")
                .font(.system(.headline, design: .rounded, weight: .black))
                .foregroundStyle(.white)
            Text(String(format: "±%.1f°", rx.tolerance))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    private var guidanceView: some View {
        VStack(spacing: 2) {
            // Profile badge
            HStack(spacing: 3) {
                Image(systemName: rx.profileIcon)
                    .font(.system(size: 10))
                Text(rx.profileName)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(.white.opacity(0.75))
            .padding(.top, 2)

            Spacer(minLength: 4)

            // Primary correction
            if let p = primary {
                VStack(spacing: 3) {
                    Image(systemName: p.arrow)
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 4)

                    Text(p.text)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)

                    Text(String(format: "%.1f°", abs(p.degrees)))
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }

            Spacer(minLength: 4)

            // Secondary axis + mini status dots
            HStack(spacing: 12) {
                // Roll dot
                AxisStatusDot(
                    isLevel: rx.isRollLevel,
                    label: "R",
                    degrees: rx.roll
                )

                // Pitch dot (only if applicable)
                if rx.showPitch {
                    AxisStatusDot(
                        isLevel: rx.isPitchLevel,
                        label: "P",
                        degrees: rx.pitch
                    )
                }
            }
            .padding(.bottom, 4)
        }
        .padding(.horizontal, 6)
    }
}

// MARK: - Axis Status Dot

private struct AxisStatusDot: View {
    let isLevel: Bool
    let label: String
    let degrees: Double

    var body: some View {
        VStack(spacing: 2) {
            Circle()
                .fill(isLevel ? Color.green : Color.white.opacity(0.5))
                .frame(width: 7, height: 7)
                .overlay(
                    Circle().stroke(Color.white.opacity(0.6), lineWidth: 0.5)
                )
            Text(label)
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
            Text(String(format: "%.1f°", abs(degrees)))
                .font(.system(size: 8, design: .monospaced))
                .foregroundStyle(.white.opacity(0.6))
        }
    }
}

#Preview {
    WatchLevelView()
}
