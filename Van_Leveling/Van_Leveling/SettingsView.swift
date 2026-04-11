import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: LevelViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showOnboarding = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: – Feedback
                Section("Rückmeldung") {
                    Toggle("Ton bei Waagerecht", isOn: $viewModel.soundEnabled)
                }

                // MARK: – Calibration
                Section {
                    LabeledContent("Neigungs-Offset (V/H)") {
                        Text(String(format: "%.2f°", viewModel.calibrationPitch))
                            .foregroundStyle(.secondary)
                    }
                    LabeledContent("Neigungs-Offset (L/R)") {
                        Text(String(format: "%.2f°", viewModel.calibrationRoll))
                            .foregroundStyle(.secondary)
                    }
                    Button("Auf Werkseinstellungen zurücksetzen", role: .destructive) {
                        viewModel.resetCalibration()
                    }
                } header: {
                    Text("Kalibrierung")
                } footer: {
                    Text("Verwende 'Als Waagerecht setzen' im Hauptbildschirm, um die aktuelle Position als Referenz zu speichern.")
                }

                // MARK: – Sensor Info
                Section("Sensor") {
                    LabeledContent("Bewegungssensor") {
                        Text(viewModel.motion.isAvailable ? "Verfügbar" : "Nicht verfügbar")
                            .foregroundStyle(viewModel.motion.isAvailable ? .green : .red)
                    }
                    LabeledContent("Aktualisierungsrate", value: "60 Hz")
                    LabeledContent("Toleranz") {
                        Text(String(format: "±%.1f°", viewModel.tolerance))
                            .foregroundStyle(.secondary)
                    }
                }

                // MARK: – Help
                Section {
                    Button {
                        showOnboarding = true
                    } label: {
                        Label("Anleitung anzeigen", systemImage: "book.pages")
                    }
                } header: {
                    Text("Hilfe")
                }

                // MARK: – About
                Section {
                    LabeledContent("App", value: "iLevelX")
                    LabeledContent("Version", value: "1.0.1")

                    HStack(spacing: 14) {
                        Image("KirschxLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sebastian Kirschner")
                                .font(.subheadline.bold())
                            Text("kirschx.ai")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Über")
                }
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showOnboarding) {
                OnboardingView()
            }
        }
    }
}
