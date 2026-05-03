import SwiftUI

struct LevelBarsView: View {
    let pitch: Double
    let roll: Double
    let tolerance: Double

    var body: some View {
        VStack(spacing: 14) {
            LevelBar(
                value: roll,
                maxValue: 10.0,
                tolerance: tolerance,
                label: "Rollen",
                valueLabel: "L ← → R"
            )
            LevelBar(
                value: pitch,
                maxValue: 10.0,
                tolerance: tolerance,
                label: "Nicken",
                valueLabel: "V ← → H"
            )
        }
    }
}

struct LevelBar: View {
    let value: Double
    let maxValue: Double
    let tolerance: Double
    let label: String
    let valueLabel: String

    private var normalized: Double {
        max(-1.0, min(1.0, value / maxValue))
    }

    private var isLevel: Bool { abs(value) <= tolerance }

    private var barColor: Color {
        if isLevel               { return .green  }
        if abs(value) < maxValue * 0.5 { return .yellow }
        return .red
    }

    var body: some View {
        HStack(spacing: 10) {
            // Axis label
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption.bold())
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                Text(valueLabel)
                    .font(.system(size: 8))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
            .frame(width: 52, alignment: .leading)

            // Bar
            GeometryReader { geo in
                let w      = geo.size.width
                let halfW  = w / 2.0
                let offset = CGFloat(normalized) * halfW

                ZStack {
                    // Track
                    Capsule()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 10)

                    // Tolerance zone
                    Capsule()
                        .fill(Color.green.opacity(0.22))
                        .frame(width: CGFloat(tolerance / maxValue) * w * 2, height: 10)

                    // Filled section from center to indicator
                    if abs(offset) > 0.5 {
                        HStack(spacing: 0) {
                            if offset > 0 {
                                Spacer()
                                Capsule()
                                    .fill(barColor.opacity(0.35))
                                    .frame(width: abs(offset), height: 6)
                                    .padding(.trailing, halfW - abs(offset))
                            } else {
                                Capsule()
                                    .fill(barColor.opacity(0.35))
                                    .frame(width: abs(offset), height: 6)
                                    .padding(.leading, halfW - abs(offset))
                                Spacer()
                            }
                        }
                    }

                    // Center line
                    Rectangle()
                        .fill(Color.secondary.opacity(0.4))
                        .frame(width: 1.5, height: 18)

                    // Indicator pill
                    Capsule()
                        .fill(barColor.gradient)
                        .frame(width: 10, height: 20)
                        .shadow(color: barColor.opacity(0.4), radius: 4)
                        .offset(x: offset)
                        .animation(
                            .interpolatingSpring(stiffness: 280, damping: 28),
                            value: offset
                        )
                }
            }
            .frame(height: 22)

            // Degree readout
            Text(String(format: "%+.1f°", value))
                .font(.caption.monospacedDigit())
                .foregroundStyle(isLevel ? .green : .primary)
                .frame(width: 48, alignment: .trailing)
        }
    }
}

#Preview {
    LevelBarsView(pitch: 2.3, roll: -0.8, tolerance: 1.0)
        .padding()
}
