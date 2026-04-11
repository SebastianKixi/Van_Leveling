import SwiftUI

/// Generic guidance view — content adapts to the selected LevelProfile.
struct GuidanceView: View {
    let viewModel: LevelViewModel

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: viewModel.selectedProfile.icon)
                    .foregroundStyle(.secondary)
                Text(viewModel.selectedProfile.name)
                    .font(.headline)
                Spacer()
                Text(String(format: "±%.1f°", viewModel.tolerance))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Divider()

            if viewModel.isLevel {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                    Text("Perfekt waagerecht!")
                        .font(.subheadline.bold())
                        .foregroundStyle(.green)
                    Spacer()
                }
                .padding(10)
                .background(Color.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                .transition(.scale.combined(with: .opacity))
            } else {
                VStack(spacing: 10) {
                    // Top-down diagram showing which sides need raising
                    LevelDiagramView(
                        pitch: viewModel.adjustedPitch,
                        roll: viewModel.adjustedRoll,
                        tolerance: viewModel.tolerance,
                        showPitch: viewModel.selectedProfile.showPitch
                    )
                    .frame(height: viewModel.selectedProfile.showPitch ? 130 : 90)

                    // Text instructions
                    InstructionRow(
                        arrowName: viewModel.rollArrowName,
                        text: viewModel.rollInstruction,
                        isLevel: viewModel.isRollLevel
                    )
                    if viewModel.selectedProfile.showPitch {
                        InstructionRow(
                            arrowName: viewModel.pitchArrowName,
                            text: viewModel.pitchInstruction,
                            isLevel: viewModel.isPitchLevel
                        )
                    }
                }
                .transition(.opacity)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .animation(.easeInOut(duration: 0.25), value: viewModel.isLevel)
    }
}

// MARK: - Top-Down Diagram

/// Shows the object from above with coloured edges indicating which sides are too low.
struct LevelDiagramView: View {
    let pitch: Double
    let roll: Double
    let tolerance: Double
    let showPitch: Bool

    // Which sides need raising (too low)
    private var leftLow:  Bool { roll < -tolerance }
    private var rightLow: Bool { roll >  tolerance }
    private var frontLow: Bool { showPitch && pitch < -tolerance }
    private var backLow:  Bool { showPitch && pitch >  tolerance }

    private func edgeColor(_ isLow: Bool, _ degrees: Double) -> Color {
        guard isLow else { return .green }
        return abs(degrees) > tolerance * 4 ? .red : .orange
    }

    var body: some View {
        VStack(spacing: 3) {
            // Front edge
            if showPitch {
                EdgeBar(isLow: frontLow, label: "Vorne",
                        degrees: abs(pitch),
                        color: edgeColor(frontLow, pitch),
                        axis: .horizontal)
            }

            HStack(spacing: 3) {
                // Left edge
                EdgeBar(isLow: leftLow, label: "Links",
                        degrees: abs(roll),
                        color: edgeColor(leftLow, roll),
                        axis: .vertical)

                // Object body
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.07))
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1.5)
                    // iPhone icon to clarify orientation
                    Image(systemName: "iphone")
                        .font(.system(size: 22))
                        .foregroundStyle(.secondary.opacity(0.4))
                }

                // Right edge
                EdgeBar(isLow: rightLow, label: "Rechts",
                        degrees: abs(roll),
                        color: edgeColor(rightLow, roll),
                        axis: .vertical)
            }

            // Back edge
            if showPitch {
                EdgeBar(isLow: backLow, label: "Hinten",
                        degrees: abs(pitch),
                        color: edgeColor(backLow, pitch),
                        axis: .horizontal)
            }
        }
    }
}

private struct EdgeBar: View {
    let isLow: Bool
    let label: String
    let degrees: Double
    let color: Color
    let axis: Axis

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(color.opacity(isLow ? 0.18 : 0.08))
            RoundedRectangle(cornerRadius: 5)
                .stroke(color.opacity(isLow ? 0.5 : 0.2), lineWidth: 1)

            if axis == .horizontal {
                HStack(spacing: 4) {
                    if isLow {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(color)
                    }
                    Text(label)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(isLow ? color : .secondary)
                    if isLow {
                        Text(String(format: "%.1f°", degrees))
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(color.opacity(0.8))
                    }
                }
            } else {
                VStack(spacing: 2) {
                    if isLow {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(color)
                    }
                    Text(label)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(isLow ? color : .secondary)
                    if isLow {
                        Text(String(format: "%.1f°", degrees))
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundStyle(color.opacity(0.8))
                    }
                }
            }
        }
        .frame(
            width:  axis == .vertical   ? 46 : nil,
            height: axis == .horizontal ? 32 : nil
        )
    }
}

// MARK: - Instruction Row

private struct InstructionRow: View {
    let arrowName: String?
    let text: String
    let isLevel: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isLevel ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: arrowName ?? "checkmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(isLevel ? .green : .orange)
            }
            Text(text)
                .font(.subheadline.weight(isLevel ? .regular : .semibold))
                .foregroundStyle(isLevel ? .secondary : .primary)
            Spacer()
            if isLevel {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
            }
        }
        .padding(.horizontal, 4)
    }
}
