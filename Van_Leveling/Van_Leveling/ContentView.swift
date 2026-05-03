import SwiftUI

struct ContentView: View {
    @State private var viewModel = LevelViewModel()
    @State private var showSettings = false
    @State private var selectedTab: Int = 0
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showOnboarding = false

    /// Erlaubte Geräte-Orientierung pro Tab.
    private func allowedOrientations(for tab: Int) -> UIInterfaceOrientationMask {
        switch tab {
        case 0:  return .portrait               // Profile
        case 1:  return .landscape              // Wasserwaage
        case 2:  return .landscape              // Winkelmesser
        default: return .portrait
        }
    }

    private func applyOrientation(for tab: Int) {
        let mask = allowedOrientations(for: tab)
        AppDelegate.orientationLock = mask
        if let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first {
            scene.requestGeometryUpdate(.iOS(interfaceOrientations: mask))
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ProfileLevelTab(viewModel: viewModel, showSettings: $showSettings)
                .tabItem {
                    Label("Profile", systemImage: "scope")
                }
                .tag(0)

            WasserwaageView(viewModel: viewModel, showSettings: $showSettings)
                .tabItem {
                    Label("Wasserwaage", systemImage: "ruler")
                }
                .tag(1)

            WinkelmesserView(viewModel: viewModel, showSettings: $showSettings)
                .tabItem {
                    Label("Winkel", systemImage: "angle")
                }
                .tag(2)
        }
        .onChange(of: selectedTab) { _, newTab in
            applyOrientation(for: newTab)
        }
        .onAppear {
            applyOrientation(for: selectedTab)
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
        .sheet(isPresented: $showSettings) {
            SettingsView(viewModel: viewModel)
        }
        .onChange(of: viewModel.adjustedPitch) { viewModel.onMotionTick() }
        .sensoryFeedback(.success, trigger: viewModel.isLevel) { _, new in new }
    }
}

// MARK: - Profile Tab (bisherige Hauptansicht)

private struct ProfileLevelTab: View {
    let viewModel: LevelViewModel
    @Binding var showSettings: Bool

    @Environment(\.verticalSizeClass) private var vSize
    @AppStorage("hideWatchHint") private var hideWatchHint: Bool = false

