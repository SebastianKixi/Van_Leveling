import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var page = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "scope",
            iconColor: .blue,
            title: "Willkommen bei iLevelX",
            body: "Richte Objekte präzise aus – Wohnwagen, Möbel, Kamera, Regale und mehr.\n\nDrei Modi für drei Aufgaben: Profile, Wasserwaage und Winkelmesser. Wechseln kannst du unten über die Tab-Leiste."
        ),
        OnboardingPage(
            icon: "rectangle.3.group",
            iconColor: .green,
            title: "Profile",
            body: "Lege das iPhone flach auf die Fläche, die du ausrichten möchtest.\n\nDie Libelle zeigt die Neigung – die Streifen links und unten markieren die hohe Seite. Bring die Blase in die grüne Zone, dann ist es waagerecht."
        ),
        OnboardingPage(
            icon: "slider.horizontal.3",
            iconColor: .orange,
            title: "Profil wählen",
            body: "Pro Anwendungsfall ein eigenes Profil mit angepasster Toleranz und Anweisungstexten:\n\n• Allgemein – Standard-Modus\n• Wohnwagen – gröbere Toleranz\n• Gerät – Waschmaschine & Co.\n• Regal – nur Links/Rechts\n• Kamera – hochpräzise (Pro)"
        ),
        OnboardingPage(
            icon: "ruler",
            iconColor: .teal,
            title: "Wasserwaage",
            body: "Halte das iPhone quer auf der langen Kante an die Fläche, die du prüfen möchtest – wie eine klassische Alu-Wasserwaage.\n\nDas Bläschen wandert zur hohen Seite, der Grad-Wert zeigt die exakte Neigung."
        ),
        OnboardingPage(
            icon: "angle",
            iconColor: .indigo,
            title: "Winkelmesser",
            body: "Zum Messen von Neigungen und Steigungen. Halte das iPhone quer auf der langen Kante an die geneigte Fläche.\n\nMit 'Halten' frierst du den Wert ein, mit 'Nullen' setzt du die aktuelle Lage als 0°-Referenz."
        ),
        OnboardingPage(
            icon: "scope",
            iconColor: .accentColor,
            title: "Kalibrierung",
            body: "Im Profile-Modus kannst du jede beliebige Position als \"waagerecht\" definieren – nützlich wenn der Untergrund nicht perfekt eben ist.\n\nLeg das iPhone wie gewünscht hin und tippe \"Als Waagerecht setzen\". Zurücksetzen jederzeit in den Einstellungen."
        ),
        OnboardingPage(
            icon: "applewatch",
            iconColor: .purple,
            title: "Apple Watch",
            body: "Leg das iPhone auf das Objekt – die Watch zeigt dir dank Kompass-Ausgleich immer die richtige Richtung, egal von welcher Seite du stehst.\n\nWische auf der Watch nach links für die Draufsicht-Übersicht, weiter für Verbindungsdetails."
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
