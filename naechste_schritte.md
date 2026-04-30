# iLevelX — Vorgehensplan & Wiedereinstieg

**Stand:** 2026-04-26
**Status der App:** Code ~80% fertig, **noch nicht im App Store**, kein IAP, kein Listing.
**Begleitende Recherche:** [`../Recherche_Apps/`](../Recherche_Apps/) — 50 App-Konzepte für Folge-Apps.

---

## TODO morgen (2026-05-01)

- [ ] **Einheitliches Design über alle Tabs** — Profile, Wasserwaage und Winkelmesser haben aktuell jeweils eigene Layouts und Stile. Vereinheitlichen: gemeinsame Akzentfarben, identische Spacings, konsistente Card-Styles, einheitliche Typo-Hierarchie, gleiche Status-Badges.
- [ ] **Neues App-Logo** für iPhone und Watch (Konzept-Auswahl ausstehend, siehe Chat-Verlauf)

---

## 1. Konzept und Positionierung (entschieden)

iLevelX ist **kein generisches Bubble-Level**, sondern ein **Multi-Mode Leveler mit Use-Case-spezifischen Anweisungen** + Apple-Watch-Live-Anzeige.

**Differenzierung gegenüber der Konkurrenz** (Lemondo Bubble Level: 111k US Reviews mit reiner Libelle):
- Use-Case-Profile: User wählt "Wohnwagen" → App sagt "Hebe linke vordere Stütze 1,5 cm" statt nur Bläschen anzuzeigen
- Apple-Watch-Anzeige mit Kompass-Heading-Ausgleich → User steht neben Wohnwagen, dreht Stützen, sieht Live-Anzeige aus jeder Richtung
- Kalibrierungs-Funktion ("Als Waagerecht setzen") für nicht-perfekte Untergründe

**Positionierung im App Store:**
- **Primärer Use-Case:** Wohnwagen-/Wohnmobil-Ausrichtung (DE-Markt mit 60k+ Reviews bei umliegenden Camper-Apps, aber Wohnwagen-Leveler haben max. 63 Reviews → Marktlücke)
- **Sekundärer Use-Case:** Heimwerker (Wasserwaage, Regal aufhängen, Gerät ausrichten)
- **Tertiärer Use-Case:** Foto-Stative (Kamera-Modus mit hoher Toleranz)

---

## 2. Marktrecherche-Belege (für Marketing-Texte)

**DE Wohnwagen-Leveling-Nische ist quasi leer:**
| App | Preis | Reviews |
|---|---|---|
| LevelMate | €2,99 | 1 |
| Caravan-Assistant | €4,99 | 12 |
| Wohnmobil Level Assist | Gratis | 63 ← Marktführer |
| Camping Level Pro | €1,79 | 9 |

**Drumherum riesige Camper-Audience:**
| App | Reviews |
|---|---|
| Stellplatz-Radar (PROMOBIL) | 43.743 |
| Campercontact | 9.783 |
| Camping App Womo Wowa Van | 7.632 |
| park4night | 7.390 |
| StayFree Vanlife | 2.096 |

**Generische Bubble-Level zum Vergleich (Konkurrenz für Heimwerker):**
- Bubble Level for iPhone (Lemondo) — 111.483 Reviews, US Free
- Pocket Bubble Level XXL — 15.139 Reviews
- Bubble Level Plus+ — 14.945 Reviews

→ **Wohnwagen-Markt erobern, Heimwerker als Bonus-Reichweite.**

---

## 3. Code-Stand-Inventur (verifiziert am 2026-04-26)

### Vorhandene Architektur
```
Van_Leveling/Van_Leveling/
├── Van_LevelingApp.swift              ← App-Entry
├── ContentView.swift                  ← Haupt-UI mit Profile-Picker
├── LevelProfile.swift                 ← 6 Profile-Definitionen
├── LevelViewModel.swift               ← @Observable, Kalibrierung, Sound, Watch-Throttle
├── MotionManager.swift                ← CoreMotion (60 Hz) + CoreLocation Heading
├── BubbleLevelView.swift              ← Klassische Libelle (rund, mit Tolerance-Ring)
├── LevelBarsView.swift                ← Roll/Pitch als Balken-Anzeige
├── CaravanGuideView.swift             ← Top-Down-Diagramm mit Edge-Highlights
├── OnboardingView.swift               ← 5-Page Onboarding
├── SettingsView.swift                 ← Settings
├── WatchConnectivityManager.swift     ← Sendet 14 Felder zur Watch
├── PrivacyInfo.xcprivacy              ← Privacy Manifest ✓
└── Assets.xcassets

iLevelX Watch Watch App/               ← Watch-App (491-Line ContentView!)
├── iLevelX_WatchApp.swift
├── ContentView.swift                  ← Watch-Hauptview
├── WatchConnectivityReceiver.swift
└── WatchHeadingManager.swift          ← Watch-eigener Kompass

iLevelX Watch/                         ← Vermutlich ALTE Watch-Version (klären!)
├── WatchApp.swift
├── WatchLevelView.swift
└── WatchConnectivityReceiver.swift
```

