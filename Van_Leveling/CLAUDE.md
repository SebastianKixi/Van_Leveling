# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

This is an Xcode project — all building, running, and testing is done via Xcode or `xcodebuild`.

```bash
# Build the iOS app (simulator)
xcodebuild -project Van_Leveling.xcodeproj -scheme Van_Leveling -destination 'platform=iOS Simulator,name=iPhone 16' build

# Build the Watch app
xcodebuild -project Van_Leveling.xcodeproj -scheme "iLevelX Watch Watch App" -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)' build

# Run tests (none currently exist)
xcodebuild -project Van_Leveling.xcodeproj -scheme Van_Leveling test
```

The app is named **iLevelX** externally (App Store / UI) but the Xcode project/bundle is named `Van_Leveling`. The Watch app target is `iLevelX Watch Watch App`.

## Architecture

**iOS target** (`Van_Leveling/`): SwiftUI + `@Observable` (iOS 17+), no third-party dependencies.

```
MotionManager          CoreMotion (60 Hz pitch/roll) + CoreLocation (compass heading)
     ↓
LevelViewModel         Calibration offsets, profile selection, sound trigger, Watch throttle
     ↓
ContentView            Main screen: bubble, angle readouts, guidance, level bars, profile picker
```

Supporting views live in separate files: `BubbleLevelView`, `LevelBarsView`, `CaravanGuideView`, `OnboardingView`, `SettingsView`.

**Watch target** (`iLevelX Watch Watch App/`): Receives data from iPhone; uses compass heading from the Watch's own sensor to rotate the tilt into the user's reference frame.

```
WatchConnectivityReceiver   Receives pitch/roll/heading/profile dict from iPhone (~10 Hz)
WatchHeadingManager         Watch's own CLLocationManager heading
WatchLevelView (ContentView) 3-page TabView:
    Page 0 — level indicator (checkmark) or guidance (arrow + instruction text)
    Page 1 — top-down diagram (WatchTopDownView: edge bars for L/R/V/H)
    Page 2 — connection & app info (InfoRow grid)
```

**Watch connectivity** (`WatchConnectivityManager` ↔ `WatchConnectivityReceiver`): iPhone sends via `sendMessage` when Watch is reachable, falls back to `updateApplicationContext`. Throttled to ~10 Hz in `LevelViewModel.sendToWatchThrottled()`.

**Profiles** (`LevelProfile.swift`): Value-type structs with per-profile tolerance, instruction strings (German), and a `showPitch` flag for single-axis profiles (shelf). `isProOnly` flag exists but `isProVersion` is hardcoded `true` in v1.0 (all features unlocked).

## Key Conventions

**Angle sign convention:**
- `pitch > 0` → front tilted down (back is high → "Hinten heben")
- `roll > 0` → right side down (right is low → "Rechte Seite heben")
- Bubble floats to the *high* side: `rawX = -roll`, `rawY = +pitch`

**Watch compass rotation:** The Watch computes `delta = watchHeading - iPhoneHeading` and rotates the received pitch/roll into the user's frame using a 2D rotation matrix, so instructions remain correct regardless of how the iPhone is oriented relative to the Watch wearer.

**UI language:** All user-facing strings are in German.

**Persistence:** `UserDefaults` only — calibration offsets (`cal_pitch`, `cal_roll`) and selected profile ID (`selectedProfileID`). No Core Data or CloudKit.

**Motion updates** dispatch on a background `OperationQueue`, then hop to `@MainActor` via `Task { @MainActor in }`. All `@Observable` classes are `@MainActor`.
