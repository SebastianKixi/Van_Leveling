import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var page = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "bubble.left.and.exclamationmark.bubble.right",
            iconColor: .blue,
            title: "Willkommen bei iLevelX",
            body: "Richte jedes Objekt präzise waagerecht aus – ob Wohnwagen, Kamera, Regal oder Billardtisch. Leg einfach das iPhone auf die Fläche und folge den Anweisungen."
        ),
        OnboardingPage(
            icon: "scope",
            iconColor: .green,
            title: "Die Libelle",
            body: "Die Blase zeigt die aktuelle Neigung. Bring sie in die grüne Zone – dann ist alles waagerecht.\n\nDie Balken darunter zeigen dir die exakte Gradzahl für Links/Rechts und Vorne/Hinten."
        ),
        OnboardingPage(
            icon: "slider.horizontal.3",
            iconColor: .orange,
            title: "Profile",
            body: "Wähle das passende Profil für deinen Einsatzzweck:\n\n• Allgemein – für alles\n• Wohnwagen – gröbere Toleranz\n• Kamera – hochpräzise (Pro)\n• Gerät – Waschmaschine & Co.\n• Regal – nur Links/Rechts\n• Billard – höchste Präzision (Pro)"
        ),
        OnboardingPage(
            icon: "scope",
            iconColor: .accentColor,
            title: "Kalibrierung",
            body: "Liegt das iPhone auf einer Fläche, die du als \"waagerecht\" definieren möchtest (z. B. leicht geneigter Boden), tippe auf 'Als Waagerecht setzen'.\n\nDie Kalibrierung lässt sich jederzeit in den Einstellungen zurücksetzen."
        ),
        OnboardingPage(
            icon: "applewatch",
            iconColor: .purple,
            title: "Apple Watch",
            body: "Leg das iPhone auf das Objekt. Die Watch zeigt dir dank Kompass-Ausgleich immer die richtige Richtung – egal von welcher Seite du stehst.\n\nWische auf der Watch nach links für die Draufsicht-Übersicht."
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { i in
                    pageView(pages[i])
                        .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            // Bottom bar
            VStack(spacing: 12) {
                if page < pages.count - 1 {
                    Button {
                        withAnimation { page += 1 }
                    } label: {
                        Text("Weiter")
                            .font(.body.bold())
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button("Überspringen") { dismiss() }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Button {
                        dismiss()
                    } label: {
                        Text("Los geht's!")
                            .font(.body.bold())
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 32)
            .padding(.top, 8)
        }
    }

    @ViewBuilder
    private func pageView(_ p: OnboardingPage) -> some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(p.iconColor.opacity(0.12))
                    .frame(width: 100, height: 100)
                Image(systemName: p.icon)
                    .font(.system(size: 44))
                    .foregroundStyle(p.iconColor)
            }

            VStack(spacing: 12) {
                Text(p.title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text(p.body)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
            .padding(.horizontal, 28)

            Spacer()
            Spacer()
        }
    }
}

private struct OnboardingPage {
    let icon: String
    let iconColor: Color
    let title: String
    let body: String
}

#Preview {
    OnboardingView()
}