### Aktueller LevelProfile-Stand
```swift
static let all: [LevelProfile] = [
    .general,    // "Allgemein", icon: scope, tol 0.5°, FREE  ← bereits dein "generischer Wasserwaage-Modus"
    .caravan,    // "Wohnwagen", icon: car.side.fill, tol 1.0°, FREE
    .camera,     // "Kamera", icon: camera.fill, tol 0.3°, PRO-only ← einziges Pro-Profile
    .appliance,  // "Gerät", icon: washer.fill, tol 2.0°, FREE
    .shelf,      // "Regal", icon: rectangle..., tol 0.5°, FREE, single-axis
    .billiard    // "Billard", PRO-only, tol 0.1° ← FLIEGT RAUS (entschieden 2026-04-26)
]
```

### Wichtige Beobachtung
**Der "generische Wasserwaage-Modus", den du hinzufügen wolltest, existiert bereits als `.general`** (Default beim ersten Start). Du brauchst ihn nicht neu zu bauen — nur das **Onboarding-Wording schärfen**, dass User verstehen, dass "Allgemein" die klassische Wasserwaage ist.

### `isProVersion = true` ist hardcoded
```swift
// LevelViewModel.swift:24
var isProVersion: Bool = true  // Monetization (Pro IAP not yet active — all features unlocked in v1.0)
```
→ **StoreKit-IAP fehlt vollständig.** Vor Submit unverzichtbar.

---

## 4. Was zum Launch noch fehlt

### Code-Änderungen
| # | Was | Aufwand | Datei(en) |
|---|---|---|---|
| 1 | **Billard-Profile entfernen** | 5 Min | `LevelProfile.swift:82-93` (komplettes static let billiard) + `LevelProfile.swift:95-97` (aus `.all` entfernen) |
| 2 | **Onboarding-Page-3 Text anpassen** (kein Billard mehr, "Allgemein" als generische Wasserwaage hervorheben) | 10 Min | `OnboardingView.swift:23-25` |
| 3 | **Winkelmesser-Modus** als separater Tab/Mode-Switch (nicht als Profile!) — zeigt absolute Grad statt Libelle, mit Hold-Funktion | 0,5–1 Tag | Neuer View `InclinometerView.swift` + Tab-Switch in `ContentView.swift` |
| 4 | **StoreKit-IAP** für Camera-Profile als Pro-Lock | 1–2 Tage | Neue Datei `StoreKitManager.swift`, `LevelViewModel.isProVersion` an StoreKit binden, Paywall-Sheet |
| 5 | **Watch-Verzeichnis aufräumen** — `iLevelX Watch/` (alt?) vs. `iLevelX Watch Watch App/` (491 Zeilen, vermutlich aktuell) klären, ggf. alte Version löschen | 30 Min | beide Watch-Verzeichnisse |
| 6 | **App Icon** im Assets ergänzen (`Logo/4.svg` als Source) | 30 Min | `Assets.xcassets/AppIcon.appiconset/` |

### Listing & Submit
| # | Was | Aufwand |
|---|---|---|
| 7 | **App Store Connect Setup** (Bundle ID, Capabilities, App Privacy) | 1 Std |
| 8 | **Listing-Texte schreiben** (Name, Subtitle DE/EN, Description, Keywords) | 1–2 Std |
| 9 | **Screenshots produzieren** (6–8 iPhone + 3–5 Apple Watch) | 0,5–1 Tag |
| 10 | **TestFlight Beta** (5–10 Camper-Forum-Tester) | 1 Woche kalendarisch |
| 11 | **Submit + Apple Review** | 1–3 Tage warten |

**Realistisch von heute bis live: 2–3 Wochen** (5–7 Tage aktive Entwicklung + 1 Woche TestFlight + Review-Wartezeit).

---

## 5. Offene Entscheidungen (vor Code-Arbeit klären)

### IAP-Strategie
- **Variante A:** Free + One-Time-IAP **€2,99–€4,99** für „Pro" (entsperrt Camera-Profile + ggf. weitere Features wie Watch-Komplikation, Custom-Toleranzen, Mess-Snapshot speichern, Themes)
- **Variante B:** Free + Subscription €0,99/Monat oder €4,99/Jahr
- **Variante C:** Paid-only €1,99 (klassisches Tools-Modell, kein IAP)
- **Empfehlung:** Variante A (One-Time, Camper-Markt erwartet One-Time-Purchases laut Reviews der Konkurrenz)