    var body: some View {
        NavigationStack {
            Group {
                if vSize == .regular {
                    portraitContent
                } else {
                    Color(.systemBackground)
                }
            }
            .navigationTitle("iLevelX")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gear")
                    }
                }
            }
        }
    }

    private var portraitContent: some View {
        ScrollView {
            VStack(spacing: 12) {

                if !hideWatchHint
                    && viewModel.watchManager.isWatchPaired
                    && viewModel.watchManager.isWatchAppInstalled
                    && !viewModel.watchManager.isWatchReachable {
                    WatchHintBanner(onDismiss: { hideWatchHint = true })
                        .padding(.horizontal, 16)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                    HStack(alignment: .top, spacing: 8) {
                        VerticalLevelStrip(
                            value: viewModel.adjustedPitch,
                            tolerance: viewModel.tolerance,
                            topLabel: "V",
                            bottomLabel: "H"
                        )
                        .frame(width: 34)

                        VStack(spacing: 6) {
                            BubbleLevelView(
                                pitch: viewModel.adjustedPitch,
                                roll:  viewModel.adjustedRoll,
                                tolerance: viewModel.tolerance
                            )

                            HorizontalLevelStrip(
                                value: viewModel.adjustedRoll,
                                tolerance: viewModel.tolerance,
                                leftLabel: "L",
                                rightLabel: "R"
                            )
                            .frame(height: 34)
                        }
                    }
                    .padding(.horizontal, 28)

                    GuidanceView(viewModel: viewModel)
                        .padding(.horizontal, 20)

                    ProfilePicker(viewModel: viewModel)

                    LevelBarsView(
                        pitch: viewModel.adjustedPitch,
                        roll:  viewModel.adjustedRoll,
                        tolerance: viewModel.tolerance
                    )
                    .padding(.horizontal, 20)

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

                    Spacer(minLength: 16)
            }
            .padding(.top, 4)
            .animation(.easeInOut(duration: 0.3),
                       value: viewModel.watchManager.isWatchReachable)
            .animation(.easeInOut(duration: 0.3), value: hideWatchHint)
        }
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

// MARK: - Watch Hint Banner

private struct WatchHintBanner: View {
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "applewatch.radiowaves.left.and.right")
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Color.purple.gradient, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("iLevelX auf der Watch öffnen")
                    .font(.subheadline.bold())
                Text("Hände frei beim Ausrichten — die Watch zeigt Live-Anweisungen.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                    .padding(6)
                    .background(Color.secondary.opacity(0.15), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Level Strip Indicators

/// Vertikaler Messstreifen: Marker wandert nach oben/unten und zeigt
/// die niedrige Seite an (Pitch). Top-Label = Vorne, Bottom-Label = Hinten.
private struct VerticalLevelStrip: View {
    let value: Double
    let tolerance: Double
    let topLabel: String
    let bottomLabel: String

    private let maxValue: Double = 10.0

    private var isLevel: Bool { abs(value) <= tolerance }

    private var markerColor: Color {
        if isLevel { return .green }
        if abs(value) > maxValue * 0.5 { return .red }
        return .orange
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(topLabel)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)

            GeometryReader { geo in
                let h = geo.size.height
                let normalized = max(-1.0, min(1.0, value / maxValue))
                let offset = CGFloat(normalized) * (h / 2)
                let tolH = CGFloat(tolerance / maxValue) * h * 2

                ZStack {
                    // Track
                    Capsule()
                        .fill(Color.secondary.opacity(0.18))
                        .frame(width: 8)

                    // Tolerance zone
                    Capsule()
                        .fill(Color.green.opacity(isLevel ? 0.4 : 0.15))
                        .frame(width: 8, height: max(tolH, 6))

                    // Tick marks (every 2°)
                    ForEach([1, 2, 3, 4], id: \.self) { i in
                        let off = CGFloat(i) * h / 10
                        Group {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.35))
                                .frame(width: 14, height: 1)
                                .offset(y: off)
                            Rectangle()
                                .fill(Color.secondary.opacity(0.35))
                                .frame(width: 14, height: 1)
                                .offset(y: -off)
                        }
                    }

                    // Center line (0°)
                    Rectangle()
                        .fill(Color.secondary.opacity(0.7))
                        .frame(width: 18, height: 1.5)

                    // Marker (zeigt die NIEDRIGE Seite)
                    Capsule()
                        .fill(markerColor.gradient)
                        .frame(width: 22, height: 8)
                        .shadow(color: markerColor.opacity(0.5), radius: 4)
                        .offset(y: offset)
                        .animation(
                            .interpolatingSpring(stiffness: 280, damping: 28),
                            value: offset
                        )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Text(bottomLabel)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

/// Horizontaler Messstreifen: Marker wandert nach links/rechts (Roll).
/// Left-Label = Links, Right-Label = Rechts.
private struct HorizontalLevelStrip: View {
    let value: Double
    let tolerance: Double
    let leftLabel: String
    let rightLabel: String

    private let maxValue: Double = 10.0

    private var isLevel: Bool { abs(value) <= tolerance }

    private var markerColor: Color {
        if isLevel { return .green }
        if abs(value) > maxValue * 0.5 { return .red }
        return .orange
    }

    var body: some View {
        HStack(spacing: 6) {
            Text(leftLabel)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)

            GeometryReader { geo in
                let w = geo.size.width
                // Marker wandert zur HOHEN Seite – wie das Bläschen in der Bubble.
                // Bei roll > 0 (rechte Seite tief) wandert der Marker nach LINKS.
                let normalized = max(-1.0, min(1.0, -value / maxValue))
                let offset = CGFloat(normalized) * (w / 2)
                let tolW = CGFloat(tolerance / maxValue) * w * 2

                ZStack {
                    Capsule()
                        .fill(Color.secondary.opacity(0.18))
                        .frame(height: 8)

                    Capsule()
                        .fill(Color.green.opacity(isLevel ? 0.4 : 0.15))
                        .frame(width: max(tolW, 6), height: 8)

                    ForEach([1, 2, 3, 4], id: \.self) { i in
                        let off = CGFloat(i) * w / 10
                        Group {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.35))
                                .frame(width: 1, height: 14)
                                .offset(x: off)
                            Rectangle()
                                .fill(Color.secondary.opacity(0.35))
                                .frame(width: 1, height: 14)
                                .offset(x: -off)
                        }
                    }

                    Rectangle()
                        .fill(Color.secondary.opacity(0.7))
                        .frame(width: 1.5, height: 18)

                    Capsule()
                        .fill(markerColor.gradient)
                        .frame(width: 8, height: 22)
                        .shadow(color: markerColor.opacity(0.5), radius: 4)
                        .offset(x: offset)
                        .animation(
                            .interpolatingSpring(stiffness: 280, damping: 28),
                            value: offset
                        )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Text(rightLabel)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 6)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Supporting Views


#Preview {
    ContentView()
}
