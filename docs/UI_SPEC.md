# UI Specification: *What On Earth?!*

**Version:** 1.0
**Date:** 2026-03-07
**Status:** Draft
**Depends on:** PRD v1.0, TECH_SPEC v1.0

---

## Table of Contents

1. [Design Philosophy](#1-design-philosophy)
2. [Theme System](#2-theme-system)
3. [Navigation Model](#3-navigation-model)
4. [Screen Layouts](#4-screen-layouts)
5. [Shared Components](#5-shared-components)
6. [Bridge Protocol Extensions](#6-bridge-protocol-extensions)

---

## 1. Design Philosophy

The interface has two distinct contexts governed by separate design rules.

**AR context (full-screen globe)**
The globe owns the screen. UI chrome must be minimal, semi-transparent, and positioned at the periphery. Every element must be legible against both a dark starfield and a sunlit Earth below. The aesthetic is a heads-up display (HUD) — precise, numerical, purposeful. Nothing competes with the globe.

**Navigation context (2D Map, Pins, Settings)**
Standard app UI with full-opacity surfaces. Legibility and information density over drama. These screens are for managing data, not experiencing the AR view.

**Core rules:**
- No modal dialogs on the AR screen except critical safety alerts (magnetometer interference).
- No persistent bottom navigation bar — the globe is always full-screen.
- One-handed operation: all primary actions reachable from the bottom-right corner.
- Controls reveal on demand; the default AR view is as uncluttered as possible.
- All screens support the active theme; the globe annotation colors are fixed in V1 (see §2.4).

---

## 2. Theme System

### 2.1 Architecture

Themes are implemented as named `AppTheme` objects registered in a central `AppThemeRegistry`. Each `AppTheme` provides a complete `AppTokens` extension applied to Flutter's `ThemeData` via `ThemeData.extension<AppTokens>()`.

Adding a new theme requires only two steps:
1. Define a new `const AppTheme(...)` with a full set of `AppTokens` in `lib/shared/theme.dart`.
2. Add it to `AppThemeRegistry.themes`.

No other code changes are required. The Settings theme picker discovers all registered themes automatically.

```dart
// lib/shared/theme.dart

@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  // --- Surfaces (non-AR screens) ---
  final Color surfacePrimary;    // Main background (Settings, Pin List, etc.)
  final Color surfaceSecondary;  // Card and panel backgrounds
  final Color surfaceOverlay;    // Semi-transparent overlays (Status Bar, Control Panel)

  // --- HUD (AR overlay layer) ---
  final Color hudPrimary;        // Primary HUD text, lines, tape, reticle
  final Color hudSecondary;      // Secondary / lower-importance readouts
  final Color hudWarning;        // Warning state (e.g., low FPS, stale data)
  final Color hudDanger;         // Critical / error state (e.g., mag interference)
  final Color hudBackground;     // Semi-transparent label backing

  // --- Interactive elements ---
  final Color fabBackground;
  final Color fabIcon;

  // --- Status indicators ---
  final Color statusLive;        // Live position source
  final Color statusEstimated;   // TLE / estimated fallback
  final Color statusOffline;     // No connectivity

  // --- Typography ---
  final String hudFontFamily;    // Monospace font for HUD numerics
  final double hudFontSize;      // Base size for HUD numeric readouts

  // --- Borders / dividers ---
  final Color borderPrimary;

  const AppTokens({required ...});

  @override
  AppTokens copyWith({...}) => ...;

  @override
  AppTokens lerp(AppTokens? other, double t) => ...;
}

class AppTheme {
  final String id;
  final String displayName;
  final AppTokens tokens;
  const AppTheme({required this.id, required this.displayName, required this.tokens});
}

class AppThemeRegistry {
  static const List<AppTheme> themes = [
    AppThemes.night,
    AppThemes.dark,
    AppThemes.starWars,
    AppThemes.starTrek,
    // Add new themes here — no other changes needed.
  ];

  static AppTheme find(String id) =>
      themes.firstWhere((t) => t.id == id, orElse: () => AppThemes.night);
}
```

The active theme ID is persisted in shared preferences under the key `ui_theme_id`. Default: `night`.

### 2.2 Token Reference

| Token | Role |
|---|---|
| `surfacePrimary` | Background for full-screen non-AR screens |
| `surfaceSecondary` | Cards, list tiles, sheet backgrounds |
| `surfaceOverlay` | 70% opacity overlay panels on the AR view |
| `hudPrimary` | Heading tape, pitch ladder, reticle, primary data labels |
| `hudSecondary` | FPS counter, secondary data labels |
| `hudWarning` | Amber warning state |
| `hudDanger` | Red critical / error state |
| `hudBackground` | Semi-transparent backing behind HUD text blocks |
| `fabBackground` | Speed-dial FAB background |
| `fabIcon` | Speed-dial FAB icon color |
| `statusLive` | Live position dot and label |
| `statusEstimated` | TLE / estimated position dot and label |
| `statusOffline` | No-connectivity indicator |
| `hudFontFamily` | Monospace typeface for all HUD numeric readouts |
| `hudFontSize` | Base size (pt) for HUD numerics; secondary items use `hudFontSize - 2` |
| `borderPrimary` | Dividers, panel outlines |

### 2.3 Named Themes

| Token | `night` | `dark` | `starwars` | `startrek` |
|---|---|---|---|---|
| Display name | Night | Dark | Star Wars | Star Trek |
| Aesthetic | Deep space blue | OLED black | Rebel gold on void black | LCARS orange/blue |
| `surfacePrimary` | `#0A0E1A` | `#000000` | `#0A0A0A` | `#1A0A00` |
| `surfaceSecondary` | `#141927` | `#111111` | `#141414` | `#260E00` |
| `surfaceOverlay` | `#0A0E1AB3` | `#000000B3` | `#0A0A0AB3` | `#1A0A00B3` |
| `hudPrimary` | `#4DD9FF` | `#FFFFFF` | `#FFD700` | `#FF9900` |
| `hudSecondary` | `#8BB8C8` | `#AAAAAA` | `#C8A800` | `#CC6600` |
| `hudWarning` | `#FFB340` | `#FFB340` | `#FF8C00` | `#FFCC00` |
| `hudDanger` | `#FF3B30` | `#FF3B30` | `#FF0000` | `#FF3B30` |
| `hudBackground` | `#00000099` | `#00000099` | `#00000099` | `#00000099` |
| `fabBackground` | `#4DD9FF` | `#FFFFFF` | `#FFD700` | `#FF9900` |
| `fabIcon` | `#0A0E1A` | `#000000` | `#0A0A0A` | `#1A0A00` |
| `statusLive` | `#34C759` | `#34C759` | `#34C759` | `#34C759` |
| `statusEstimated` | `#FFB340` | `#FFB340` | `#FFD700` | `#FFCC00` |
| `statusOffline` | `#8E8E93` | `#8E8E93` | `#8E8E93` | `#8E8E93` |
| `hudFontFamily` | `JetBrainsMono` | `JetBrainsMono` | `JetBrainsMono` | `JetBrainsMono` |
| `hudFontSize` | `11.0` | `11.0` | `11.0` | `11.0` |
| `borderPrimary` | `#1E2A3A` | `#222222` | `#2A2200` | `#331500` |

> `B3` suffix denotes 70% opacity (hex alpha `0xB3` = 179/255).

**Font:** `JetBrainsMono` (monospaced, high legibility at small sizes, open-source). Add via `google_fonts` package or as a bundled asset in `assets/fonts/`. All four themes use the same HUD font; only colors differ.

### 2.4 Globe Annotation Colors (V1 — Fixed)

Globe annotation layer colors (country borders, coastlines, city labels) are defined in `web_globe/src/layers.js` and are not yet theme-aware. They are fixed in V1 for legibility against the satellite imagery base map. Making them respond to the active theme via a bridge message is a V2 enhancement.

| Layer | Color | Opacity |
|---|---|---|
| Country borders | White `#FFFFFF` | 70% |
| Coastlines | Light blue `#A0C8FF` | 80% |
| Cities (point) | White `#FFFFFF` | 100% |
| City labels | White `#FFFFFF` | 90%, outline `#000000` 60% |
| Rivers & lakes | Pale blue `#7ABAFF` | 60% |

---

## 3. Navigation Model

Navigation is driven by a **speed-dial FAB** pinned to the bottom-right of the AR View. There is no persistent bottom navigation bar. The AR view is the home screen and is always the root of the navigation stack.

### 3.1 Speed-Dial NAV FAB

**Closed state:** Single circular FAB (56 dp) showing a grid icon.
**Open state:** FAB icon changes to ✕; three secondary action FABs (40 dp) animate upward with label pills to their left.

| Button | Icon | Destination |
|---|---|---|
| Primary (always visible) | Grid / ✕ | Toggle open / close |
| Secondary 1 | Globe-with-crosshair | 2D Map View |
| Secondary 2 | List with pin | Pin List |
| Secondary 3 | Gear | Settings |

**Behavior:**
- Tapping outside the expanded FAB collapses it.
- The button for the currently active destination is tinted `hudPrimary`.
- 2D Map, Pin List, and Settings push onto the navigation stack; the system back gesture / button returns to AR.
- On the AR View itself, the primary FAB has no active-destination highlight (AR is the implicit home).

**Animation:** Secondary FABs scale from 0→1 and fade in, staggered 60 ms apart, animating upward from the primary button. Reverse on collapse.

### 3.2 Controls Button

A rectangular pill button (`⌃  Controls`) positioned in the **bottom-left** of the AR View. Always visible. Tapping opens the Control Panel (§5.3) as a downward-anchored overlay.

On the 2D Map View the Controls button is also present; the camera row is hidden since the camera is inactive in that mode.

---

## 4. Screen Layouts

### 4.1 AR View

Full-screen composited view. Flutter rendering layers (bottom to top):

```
Layer 1 (bottom) : CameraPreview — full-screen live feed
                   OR black fill when camera OFF (CesiumJS skybox active)
Layer 2           : InAppWebView — CesiumJS globe, transparent WebGL canvas
Layer 3           : Telemetry HUD — Flutter CustomPaint (§5.2)
Layer 4 (top)     : UI chrome — Status Bar, Controls button, NAV FAB
```

Spatial layout of chrome elements:

```
┌────────────────────────────────────────┐
│  [●══ Status Bar ═════════════════════]│  ← top, full-width pill (§5.1)
│                                        │
│   ╔══ Heading tape ══╗   FPS: 58      │
│   ║  ...235 240 245..║                 │
│   ╠════════════════════════════════════╣
│   ║                                    ║
│   ║  +20°──────────                   ║
│   ║  +10°────                         ║  ← Pitch ladder (§5.2)
│   ║    ──⊕──  (reticle)               ║
│   ║  -10°────                         ║
│   ║  -20°──────────                   ║
│   ║                                    ║
│   ╠════════════════════════════════════╣
│   ║  LAT  12.345°N    VEL  7.66 km/s  ║
│   ║  LON -98.762°W    SRC ● ISS Live  ║  ← data strip (§5.2)
│   ║  ALT  420.1 km    AGE  2s         ║
│   ║  HDG  247°        PCH +12° ROL +3°║
│   ╚════════════════════════════════════╝
│                                        │
│  [⌃ Controls]           [NAV FAB  ⊞] │  ← bottom chrome
└────────────────────────────────────────┘
```

The HUD (layers 3) is rendered only when the Telemetry HUD setting is ON (default: ON). The Status Bar and FABs (layer 4) are always rendered.

### 4.2 2D Map View

Same CesiumJS WebView with `SET_MODE {mode: 'map'}` active. Camera is not used.

- Status Bar visible at top (same as AR).
- Controls button visible; camera row hidden in Control Panel.
- NAV FAB visible; Map button highlighted.
- Telemetry HUD hidden (orientation data is irrelevant in 2D mode).
- ISS ground track: a CesiumJS `Polyline` entity showing the next 90-minute orbital path.
- ISS footprint: a semi-transparent `Ellipse` entity showing the current ground-level viewing circle (~2,200 km radius at 400 km altitude, 10° min elevation).
- User can pan and zoom the 2D map freely (this is the only view with user-controlled zoom).

### 4.3 Pin List

Standard scrollable list:

- Each row: icon (themed color) · pin name (body) · next pass countdown ("in 23 min" / "in 4 h 12 m") · chevron.
- Sorted: next pass time ascending (soonest first).
- Empty state: "No pins yet. Tap any location on the globe or map to add one."
- FAB (bottom-right, independent of NAV FAB): "+" — opens 2D Map View in pin-placement mode.
- Swipe-to-delete on each row (with confirmation).

### 4.4 Pin Detail

Pushed from Pin List row tap or globe entity tap.

- Header: pin name (inline editable), selected icon (tappable to change).
- Note field: multi-line, inline editable, placeholder "Add a note…".
- **Next Pass card:** date/time (local + UTC), max elevation (°), pass duration.
- **Upcoming passes list:** up to 5 subsequent passes, compact rows.
- "Delete Pin" destructive button at bottom with confirmation dialog.
- Save is automatic on field blur (no explicit Save button).

### 4.5 Add Pin (Bottom Sheet)

Slides up from bottom after `MAP_TAP` bridge message. Half-height sheet.

- **Coordinate display:** "12.345° N, 98.762° W" — non-editable, styled as caption.
- **Name field:** autofocused, "Location name" placeholder, 100-character limit.
- **Note field:** optional, "Add a note" placeholder.
- **Icon picker:** 5 icon options in a horizontal row; selected icon has `hudPrimary` border ring.
- **"Add Pin"** (primary, `fabBackground` fill) / **"Cancel"** (text button).

### 4.6 Settings

Grouped list using `surfaceSecondary` card style per section.

| Section | Items |
|---|---|
| **Display** | Theme picker (scrollable horizontal card row showing all registered themes with name and accent color swatch); Telemetry HUD toggle (on/off) |
| **Position Source** | Segmented control or radio group: Live ISS Feed / TLE Propagation / Static; when Static selected: lat/lon/alt entry fields |
| **Layers** | Same layer toggle switches as Control Panel; changes sync bidirectionally |
| **Tile Cache** | Cache size used, last sync timestamp, per-layer coverage (green tick / amber warning / red X); "Re-download All" action; "Clear Cache" destructive action |
| **Account** | Sign in / Sign out via Supabase auth; sync status ("Last synced 5 min ago") |
| **Sensor** | "Recalibrate magnetometer" → navigates to Calibration screen; last calibration date and confidence % |
| **Power** | Power-saving mode toggle; threshold slider (5–50%, default 20%) |
| **About** | App version; Open Data Registry (scrollable list of data sources with license); open-source licenses; data attribution |

### 4.7 Onboarding

Multi-step `PageView`. Progress shown as pill dots at the bottom.

| Step | Title | Content | Skippable |
|---|---|---|---|
| 1 | Welcome | App purpose, confirm Live ISS Feed is active and no configuration needed. Single CTA: "Get Started". | No |
| 2 | Download Map Data | Layer checkboxes with estimated size per layer; total size estimate; "Download" primary button + progress bar during download; "Skip for now" text link (shows warning: offline mode limited). | Yes |
| 3 | Calibrate Compass | Animated device silhouette performing figure-8; live heading stability ring; confidence percentage. "Done" enabled at ≥ 80%. "Skip for now" text link (shows warning: AR accuracy reduced). | Yes |

On subsequent launches with incomplete onboarding: a non-blocking banner ("Finish setup →") appears at the top of the AR View above the Status Bar. Tapping resumes from the last incomplete step.

### 4.8 Calibration

Accessible from Onboarding step 3 and Settings → Sensor.

- Full-screen dark surface.
- Animated device silhouette (loop): figure-8 motion in 3D, 4-second cycle.
- Instruction text: "Move your device in a slow figure-8 pattern."
- **Confidence ring:** circular progress indicator (0–100%). Fills as magnetometer samples improve ellipsoid fit.
- **Confidence label:** percentage inside the ring.
- Ring color: `hudDanger` 0–39%, `hudWarning` 40–79%, `hudPrimary` 80–100%.
- "Done" button: enabled when confidence ≥ 80%, disabled (greyed) below.
- "Restart" text button: resets collected samples and restarts the capture.

---

## 5. Shared Components

### 5.1 Status Bar

A compact, semi-transparent pill bar pinned to the **top** of the AR View and 2D Map View. Always visible. Not interactive (tap anywhere on it has no effect in V1).

```
┌─────────────────────────────────────────────────────┐
│  ●  ISS Live  ·  2s ago  ·  [wifi]  ·  [map] Stale │
└─────────────────────────────────────────────────────┘
```

| Element | Description |
|---|---|
| Source dot | Filled circle: `statusLive` / `statusEstimated` / `statusOffline` |
| Source label | "ISS Live" / "TLE Estimated" / "Static" |
| Age | "Xs ago" — hidden when source is Static or age < 1s |
| Connectivity icon | System wifi/cell icon when online; ⚠ icon in `statusOffline` when offline |
| Tile freshness | Hidden unless tile cache is > 30 days stale; shows map icon + "Stale" in `hudWarning` |

**Dimensions:** Height 28 dp · horizontal padding 12 dp · corner radius 14 dp (fully rounded pill) · background `surfaceOverlay` · top margin 12 dp from safe area.

**Typography:** `hudFontFamily`, `hudFontSize - 1` pt, color `hudPrimary`.

### 5.2 Telemetry HUD

Fighter-jet style heads-up display rendered as a Flutter `CustomPaint` layer directly over the globe. Visibility controlled by Settings → Display → Telemetry HUD (default: ON).

All HUD text uses `hudFontFamily` at `hudFontSize` (11 pt). Secondary labels (`FPS`, axis suffixes) use `hudFontSize - 2` (9 pt). All colors from the active `AppTokens`.

#### Heading Tape (top-center)

- Horizontal scrolling tape spanning 60° of arc, centered on current `headingDeg`.
- Major tick every 10° labeled; minor tick every 5°.
- Cardinal letters at 0° (N), 45° (NE), 90° (E), 135° (SE), 180° (S), 225° (SW), 270° (W), 315° (NW).
- Current heading shown in a downward-pointing notch above the tape center.
- Color: `hudPrimary`. Background: `hudBackground` strip behind the tape.

#### Pitch Ladder (left edge)

- Horizontal lines at ±5° increments from current pitch, labeled at ±10°, ±20°, ±30°.
- Lines shorten toward center (±5° lines are half the length of ±30° lines).
- Color: `hudPrimary` at 60% opacity.

#### Roll Indicator (top-center, above heading tape)

- Small arc (±60° visible range) with a moving pointer showing `rollDeg`.
- Pointer color: `hudPrimary`; turns `hudWarning` when |roll| > 30°.
- Tick marks at 0°, ±10°, ±20°, ±30°, ±45°, ±60°.

#### Reticle (center)

- Boresight crosshair: four 8 dp arms with a 12 dp gap at center.
- Color: `hudPrimary` at 50% opacity.

#### Data Strip (bottom)

Two columns of labeled readouts, left and right, above the Controls button and NAV FAB.

| Label | Source | Notes |
|---|---|---|
| `LAT` | `OrbitalPosition.latDeg` | e.g., `12.345°N` |
| `LON` | `OrbitalPosition.lonDeg` | e.g., `-98.762°W` |
| `ALT` | `OrbitalPosition.altKm` | e.g., `420.1 km` |
| `HDG` | `DeviceOrientation.headingDeg` | e.g., `247°` |
| `PCH` | `DeviceOrientation.pitchDeg` | e.g., `+12°` |
| `ROL` | `DeviceOrientation.rollDeg` | e.g., `+3°` |
| `VEL` | Live API velocity field | e.g., `7.66 km/s`; blank when source is TLE or Static |
| `SRC` | `PositionSourceType` | Colored dot + `ISS Live` / `TLE Est.` / `Static` |
| `AGE` | Age of last position fix | e.g., `2s`; hidden when source is Static |

Background: `hudBackground` rounded rect behind each column. Label color: `hudSecondary`. Value color: `hudPrimary`.

#### FPS Counter (top-right)

- `FPS: 58` in `hudSecondary` at `hudFontSize - 2`.
- Turns `hudWarning` below 25 fps; turns `hudDanger` below 15 fps.
- Sourced from `FRAME_RATE` bridge messages (reported every 5 s per TECH_SPEC §8.2).

#### Magnetometer Interference Banner

Displayed between the heading tape and pitch ladder when `DeviceOrientation.reliable == false`.

```
┌────────────────────────────────────────────┐
│  ⚠  MAG INTERFERENCE — TAP TO RECALIBRATE │
└────────────────────────────────────────────┘
```

- Full-width, `hudBackground` backing, text in `hudDanger`.
- Tapping navigates to Calibration screen.
- Dismissed automatically when `reliable` returns `true`.

### 5.3 Layer Control Panel

Slides down from the Controls button as a Flutter overlay. Left-anchored, positioned directly above the Controls button.

```
┌─────────────────────────────────────────┐
│  Camera                    ●────── ON  │   ← always first; hidden in 2D Map mode
├─────────────────────────────────────────┤
│  Relief shading            ●────── ON  │
│  Cloud cover               ●────── ON  │
│  Country borders           ●────── ON  │
│  Coastlines                ●────── ON  │
│  Cities & labels           ●────── ON  │
│  Rivers & lakes            ─────── OFF │
└─────────────────────────────────────────┘
```

**Dimensions:** Width 220 dp · `surfaceOverlay` background · corner radius 12 dp · row height 44 dp · internal padding 12 dp.

**Toggle switches:** Active color `hudPrimary`; inactive color `borderPrimary`.

**Persistence:** All layer toggle states (except Camera, which resets to ON on each cold launch) are saved in shared preferences and restored on next launch.

**Camera toggle behavior (see also §6.1):**
- **OFF:** `CameraController.pausePreview()` → send `SET_SKYBOX {enabled: true}` → CesiumJS enables star skybox + sets `scene.backgroundColor` to opaque black.
- **ON:** send `SET_SKYBOX {enabled: false}` → CesiumJS disables star skybox + restores `scene.backgroundColor` to transparent → `CameraController.resumePreview()`.

**Base map row:** Not shown in the panel. The base imagery layer is always active and has no user toggle in V1.

### 5.4 Speed-Dial NAV FAB

Implemented with a `FloatingActionButton` and `AnimatedList` (or a dedicated `flutter_speed_dial` package).

| Property | Value |
|---|---|
| Primary FAB diameter | 56 dp |
| Secondary FAB diameter | 40 dp |
| Gap between secondary FABs | 8 dp |
| Label pills | Appear to the left of each secondary FAB, `surfaceOverlay` background, `hudPrimary` text |
| Open animation | Each secondary FAB scales 0→1 + fades in, staggered 60 ms apart, upward from primary |
| Close animation | Reverse of open |
| Tap outside | Collapses the FAB |

Active-destination highlight: secondary FAB background changes to `hudPrimary`, icon to `fabIcon` color.

---

## 6. Bridge Protocol Extensions

The following messages extend the protocol defined in `TECH_SPEC §8`. They are additions only — no existing messages are modified.

### 6.1 Flutter → CesiumJS

| Message | Payload | Trigger | Description |
|---|---|---|---|
| `SET_SKYBOX` | `{enabled: bool}` | Camera toggle | Enable or disable the CesiumJS star skybox and adjust `scene.backgroundColor` accordingly |

**JS handler (`web_globe/src/main.js`):**

```javascript
handlers['SET_SKYBOX'] = ({ enabled }) => {
  viewer.scene.skyBox.show = enabled;
  viewer.scene.backgroundColor = enabled
    ? new Cesium.Color(0, 0, 0, 1)   // opaque black — stars render against solid background
    : new Cesium.Color(0, 0, 0, 0);  // fully transparent — camera feed shows through
};
```

**Initialization change required (`TECH_SPEC §3.2`):**

The original TECH_SPEC configuration sets `skyBox: false` in the `Viewer` constructor, which prevents the skybox asset from loading. To support runtime toggling, change the initialization to use Cesium's default skybox, then immediately hide it:

```javascript
// web_globe/src/main.js — Viewer constructor
const viewer = new Cesium.Viewer('cesiumContainer', {
  // Remove: skyBox: false
  // The default skyBox uses Cesium's built-in star catalog cube map.
  // It is hidden immediately below and only shown when camera is toggled off.
  skyAtmosphere: false,
  // ... all other existing options unchanged ...
});

// Hide skybox at startup (camera is ON by default)
viewer.scene.skyBox.show = false;
```

This ensures the star catalog cube map is loaded and GPU-resident, allowing it to appear instantly when the camera is toggled off — with no additional network requests and no reload.

**Accuracy note:** Cesium's built-in skybox is a static cube map of the real star catalog rendered from Earth's approximate position. It is orientation-aware — the star field rotates correctly as the device moves. It does not account for the ~400 km altitude offset of the ISS (negligible for a star-field effect) or time-of-day precession. For the purposes of this app, it is visually and practically accurate.

---

*What On Earth?!* | UI Specification v1.0