### Pro-Feature-Umfang
Aktuell ist nur `camera` Pro-only. Optionen für Erweiterung:
- Apple-Watch-Komplikation als Pro
- Custom-Toleranz pro Profile als Pro
- Mess-Snapshot mit Foto + Datum als Pro
- Profile-Themes / Dark Mode als Pro
- Mehrere Wohnwagen-Profile speichern (für Pärchen mit zwei Wohnwagen) als Pro

### Watch-Verzeichnis-Klärung
Welches der beiden ist die aktuelle Version?
- `iLevelX Watch/` (3 Files, älter)
- `Van_Leveling/iLevelX Watch Watch App/` (4 Files, ContentView mit 491 Zeilen)

→ Vor Code-Änderungen klären, das andere kann gelöscht werden.

### Subtitle-Optionen für App Store
A. *„Wohnwagen, Kamera, Regal & mehr"* (Use-Case-Hero)
B. *„Wasserwaage & Winkelmesser Pro"* (Funktion-Hero)
C. *„Wasserwaage für Wohnwagen & DIY"* (Hybrid — Empfehlung)
D. *„Spirit Level mit Apple Watch"* (USP-Hero)

---

## 6. Marketing-Strategie (vorbereitet, nicht aktiv)

### Audience-Vertikalen (priorisiert)
1. 🚐 **Wohnwagen** — höchster Fokus
   - Promobil-Forum, Wohnmobil-Forum.de, Campofant
   - YouTube: Tom Camp, Trekkingbude, etc.
   - ADAC Camping-Magazin
   - park4night- und camping.info-User
2. 📷 **Foto-Stative** — sekundär
   - DSLR-Forum, fotografr.de, traumflieger
   - YouTube: Calumet, Krolop & Gerst, etc.
3. 🔨 **Heimwerker** — opportunistisch (DIY ist Massenmarkt mit harter Bubble-Level-Konkurrenz)
   - DIY-YouTuber für Reviews; aber kein primärer Push

### Cold-Outreach-Plan
- Marketing muss von Sebastian kalt aufgebaut werden (kein bestehender Camper-Community-Zugang)
- Bedeutet: TestFlight-Phase nutzen, um in Wohnwagen-Foren um Beta-Tester zu bitten — die geben nach Launch organisch Reviews
- Erst Outreach an mittelgroße YouTuber (10–50k Subs), nicht direkt an die Top-Namen

---

## 7. Folge-App-Plan (nach iLevelX-Launch)

**Vergessen für jetzt:** Während iLevelX-Entwicklung KEINE Parallel-Entwicklung anderer Apps. Solo-Dev hat nicht die Bandwidth.

**Nach iLevelX-Launch (frühestens 4 Wochen Beobachtung):** Mögliche zweite App in der Camper-Familie:
- **iCheckX** — Wohnwagen-Checkliste vor/nach Fahrt (kleinster Scope, S–M Aufwand, klare Funktion)
- alternativ: **iSpaceX** — eigenes Stellplatz-Tagebuch (M Aufwand, MapKit/CoreLocation/CloudKit)
- alternativ: **iWindX** — Wind/Sturm-Warnung relativ zur Wohnwagen-Ausrichtung (M Aufwand, WeatherKit, Synergie zu iLevelX)

Die volle Liste mit 50 Konzepten und Marktdaten liegt in [`../Recherche_Apps/`](../Recherche_Apps/) — Dashboard via `open ../Recherche_Apps/dashboard.html`.

---

## 8. Wenn du wieder einsteigst — wähle ein Paket

**A) Code-Diff "Billard raus + Onboarding aufräumen + Winkelmesser-Skeleton"**
→ kleinste Änderungen, App bleibt funktionsfähig. ~1 Tag.

**B) App-Store-Listing schreiben (DE + EN)**
→ Subtitle, Description, Keywords, Screenshot-Reihenfolge, Pricing-Empfehlung. ~2 Stunden.

**C) StoreKit-IAP-Konzept + Code-Skeleton**
→ Welche Profile sind Pro, Pricing-Modell, StoreKit2-Setup. ~1 Tag.

**D) Watch-Verzeichnis aufräumen + Watch-App durchgehen**
→ Klären welches Watch-Verzeichnis aktuell ist, Code-Review der Watch-App.

**Empfohlene Reihenfolge:** D → A → C → B (Watch klären, Code aufräumen, IAP rein, dann Listing schreiben — Listing kommt zuletzt weil dann das finale Feature-Set bekannt ist).

---

## 9. Wenn du eine neue Session startest

Sage einfach:
> *„Lass uns bei iLevelX weitermachen — wo waren wir?"*

oder direkt:
> *„Ich will Paket A (Code-Diff) angehen."*

Dann liest Claude diese Datei und du bist sofort im Kontext.
