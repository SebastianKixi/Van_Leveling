# iLevelX — Vorgehensplan & Wiedereinstieg

**Stand:** 2026-05-03
**Status der App:** Code ~90% fertig, **noch nicht im App Store**, kein IAP, kein Listing.
**Begleitende Recherche:** [`../Recherche_Apps/`](../Recherche_Apps/) — 50 App-Konzepte für Folge-Apps.

---

## TODOs

- [x] ~~Einheitliches Design über alle Tabs~~ (2026-05-05 abgenommen)
- [ ] **Pro-Killer-Features implementieren** (siehe Abschnitt 5):
   - Wohnwagen-Step-by-Step-Guide
   - Audio-Feedback beim Ausrichten
   - Voice-Anweisungen (deutsch)
   - Apple Watch Komplikation
   - Eigene Profile erstellen
- [ ] **StoreKit-IAP einbauen** — `isProVersion = true` ist hardcoded. Pro-Bundle €4,99 One-Time mit obigen Features locken.
- [ ] **App-Store-Listing** schreiben (DE + EN, Screenshots produzieren)
- [ ] **TestFlight-Beta** mit 5–10 Wohnwagen-Forum-Testern

---

## 1. Konzept und Positionierung (entschieden)

iLevelX ist **kein generisches Bubble-Level**, sondern ein **Multi-Mode Leveler mit drei spezialisierten Werkzeugen** (Tabs) plus Apple-Watch-Live-Anzeige.

**Drei Tabs (entschieden 2026-05-02):**
1. **Profile** — Multi-Mode mit Use-Case-Profilen (Hochformat-locked)
2. **Wasserwaage** — klassische Spirit-Level für vertikale Anwendung (Querformat-locked)
3. **Winkelmesser** — Inklinometer mit Halten + Nullen (Querformat-locked)

**Differenzierung gegenüber der Konkurrenz** (Lemondo Bubble Level: 111k US Reviews mit reiner Libelle):
- Use-Case-Profile (Wohnwagen, Kamera, Gerät, Regal) mit eigenen Anweisungstexten
- Apple-Watch-Anzeige mit Kompass-Heading-Ausgleich → User steht neben Wohnwagen, dreht Stützen, sieht Live-Anzeige aus jeder Richtung
- Drei separate Modi statt eine generische Libelle
- Kalibrierungs-Funktion ("Als Waagerecht setzen") für nicht-perfekte Untergründe

**Positionierung im App Store:**
- **Primär:** Wohnwagen-/Wohnmobil-Ausrichtung (DE-Markt mit 60k+ Reviews bei umliegenden Camper-Apps, aber Wohnwagen-Leveler haben max. 63 Reviews → Marktlücke)
- **Sekundär:** Heimwerker (Wasserwaage, Winkelmesser, Regal aufhängen, Gerät ausrichten)
- **Tertiär:** Foto-Stative (Kamera-Modus mit hoher Toleranz)

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

## 3. Aktueller Code-Stand (verifiziert am 2026-05-03)

### Architektur
```
Van_Leveling/Van_Leveling/
├── Van_LevelingApp.swift          ← App-Entry + AppDelegate für Orientierungs-Lock
├── ContentView.swift              ← TabView mit ProfileLevelTab + WatchHintBanner +
│                                    LevelStrip-Komponenten
├── WasserwaageView.swift          ← Wasserwaage-Tab (Querformat)
├── WinkelmesserView.swift         ← Winkelmesser-Tab (Querformat)
├── LevelProfile.swift             ← 5 Profile-Definitionen (kein Billard mehr)
├── LevelViewModel.swift           ← @Observable, Kalibrierung, Sound, Watch-Throttle
├── MotionManager.swift            ← CoreMotion (60 Hz pitch/roll + gravity vector)
├── BubbleLevelView.swift          ← Klassische Libelle (rund)
├── LevelBarsView.swift            ← Roll/Nicken Balken-Anzeige
├── CaravanGuideView.swift         ← Top-Down-Diagramm mit Edge-Highlights
├── OnboardingView.swift           ← 7-Page Onboarding (überarbeitet 2026-05-03)
├── SettingsView.swift             ← Settings
├── WatchConnectivityManager.swift ← isWatchPaired/Installed/Reachable exposed
├── PrivacyInfo.xcprivacy
└── Assets.xcassets                ← AppIcon Light/Dark/Tinted (Balance Stone Lime)

Van_Leveling/iLevelX Watch Watch App/
├── iLevelX_WatchApp.swift
├── ContentView.swift              ← Watch-Hauptview (3-Page TabView)
├── WatchConnectivityReceiver.swift
├── WatchHeadingManager.swift      ← Watch-eigener Kompass
└── WatchRuntimeSession.swift      ← WKExtendedRuntimeSession (Bildschirm wach)
```

