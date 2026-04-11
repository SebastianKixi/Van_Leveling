import SwiftUI

struct BubbleLevelView: View {
    let pitch: Double
    let roll: Double
    let tolerance: Double

    private let maxDegrees: Double = 10.0
    private let bubbleSize: CGFloat = 50

    private var isLevel: Bool {
        abs(pitch) <= tolerance && abs(roll) <= tolerance
    }

    private var bubbleColor: Color {
        let dist = sqrt(pitch * pitch + roll * roll)
        if dist <= tolerance        { return .green  }
        if dist <= tolerance * 3.0  { return .yellow }
        return .red
    }

    var body: some View {
        GeometryReader { geo in
            let size      = min(geo.size.width, geo.size.height)
            let radius    = size / 2.0
            let maxOffset = radius - bubbleSize / 2 - 6

            // Bubble offset: bubble floats toward the HIGH side (opposite to tilt)
            let rawX = CGFloat(-roll  / maxDegrees) * maxOffset
            let rawY = CGFloat( pitch / maxDegrees) * maxOffset

            // Clamp to circle boundary
            let magnitude = sqrt(rawX * rawX + rawY * rawY)
            let scale     = magnitude > maxOffset ? maxOffset / magnitude : 1.0
            let bx = rawX * scale
            let by = rawY * scale

            let levelZone = size * CGFloat(tolerance / maxDegrees) * 2.0

            ZStack {
                // Background
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.primary.opacity(0.03), Color.secondary.opacity(0.08)],
                            center: .center,
                            startRadius: 0,
                            endRadius: radius
                        )
                    )
                    .background(.regularMaterial, in: Circle())

                // Cross-hair lines
                Path { p in
                    p.move(to:    CGPoint(x: 0,    y: radius))
                    p.addLine(to: CGPoint(x: size, y: radius))
                    p.move(to:    CGPoint(x: radius, y: 0   ))
                    p.addLine(to: CGPoint(x: radius, y: size))
                }
                .stroke(Color.secondary.opacity(0.15), lineWidth: 1)

                // Degree rings (2°, 5°)
                ForEach([2.0, 5.0], id: \.self) { deg in
                    Circle()
                        .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
                        .frame(
                            width:  size * CGFloat(deg / maxDegrees) * 2,
                            height: size * CGFloat(deg / maxDegrees) * 2
                        )
                }

                // Level-zone fill
                Circle()
                    .fill(Color.green.opacity(isLevel ? 0.20 : 0.10))
                    .frame(width: levelZone, height: levelZone)
                    .animation(.easeInOut(duration: 0.3), value: isLevel)

                // Level-zone border
                Circle()
                    .stroke(
                        isLevel ? Color.green : Color.green.opacity(0.35),
                        lineWidth: 1.5
                    )
                    .frame(width: levelZone, height: levelZone)
                    .animation(.easeInOut(duration: 0.3), value: isLevel)

                // Bubble
                Circle()
                    .fill(bubbleColor.gradient)
                    .frame(width: bubbleSize, height: bubbleSize)
                    .shadow(color: bubbleColor.opacity(0.5), radius: 8, x: 0, y: 3)
                    .offset(x: bx, y: by)
                    .animation(
                        .interpolatingSpring(stiffness: 280, damping: 28),
                        value: bx
                    )
                    .animation(
                        .interpolatingSpring(stiffness: 280, damping: 28),
                        value: by
                    )

                // Center pin
                Circle()
                    .fill(Color.secondary.opacity(0.5))
                    .frame(width: 6, height: 6)

                // Outer ring
                Circle()
                    .stroke(Color.secondary.opacity(0.35), lineWidth: 2)
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

#Preview {
    BubbleLevelView(pitch: 2.5, roll: -1.5, tolerance: 1.0)
        .padding(40)
}
