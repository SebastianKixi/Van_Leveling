# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

This is an Xcode project — all building, running, and testing is done via Xcode or `xcodebuild`.

```bash
# Build the iOS app (simulator)
xcodebuild -project Van_Leveling.xcodeproj -scheme "iLevelX" -destination 'platform=iOS Simulator,name=iPhone 17' build

# Build the Watch app
xcodebuild -project Van_Leveling.xcodeproj -scheme "iLevelX Watch Watch App" -destination 'platform=watchOS Simulator,name=Apple Watch Ultra 3 (49mm)' build

# Run tests (none currently exist)
xcodebuild -project Van_Leveling.xcodeproj -scheme "iLevelX" test
```

The app is named **iLevelX** externally (App Store / UI) but the Xcode project/bundle is named `Van_Leveling`. The iOS scheme is `iLevelX`. The Watch app target is `iLevelX Watch Watch App`.

## Architecture

**iOS target** (`Van_Leveling/`): SwiftUI + `@Observable` (iOS 17+), no third-party dependencies. Deployment target iOS 26+.

```
MotionManager          CoreMotion (60 Hz pitch/roll + gravity vector) + CoreLocation (compass heading)
     ↓
LevelViewModel         Calibration offsets, profile selection, sound trigger, Watch throttle
     ↓
ContentView            TabView mit drei Tabs:
                       - ProfileLevelTab (Hochformat-locked)
                       - WasserwaageView (Querformat-locked)
                       - WinkelmesserView (Querformat-locked)
```

Supporting views: `BubbleLevelView`, `LevelBarsView`, `CaravanGuideView`, `OnboardingView`, `SettingsView`, `WasserwaageView`, `WinkelmesserView`.

**Drei Modi (Tabs):**

1. **Profile** (`ProfileLevelTab` in `ContentView`): Klassischer Multi-Mode-Leveler. Bubble in der Mitte mit vertikalem Streifen links (Pitch) und horizontalem Streifen unten (Roll). GuidanceView mit Top-Down-Diagramm. Profile-Picker mit 5 Profilen (Allgemein, Wohnwagen, Kamera, Gerät, Regal). Kalibrierungs-Button. WatchHintBanner wenn Watch gekoppelt aber App nicht offen.

2. **Wasserwaage** (`WasserwaageView`): Klassische Spirit Level. iPhone auf der langen Kante in Querformat. Großes horizontales Bläschen-Vial in der Mitte. Misst nur eine Achse (Roll des iPhones, was der seitlichen Neigung der zu prüfenden Fläche entspricht).

3. **Winkelmesser** (`WinkelmesserView`): Inklinometer mit Skalen-Scheibe (Protractor) plus Pitch/Roll-Chips mit kleinen Tilt-Illustrationen. Halten + Nullen (Tare) Buttons. Messung über Gravitations-Vektor (`asin(gravityZ)` für Vorne/Hinten, `asin(gravityY)` für Links/Rechts) damit Null-Lage exakt stimmt.

**Orientierungs-Lock pro Tab** (`Van_LevelingApp.AppDelegate.orientationLock`): zentrale Steuerung in `ContentView.applyOrientation(for:)` via `onChange(of: selectedTab)`. Profile = `.portrait`, Wasserwaage/Winkelmesser = `.landscape`. Ohne expliziten Lock würde die UI beim Tilten kippen und Inhalte wären verzerrt.

**Physische-Lage-Erkennung**: Wasserwaage und Winkelmesser prüfen `abs(motion.gravityX) > 0.6` ob das iPhone auf der langen Kante steht. Falls nicht: Hint-Screen statt Mess-UI.

**Watch target** (`iLevelX Watch Watch App/`): Receives data from iPhone; uses compass heading from the Watch's own sensor to rotate the tilt into the user's reference frame.

```
WatchConnectivityReceiver   Receives pitch/roll/heading/profile dict from iPhone (~10 Hz)
WatchHeadingManager         Watch's own CLLocationManager heading
WatchRuntimeSession         WKExtendedRuntimeSession um Bildschirm wach zu halten
WatchLevelView (ContentView) 3-page TabView:
    Page 0 — level indicator (checkmark) or guidance (arrow + instruction text)
    Page 1 — top-down diagram (WatchTopDownView: edge bars for L/R/V/H)
    Page 2 — connection & app info (InfoRow grid)
```

Die Watch-App spiegelt nur den **Profile-Modus** des iPhones — Wasserwaage und Winkelmesser sind Use-Cases bei denen der User direkt aufs iPhone schaut, daher keine Watch-Anzeige.

**Watch connectivity** (`WatchConnectivityManager` ↔ `WatchConnectivityReceiver`): iPhone sendet **immer** `updateApplicationContext` als Cache plus `sendMessage` wenn die Watch reachable ist. Throttled auf ~10 Hz in `LevelViewModel.sendToWatchThrottled()`. WCSession-State (`isWatchPaired`, `isWatchAppInstalled`, `isWatchReachable`) wird in `WatchConnectivityManager` exponiert für UI-Reaktion (z.B. WatchHintBanner).

**Profiles** (`LevelProfile.swift`): Value-type structs mit per-profile Toleranz, Anweisungstexten (German), und `showPitch` Flag für einachsige Profile (shelf). `isProOnly` Flag existiert (camera ist Pro), aber `isProVersion` ist `true` hardcoded in v1.0 (StoreKit-IAP fehlt noch).

## Key Conventions

**Angle sign convention** (Profile-Modus):
- `pitch > 0` → front tilted down (back is high → "Hinten heben")
- `roll > 0` → right side down (right is low → "Rechte Seite heben")
- Bubble UND Streifen-Marker beide auf die *hohe* Seite: `rawX = -roll`, `rawY = +pitch`

**Winkelmesser Achs-Mapping**: Im Querformat ist aus Anwendersicht „Vorne/Hinten"-Neigung = `gravityZ` und „Links/Rechts"-Neigung = `gravityY`. Direkt aus Gravitation berechnet, nicht aus CMAttitude.pitch/roll.

**Watch compass rotation:** The Watch computes `delta = watchHeading - iPhoneHeading` and rotates the received pitch/roll into the user's frame using a 2D rotation matrix, so instructions remain correct regardless of how the iPhone is oriented relative to the Watch wearer.

**UI language:** All user-facing strings are in German.

**Persistence:** `UserDefaults` only — calibration offsets (`cal_pitch`, `cal_roll`), selected profile ID (`selectedProfileID`), `hideWatchHint`, `hasSeenOnboarding`. No Core Data or CloudKit.

**Motion updates** dispatch on a background `OperationQueue`, then hop to `@MainActor` via `Task { @MainActor in }`. All `@Observable` classes are `@MainActor`.

**App-Icon**: 1024×1024 PNG aus `Logo/iLevelX-icon-final.svg` (Balance Stone Libelle Lime — gekippter Stein auf Klingenkante mit Lime-Bläschen-Vial). Light/Dark/Tinted Varianten zeigen aktuell dasselbe Bild.
