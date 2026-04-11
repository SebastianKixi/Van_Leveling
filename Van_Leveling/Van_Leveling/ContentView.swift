import SwiftUI

struct ContentView: View {
    @State private var viewModel = LevelViewModel()
    @State private var showSettings = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showOnboarding = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // ── Status badge ──────────────────────────────────────
                    StatusBadge(isLevel: viewModel.isLevel)

                    // ── Bubble level ──────────────────────────────────────
                    BubbleLevelView(
                        pitch: viewModel.adjustedPitch,
                        roll:  viewModel.adjustedRoll,
                        tolerance: viewModel.tolerance
                    )
                    .padding(.horizontal, 28)

                    // ── Degree readouts ───────────────────────────────────
                    HStack(spacing: 20) {
                        AngleReadout(
                            label: "Neigung",
                            sublabel: "Links / Rechts",
                            value: viewModel.adjustedRoll,
                            isLevel: viewModel.isRollLevel
                        )
                        AngleReadout(
                            label: "Neigung",
                            sublabel: "Vorne / Hinten",
                            value: viewModel.adjustedPitch,
                            isLevel: viewModel.isPitchLevel
                        )
                    }
                    .padding(.horizontal, 20)

                    // ── Guidance ──────────────────────────────────────────
                    GuidanceView(viewModel: viewModel)
                        .padding(.horizontal, 20)

                    // ── Level bars ────────────────────────────────────────
                    LevelBarsView(
                        pitch: viewModel.adjustedPitch,
                        roll:  viewModel.adjustedRoll,
                        tolerance: viewModel.tolerance
                    )
                    .padding(.horizontal, 20)

                    // ── Profile picker ────────────────────────────────────
                    ProfilePicker(viewModel: viewModel)

                    // ── Calibration ───────────────────────────────────────
                    VStack(spacing: 6) {
                        Button {
                            viewModel.calibrate()
                        } label: {
                            Label("Als Waagerecht setzen", systemImage: "scope")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)

                        if viewModel.calibrationPitch != 0 || viewModel.calibrationRoll != 0 {
                            Button("Kalibrierung zurücksetzen", role: .destructive) {
                                viewModel.resetCalibration()
                            }
                            .font(.footnote)
                            .transition(.opacity)
                        }
                    }
                    .padding(.horizontal, 20)
                    .animation(.easeInOut, value: viewModel.calibrationPitch)

                    Spacer(minLength: 24)
                }
                .padding(.top, 8)
            }
            .navigationTitle("iLevelX")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(viewModel: viewModel)
            }
        }
        .onAppear {
            viewModel.start()
            UIApplication.shared.isIdleTimerDisabled = true
            if !hasSeenOnboarding {
                showOnboarding = true
                hasSeenOnboarding = true
            }
        }
        .onDisappear {
            viewModel.stop()
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView()
        }
        // Drive sound + Watch updates on every sensor tick
        .onChange(of: viewModel.adjustedPitch) { viewModel.onMotionTick() }
        .sensoryFeedback(.success, trigger: viewModel.isLevel) { _, new in new }
    }
}

// MARK: - Profile Picker

private struct ProfilePicker: View {
    let viewModel: LevelViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(LevelProfile.all) { profile in
                    let isSelected = viewModel.selectedProfile == profile

                    Button {
                        viewModel.selectedProfile = profile
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: profile.icon)
                                .font(.caption)
                            Text(profile.name)
                                .font(.caption.bold())
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            isSelected
                                ? Color.accentColor
                                : Color.secondary.opacity(0.15),
                            in: Capsule()
                        )
                        .foregroundStyle(isSelected ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                    .animation(.easeInOut(duration: 0.15), value: isSelected)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Supporting Views

private struct StatusBadge: View {
    let isLevel: Bool

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isLevel ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
                .shadow(color: isLevel ? .green : .orange, radius: 4)
            Text(isLevel ? "Waagerecht" : "Nicht waagerecht")
                .font(.caption.weight(.semibold))
                .foregroundStyle(isLevel ? .green : .orange)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.regularMaterial, in: Capsule())
        .animation(.easeInOut(duration: 0.2), value: isLevel)
    }
}

private struct AngleReadout: View {
    let label: String
    let sublabel: String
    let value: Double
    let isLevel: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text(sublabel)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Text(String(format: "%+.1f°", value))
                .font(.system(.title, design: .monospaced, weight: .bold))
                .foregroundStyle(isLevel ? .green : .primary)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.1), value: value)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}


#Preview {
    ContentView()
}