### Aktueller LevelProfile-Stand
```swift
static let all: [LevelProfile] = [
    .general,    // "Allgemein", scope, tol 0.5°, FREE
    .caravan,    // "Wohnwagen", car.side.fill, tol 1.0°, FREE
    .camera,     // "Kamera", camera.fill, tol 0.3°, PRO-only
    .appliance,  // "Gerät", washer.fill, tol 2.0°, FREE
    .shelf       // "Regal", rectangle..., tol 0.5°, FREE, single-axis
]
```

### `isProVersion = true` ist hardcoded
```swift
// LevelViewModel.swift:24
var isProVersion: Bool = true  // Monetization (Pro IAP not yet active)
```
→ **StoreKit-IAP fehlt.** Vor Submit unverzichtbar wenn Camera Pro-only bleiben soll.

---

## 4. Was noch fehlt zum Launch

| # | Was | Aufwand |
|---|---|---|
| 1 | **Einheitliches Design** über alle Tabs | 0,5–1 Tag |
| 2 | **StoreKit-IAP** für Pro-Bundle (siehe 5.) | 1–2 Tage |
| 3 | **App Store Connect Setup** | 1 Std |
| 4 | **Listing-Texte** schreiben (DE + EN) | 1–2 Std |
| 5 | **Screenshots** (iPhone + Apple Watch) | 0,5–1 Tag |
| 6 | **TestFlight Beta** (Camper-Forum-Tester) | 1 Woche kalendarisch |
| 7 | **Submit + Apple Review** | 1–3 Tage warten |

**Realistisch von heute bis live: 2–3 Wochen.**

---

## 5. IAP & Pro-Feature-Umfang

**Empfehlung: Variante A — One-Time-IAP €4,99** für „Pro" (Camper-Markt erwartet One-Time-Purchases, der höhere Preis ist gerechtfertigt durch starke Killer-Features).

**Pro-Bundle (Stand 2026-05-05, noch nicht implementiert):**

1. **🎯 Wohnwagen-Step-by-Step-Guide** *(Killer für Camper)*
   Statt cm-Berechnung (würde Setup mit Wohnwagen-Maßen erfordern) eine
   live-reagierende Anleitung in Schritten:
   *„1. Stärkste Neigung zuerst: rechtes Rad auf Auffahrkeil"*
   *„2. Jetzt vorne/hinten: vordere linke Stütze ausfahren"*
   Reagiert live, gibt immer nur den nächsten konkreten Schritt vor.
   *Kein Setup nötig.* Aufwand: M.

2. **🔊 Audio-Feedback beim Ausrichten** *(Killer für Hands-Free-Use)*
   Während des Drehens piept das iPhone schneller je näher am Ziel
   (wie Geigerzähler). Bei „Level erreicht" → Erfolgs-Sound.
   Perfekt wenn man unter dem Kühlschrank/an der Stütze dreht und
   nicht hinschauen kann. Aufwand: S.

3. **🗣️ Voice-Anweisungen** *(deutsch)*
   Sprachausgabe der Korrektur-Anweisungen ergänzend zu Audio.
   *„Linke vordere Stütze anheben"* — Hände frei. Aufwand: S.

4. **⌚ Apple Watch Komplikation**
   Direkter Zugriff vom Zifferblatt — keine App-Liste durchsuchen.
   Premium-Feel für Watch-User. Aufwand: S.

5. **🛠️ Eigene Profile erstellen**
   User legt eigene Profile mit Name + Toleranz + Anweisungstexten an.
   Universal nützlich (mehrere Wohnwagen, spezifische Möbelstücke,
   Werkbank etc.). Aufwand: M.

**Verworfene Pro-Ideen (zu schwach oder zu komplex):**
- Mess-Protokoll/History + PDF-Export — zu generisch, nicht zwingend
- Stützen-Höhen-Berechnung in cm — bräuchte Setup mit Wohnwagen-Maßen
  und Position des Handys; zu komplex für v1.0
- Stellplatz-Logbuch — könnte später als v1.1-Bonus kommen
- Themes — nice-to-have, nicht kaufkritisch

**Free behält:** Alle 5 Profile (Allgemein/Wohnwagen/Kamera/Gerät/Regal)
+ Wasserwaage + **Winkelmesser** + Watch-Live-Anzeige + Kalibrierung.

→ Camera-Profil ist NICHT mehr Pro-only (entschieden 2026-05-05).
   Der Pro-Wert liegt nun in den 5 Killer-Features oben.

---

## 6. Subtitle-Optionen für App Store

A. *„Wohnwagen, Kamera, Regal & mehr"* (Use-Case-Hero)
B. *„Wasserwaage, Winkelmesser & Watch"* (Feature-Hero)
C. *„Wasserwaage für Wohnwagen & DIY"* (Hybrid — Empfehlung)
D. *„Spirit Level mit Apple Watch"* (USP-Hero)

---

## 7. Marketing-Strategie (vorbereitet, nicht aktiv)

### Audience-Vertikalen (priorisiert)
1. 🚐 **Wohnwagen** — höchster Fokus
   - Promobil-Forum, Wohnmobil-Forum.de, Campofant
   - YouTube: Tom Camp, Trekkingbude, etc.
   - ADAC Camping-Magazin
   - park4night- und camping.info-User
2. 📷 **Foto-Stative** — sekundär
   - DSLR-Forum, fotografr.de, traumflieger
3. 🔨 **Heimwerker** — opportunistisch (DIY ist Massenmarkt mit harter Konkurrenz)

### Cold-Outreach-Plan
- TestFlight-Phase nutzen, um in Wohnwagen-Foren um Beta-Tester zu bitten — die geben nach Launch organisch Reviews
- Erst Outreach an mittelgroße YouTuber (10–50k Subs), nicht direkt an die Top-Namen

---

## 8. Folge-App-Plan (nach iLevelX-Launch)

**Vergessen für jetzt:** Während iLevelX-Entwicklung KEINE Parallel-Entwicklung anderer Apps.

**Nach iLevelX-Launch (frühestens 4 Wochen Beobachtung):**
- **iCheckX** — Wohnwagen-Checkliste vor/nach Fahrt (kleinster Scope)
- alternativ: **iSpaceX** — Stellplatz-Tagebuch
- alternativ: **iWindX** — Wind/Sturm-Warnung relativ zur Wohnwagen-Ausrichtung

Volle Liste mit 50 Konzepten in [`../Recherche_Apps/`](../Recherche_Apps/).

---

## 9. Wenn du eine neue Session startest

Sage einfach:
> *„Lass uns bei iLevelX weitermachen — wo waren wir?"*

oder direkt:
> *„Ich will am einheitlichen Design arbeiten."* / *„Ich will StoreKit einbauen."* / *„Listing schreiben."*

Dann liest Claude diese Datei + `Van_Leveling/CLAUDE.md` und du bist im Kontext.
