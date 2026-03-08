# What On Earth?! — Developer Architecture Guide

> A Flutter AR app that overlays a CesiumJS globe on a live camera feed to help ISS crew identify geography in real time.

**Platforms:** iOS 16+ / Android 12+ (API 31)
**Stack:** Flutter 3.x, Dart 3.6, CesiumJS 1.138, Riverpod 3.x, Drift 2.30, satellite.js 4.1.4

---

## Table of Contents

1. [High-Level Architecture](#1-high-level-architecture)
2. [Project Structure](#2-project-structure)
3. [AR Rendering Stack](#3-ar-rendering-stack)
4. [CesiumJS Globe (web_globe/)](#4-cesiumjs-globe-web_globe)
5. [Flutter-JS Bridge](#5-flutter-js-bridge)
6. [ISS Position Tracking](#6-iss-position-tracking)
7. [Sensor Fusion Engine](#7-sensor-fusion-engine)
8. [Tile Caching System](#8-tile-caching-system)
9. [Pin / Bookmark System](#9-pin--bookmark-system)
10. [State Management (Riverpod)](#10-state-management-riverpod)
11. [Persistence Layer](#11-persistence-layer)
12. [Theming & UI Components](#12-theming--ui-components)
13. [Screens & Navigation](#13-screens--navigation)
14. [Onboarding](#14-onboarding)
15. [Build Pipeline](#15-build-pipeline)
16. [CI/CD](#16-cicd)
17. [Testing](#17-testing)
18. [Configuration & Environment](#18-configuration--environment)
19. [Data Flow Diagrams](#19-data-flow-diagrams)

---

## 1. High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Flutter App                            │
│                                                             │
│  ┌──────────┐  ┌───────────┐  ┌──────────┐  ┌───────────┐  │
│  │ Position  │  │  Sensor   │  │   Pin    │  │   Tile    │  │
│  │ Module    │  │  Fusion   │  │  Store   │  │   Cache   │  │
│  └─────┬────┘  └─────┬─────┘  └────┬─────┘  └─────┬─────┘  │
│        │              │             │              │         │
│        └──────┬───────┴─────────────┴──────────────┘         │
│               │                                              │
│        ┌──────▼──────┐                                       │
│        │   Bridge    │  CustomEvent / callHandler             │
│        │ Controller  │◄────────────────────────┐             │
│        └──────┬──────┘                         │             │
│               │                                │             │
│  ┌────────────▼───────────────────────────┐    │             │
│  │      InAppWebView (transparent)        │    │             │
│  │  ┌──────────────────────────────────┐  │    │             │
│  │  │  CesiumJS + satellite.js (JS)   │──┘    │             │
│  │  └──────────────────────────────────┘       │             │
│  └─────────────────────────────────────────────┘             │
│  ┌─────────────────────────────────────────────┐             │
│  │         CameraPreview (full-screen)          │             │
│  └─────────────────────────────────────────────┘             │
│                                                             │
│  HTTP Servers: :8080 (CesiumJS assets)  :8765 (XYZ tiles)  │
└─────────────────────────────────────────────────────────────┘
```

The app composites three layers in a Flutter `Stack`:

1. **CameraPreview** — full-screen live camera feed (bottom)
2. **InAppWebView** — transparent CesiumJS WebGL globe (middle)
3. **Flutter UI** — HUD overlay, status bar, controls (top)

Two local HTTP servers run inside the app:

| Port | Purpose | Implementation |
|------|---------|----------------|
| 8080 | Serves `assets/globe/` (CesiumJS bundle + GeoJSON) | Custom `shelf` handler in `lib/globe/globe_view.dart` |
| 8765 | Serves XYZ raster map tiles from device storage | `shelf_router` in background isolate (`lib/tile_cache/tile_server.dart`) |

---

## 2. Project Structure

```
what-on-earth/
├── lib/
│   ├── main.dart                 # Entry point, Riverpod bootstrap, TLE daemon init
│   ├── app.dart                  # MaterialApp with dynamic theming
│   ├── globe/
│   │   ├── bridge.dart           # BridgeController + message enums
│   │   └── globe_view.dart       # WebView widget + shelf HTTP server (:8080)
│   ├── position/
│   │   ├── position_source.dart  # OrbitalPosition model + PositionSource interface
│   │   ├── iss_live_source.dart  # WhereTheISS.at API polling (2s)
│   │   ├── tle_source.dart       # TLE propagation via JS bridge
│   │   ├── static_position_source.dart  # Fixed test coordinates
│   │   ├── tle_manager.dart      # TLE file fetch/cache (CelesTrak)
│   │   ├── tle_refresh_daemon.dart  # background_fetch every 6h
│   │   └── position_controller.dart # Unified stream + auto-fallback
│   ├── sensors/
│   │   ├── device_orientation.dart   # Orientation model (heading/pitch/roll)
│   │   ├── sensor_fusion.dart        # Complementary filter (α=0.98, ~50 Hz)
│   │   ├── calibration.dart          # Hard-iron/soft-iron correction
│   │   └── sensor_fusion_provider.dart  # Riverpod providers
│   ├── tile_cache/
│   │   ├── tile_server.dart      # Background isolate HTTP server (:8765)
│   │   ├── tile_database.dart    # Drift LRU metadata (tile_metadata.db)
│   │   ├── cache_manager.dart    # LRU eviction policy (3 GB default)
│   │   └── tile_downloader.dart  # Concurrent tile fetcher with progress
│   ├── pins/
│   │   ├── pin_database.dart     # Drift table (pins.db)
│   │   ├── pin_repository.dart   # CRUD + soft-delete domain layer
│   │   └── pass_calculator.dart  # Bridge round-trip for pass prediction
│   ├── screens/
│   │   ├── ar_screen.dart        # Main AR view (camera + globe + HUD)
│   │   ├── map_screen.dart       # 2D map placeholder
│   │   ├── pin_list_screen.dart  # Pin list placeholder
│   │   └── settings_screen.dart  # Theme, HUD, position source config
│   ├── onboarding/
│   │   ├── onboarding_state_manager.dart  # Bitmask progress (3 steps)
│   │   ├── onboarding_banner.dart         # Non-blocking "finish setup"
│   │   ├── calibration_screen.dart        # Figure-8 magnetometer calibration
│   │   └── onboarding_flow.dart           # Placeholder
│   └── shared/
│       ├── theme.dart              # AppTokens + 4 named themes
│       ├── theme_provider.dart     # Persisted theme selection
│       ├── telemetry_hud.dart      # CustomPaint HUD (heading tape, pitch ladder, etc.)
│       ├── hud_visibility_provider.dart  # Toggle HUD on/off
│       ├── status_bar.dart         # Source status + connectivity + age
│       ├── nav_speed_dial.dart     # FAB with 3 secondary actions
│       ├── layer_control_panel.dart  # Layer toggles (camera, relief, borders, etc.)
│       └── controls_button.dart    # "Controls" pill button
├── web_globe/
│   ├── src/
│   │   ├── main.js                # CesiumJS viewer init + bridge handlers
│   │   ├── layers.js              # Vector (Natural Earth) + raster (OSM) layers
│   │   ├── satellite_propagator.js  # SGP4 propagation + pass prediction
│   │   └── pins.js                # Pin billboard rendering
│   ├── index.html                 # Entry HTML (transparent, full-viewport)
│   ├── vite.config.js             # Vite + vite-plugin-cesium (base: '/')
│   └── package.json               # cesium 1.138.0, satellite.js 4.1.4
├── assets/
│   ├── globe/                     # Git-ignored; built by scripts/build_globe.sh
│   └── geodata/                   # Simplified Natural Earth GeoJSON (4 files)
├── scripts/
│   ├── build_globe.sh             # npm ci + vite build + case normalization
│   └── preprocess_geodata.sh      # Download + simplify Natural Earth data
├── test/                          # ~200+ unit/widget tests (35 files)
├── integration_test/              # Smoke test on iOS simulator
├── docs/
│   ├── TECH_SPEC.md               # Authoritative technical specification
│   ├── PRD.md                     # Product requirements
│   ├── PRFAQ.md                   # Press release FAQ
│   ├── UI_SPEC.md                 # UI/UX specification
│   ├── PARALLEL_PLANS.md          # Dual-agent implementation roadmap
│   └── issues/                    # WOE-001 through WOE-088 tickets
└── .github/workflows/
    ├── ci.yml                     # Build + test + iOS smoke
    └── release.yml                # Tag-triggered release (WIP)
```

---

## 3. AR Rendering Stack

The AR view is a Flutter `Stack` composited from bottom to top:

```
Layer 4:  Flutter UI Chrome
          ├── StatusBar (top center)
          ├── TelemetryHud (full-screen CustomPaint)
          ├── ControlsButton (bottom left)
          └── NavSpeedDial (bottom right)

Layer 3:  ──── transparent gap ────

Layer 2:  InAppWebView (CesiumJS globe)
          • useHybridComposition: false (Android TextureView)
          • transparentBackground: true
          • WebGL alpha enabled, HDR disabled

Layer 1:  CameraPreview (full-screen live feed)
```

**Android transparency** requires `useHybridComposition: false` (flutter_inappwebview#99). An additional JS fallback sets `document.body.style.background='transparent'` on `onLoadStop`.

**Skybox toggling**: When the camera layer is hidden, a star skybox is enabled via `SET_SKYBOX` bridge message, providing visual context against a black background.

### ARScreen Lifecycle (`lib/screens/ar_screen.dart`)

1. `initState()` sets immersive fullscreen, creates `BridgeController`
2. Awaits `bridge.globeReady` (fired by JS on `flutterInAppWebViewPlatformReady`)
3. Subscribes to `positionController.positionStream` → sends `UPDATE_POSITION` to JS
4. Subscribes to `sensorFusionEngine.orientationStream` → sends `UPDATE_ORIENTATION` to JS
5. Caches latest position + orientation → updates `hudDataProvider` for the HUD overlay
6. Monitors `layerVisibilityProvider['camera']` → toggles skybox accordingly

---

## 4. CesiumJS Globe (web_globe/)

### Vite Build

`web_globe/` is a Vite project bundling CesiumJS and satellite.js. `vite-plugin-cesium` externalises `Cesium.js` as a separate `<script>` tag; `base: '/'` ensures all asset paths are root-relative within the WebView.

```bash
# Build (from repo root)
scripts/build_globe.sh    # npm ci + vite build → assets/globe/
```

### Viewer Configuration (`src/main.js`)

- No Cesium Ion (offline-first): `Cesium.Ion.defaultAccessToken = undefined`
- All UI chrome disabled (no geocoder, home button, timeline, etc.)
- `EllipsoidTerrainProvider` (flat globe, no elevation data)
- Globe translucency enabled (`frontFaceAlpha = 1.0`)
- Initial camera at 0,0 looking straight down from ISS altitude (420 km)
- Render error recovery: auto-restarts render loop (max 5 attempts)

### Smooth Position Interpolation

Position updates from Flutter don't snap the camera. Instead:

1. `UPDATE_POSITION` sets a `_targetPosition` (lon, lat, altKm)
2. `UPDATE_ORIENTATION` (arriving at ~50 Hz) lerps the current camera position toward the target at 5% per frame
3. First position snaps immediately if camera is at the default location

This produces smooth visual tracking at ISS ground speed (~7.7 km/s).

### Layer System (`src/layers.js`)

**Vector layers** (Natural Earth GeoJSON, served from `:8080/geodata/`):

| Layer ID | Source | Style |
|----------|--------|-------|
| `borders` | `ne_10m_admin_0_countries.geojson` | Yellow polylines (polygon outlines extracted to avoid CesiumJS crash) |
| `coastlines` | `ne_10m_coastline.geojson` | Cyan polylines |
| `lakes` | `ne_10m_lakes.geojson` | Dark blue polygons (`arcType: GEODESIC` to fix subdivision crash) |
| `cities` | `ne_10m_populated_places.geojson` | White 4px dots; labels for cities >1M pop, distance-scaled |

**Raster layers** (XYZ tiles from `:8765` or online fallback):

| Layer ID | Source | Notes |
|----------|--------|-------|
| `base` | Local tiles or `tile.openstreetmap.org` fallback | Max zoom 5 (local) / 6 (online) |
| `relief` | Local tiles only | Hidden by default |

Layer visibility is controlled via `TOGGLE_LAYER` bridge messages; each layer is stored in `layersRegistry` keyed by string ID.

### Pin Rendering (`src/pins.js`)

Pins are rendered as `Billboard` + `Label` entities in a `CustomDataSource`. Each `SYNC_PINS` message clears and re-renders all pins:

- **Billboard**: 16x16 SVG circle (5 colors by `iconId`: white, amber, red, green, blue)
- **Label**: Pin name, 11px sans-serif, positioned above billboard, visible within 15M meters
- **Depth test disabled**: pins always render in front of the globe

### Pass Calculation (`src/satellite_propagator.js`)

`calculateNextPass(lat, lon)` scans 48 hours ahead in 60-second steps:

1. Propagates ISS position via SGP4 at each timestep
2. Computes look angles from the observer's ground position
3. A pass starts when elevation exceeds 10 degrees
4. Tracks maximum elevation and duration
5. Returns `{ passStartUtc, maxElevationDeg, passDurationSeconds }` or null

---

## 5. Flutter-JS Bridge

All communication between Flutter and CesiumJS goes through `BridgeController` (`lib/globe/bridge.dart`).

### Flutter → JS (OutboundMessage)

```dart
bridge.send(OutboundMessage.updatePosition, position.toJson());
```

This calls `evaluateJavascript` to dispatch:
```javascript
window.dispatchEvent(new CustomEvent('flutter_message', {
  detail: { type: 'UPDATE_POSITION', payload: { lat, lon, altKm, ts, source } }
}));
```

The JS side has a `handlers` map that routes by message type.

### JS → Flutter (InboundMessage)

```javascript
window.flutter_inappwebview.callHandler('GLOBE_READY', {});
```

Handlers are registered in `BridgeController.registerHandlers()` during `onWebViewCreated` (before page load).

### Message Catalog

| Direction | Message | Payload | Purpose |
|-----------|---------|---------|---------|
| F→J | `UPDATE_POSITION` | `{ lat, lon, altKm, ts, source }` | Move globe to ISS position |
| F→J | `UPDATE_ORIENTATION` | `{ heading, pitch, roll, reliable, ts }` | Rotate camera |
| F→J | `SET_TLE` | `{ line1, line2 }` | Initialize SGP4 propagator |
| F→J | `TOGGLE_LAYER` | `{ layerId, visible }` | Show/hide layer |
| F→J | `SYNC_PINS` | `{ pins: [...] }` | Re-render all pins |
| F→J | `SET_SKYBOX` | `{ enabled }` | Toggle star field |
| F→J | `REQUEST_PASS_CALC` | `{ requestId, lat, lon }` | Request pass prediction |
| J→F | `GLOBE_READY` | `{}` | CesiumJS initialized |
| J→F | `MAP_TAP` | `{ lat, lon }` | User tapped globe |
| J→F | `POSITION_UPDATE` | `{ lat, lon, altKm, ts, source }` | SGP4 propagated position |
| J→F | `PASS_CALC_RESULT` | `{ requestId, passStartUtc?, maxElevationDeg?, ... }` | Pass prediction result |
| J→F | `FRAME_RATE` | `{ fps }` | WebGL FPS |

### Key Design Decisions

- **`buildDispatchSource()` is static** — testable without a live WebView
- **`globeReady` is a `Completer<void>`** — callers `await bridge.globeReady` before sending messages
- **Streams for async responses**: `mapTaps`, `passCalcResults`, `propagatedPositions` are broadcast `StreamController`s

---

## 6. ISS Position Tracking

Three position sources implement the `PositionSource` interface:

```dart
abstract class PositionSource {
  Stream<OrbitalPosition> get positionStream;
  PositionSourceType get type; // live | estimated | static
  Future<void> start();
  Future<void> stop();
}
```

### Source Implementations

| Source | Class | Data Origin | Update Rate |
|--------|-------|-------------|-------------|
| Live | `ISSLiveSource` | WhereTheISS.at API | Every 2 seconds |
| TLE | `TLESource` | CelesTrak TLE → satellite.js SGP4 | Every 2 seconds (JS-side interval) |
| Static | `StaticPositionSource` | User-configured coordinates | Every 5 seconds |

### Position Controller (`lib/position/position_controller.dart`)

`PositionController` is a `keepAlive` Riverpod provider that manages the active source and implements automatic fallback:

```
Startup: Live source
    │
    ├── 3 consecutive "estimated" positions
    │   └── Switch to TLE source (fallback)
    │
    └── First "live" position while in fallback
        └── Switch back to Live source (recovery)
```

Users can override auto-switching by pinning a source in Settings.

### TLE Refresh

`TleRefreshDaemon` uses `background_fetch` to download fresh TLE data from CelesTrak every 6 hours, even when the app is backgrounded. TLE files are cached on disk at `{documents}/tle/iss_latest.tle`.

### OrbitalPosition Model

```dart
class OrbitalPosition {
  final double latDeg, lonDeg, altKm;
  final DateTime timestamp;
  final PositionSourceType sourceType;
  // toJson() → bridge UPDATE_POSITION payload
  // fromJson() ← bridge POSITION_UPDATE payload
}
```

---

## 7. Sensor Fusion Engine

The sensor fusion system (`lib/sensors/`) combines three hardware sensors into a stable device orientation using a complementary filter.

### Pipeline

```
Accelerometer (SamplingPeriod.gameInterval ~50 Hz)
    ↓ accelPitchRoll() → pitch, roll from gravity vector

Magnetometer (SamplingPeriod.gameInterval ~50 Hz)
    ↓ applyHardIronCorrection() → remove bias
    ↓ tiltCompensatedHeading() → heading from tilt-corrected mag field

Gyroscope (SamplingPeriod.gameInterval ~50 Hz, drives tick)
    ↓ integrate angular velocity over dt
    ↓ applyFilter(α=0.98) → blend gyro (98%) with accel/mag reference (2%)
    ↓
DeviceOrientation { headingDeg, pitchDeg, rollDeg, reliable, timestamp }
```

### Complementary Filter (`applyFilter`)

```
filteredAngle = α × (previous + gyroΔ) + (1 - α) × referenceAngle
```

- `α = 0.98`: trusts gyroscope for short-term smoothness, slowly corrects drift with accelerometer/magnetometer
- Heading uses circular interpolation (`_blendAngles`) to handle 0°/360° wrap-around
- All math is in pure functions for testability

### Magnetometer Interference Detection

If consecutive headings differ by >30° (physically impossible rotation at 50 Hz), the engine flags `reliable = false` and fires a `MagnetometerInterferenceEvent`. Recovery requires 5 consecutive stable samples.

### Calibration

`CalibrationParams` stores hard-iron offset (3-vector) and soft-iron correction (3x3 matrix). Persisted via `flutter_secure_storage`. Can be updated at runtime without restarting the engine.

---

## 8. Tile Caching System

### Components

```
TileDownloader  →  Downloads XYZ tiles with concurrency (4 parallel)
      │
      ▼
File System     →  {documents}/tiles/{layer}/{z}/{x}/{y}.png
      │
      ▼
TileDatabase    →  tile_metadata.db (Drift): tileKey, fileSize, lastAccessed
      │
      ▼
CacheManager    →  LRU eviction when cache exceeds 3 GB
      │
      ▼
TileServer      →  Background isolate, shelf_router on :8765
      │
      ▼
CesiumJS        →  UrlTemplateImageryProvider → http://localhost:8765/tiles/{layer}/{z}/{x}/{y}
```

### Tile Server (`lib/tile_cache/tile_server.dart`)

Runs in a separate `Isolate` to avoid blocking the UI thread. Routes: `/tiles/<layer>/<z>/<x>/<y>`. Returns tiles from the filesystem with appropriate MIME types (PNG, WebP, JPG).

### LRU Eviction (`lib/tile_cache/cache_manager.dart`)

`enforceMaxSize()` queries the 20 least-recently-accessed tiles, deletes them from both filesystem and metadata DB, and repeats until total size is under the limit (default 3 GB).

### Download Progress

`TileDownloader.downloadLayer()` returns a `Stream<TileDownloadProgress>` reporting `completedTiles`, `totalTiles`, and `bytesDownloaded`. Supports cancellation via Dio `CancelToken`.

---

## 9. Pin / Bookmark System

### Database Schema (Drift)

```sql
CREATE TABLE pins (
  id        TEXT PRIMARY KEY,
  lat_deg   REAL NOT NULL,
  lon_deg   REAL NOT NULL,
  name      TEXT NOT NULL,        -- max 100 chars
  note      TEXT,                 -- nullable
  icon_id   INTEGER DEFAULT 0,   -- 0-4 (white, amber, red, green, blue)
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  deleted_at DATETIME             -- soft-delete
);
```

### Repository Layer (`lib/pins/pin_repository.dart`)

- `createPin(name, lat, lon)` → generates UUID, inserts, returns `Pin`
- `updatePin(pin)` → updates all fields, sets `updatedAt`
- `deletePin(id)` → soft-delete (sets `deletedAt`)
- `watchAllPins()` → reactive `Stream<List<Pin>>` of non-deleted pins

### Pass Calculator (`lib/pins/pass_calculator.dart`)

Wraps the `REQUEST_PASS_CALC` / `PASS_CALC_RESULT` bridge round-trip in a `Future` API:

```dart
final result = await passCalc.calculateNextPass(lat, lon);
if (result.hasPass) {
  print('Next pass: ${result.passStartUtc}, max ${result.maxElevationDeg}°');
}
```

Uses UUID-keyed completers with a 10-second timeout.

---

## 10. State Management (Riverpod)

All state is managed via Riverpod 3.x with code-generated providers (`riverpod_generator`). Run `dart run build_runner build` after editing `@riverpod` annotations.

### Provider Inventory

| Provider | Type | keepAlive | Purpose |
|----------|------|-----------|---------|
| `positionControllerProvider` | `AsyncNotifier<PositionSourceStatus>` | Yes | Unified position stream + fallback logic |
| `livePositionSourceProvider` | `Provider<PositionSource>` | No | WhereTheISS.at source |
| `tlePositionSourceProvider` | `Provider<PositionSource>` | No | TLE/SGP4 source (deferred init) |
| `staticPositionSourceProvider` | `Provider<PositionSource>` | No | Fixed coordinate source (deferred init) |
| `sensorFusionEngineProvider` | `Provider<SensorFusionEngine>` | Yes | Singleton engine, auto-starts on first listen |
| `orientationStream` | `Provider<Stream<DeviceOrientation>>` | Yes | Broadcast orientation stream |
| `themeProvider` | `Notifier<AppTheme>` | — | Persisted theme selection |
| `hudVisibilityProvider` | `Notifier<bool>` | — | HUD toggle (persisted) |
| `hudDataProvider` | `Notifier<HudData>` | — | Live telemetry for HUD |
| `fpsProvider` | `Notifier<int?>` | — | WebGL FPS from bridge |
| `layerVisibilityProvider` | `Notifier<Map<String, bool>>` | — | Per-layer visibility (persisted) |
| `onboardingStateProvider` | `Notifier<int>` | — | Bitmask of completed onboarding steps |

---

## 11. Persistence Layer

| Store | Technology | File | Data |
|-------|-----------|------|------|
| Pins | Drift (SQLite) | `pins.db` | User bookmarks with soft-delete |
| Tile metadata | Drift (SQLite) | `tile_metadata.db` | LRU access times, file sizes |
| TLE cache | File system | `{docs}/tle/iss_latest.tle` | Latest TLE data |
| Tiles | File system | `{docs}/tiles/{layer}/{z}/{x}/{y}` | Raster map tiles |
| Preferences | SharedPreferences | — | Theme, HUD visibility, layer states, source mode, static coords |
| Calibration | flutter_secure_storage | — | Hard-iron/soft-iron correction params |

---

## 12. Theming & UI Components

### Theme System (`lib/shared/theme.dart`)

`AppTokens` is a `ThemeExtension` carrying all design tokens:

- **Surface colors**: `surfacePrimary`, `surfaceSecondary`, `surfaceOverlay`
- **HUD colors**: `hudPrimary`, `hudSecondary`, `hudWarning`, `hudDanger`, `hudBackground`
- **Status indicators**: `statusLive` (green), `statusEstimated` (yellow), `statusOffline` (red)
- **Typography**: `hudFontFamily` (JetBrains Mono), `hudFontSize`

Four built-in themes:

| Theme | HUD Color | Background |
|-------|-----------|------------|
| Night (default) | Cyan | Dark blue |
| Dark | White | Black |
| Star Wars | Gold | Black |
| Star Trek | Orange | Brown |

### Telemetry HUD (`lib/shared/telemetry_hud.dart`)

A full-screen `CustomPaint` overlay with six instruments:

1. **Reticle** — center crosshair boresight
2. **Heading tape** — horizontal strip at top, ±30° visible arc with cardinal markers (N/S/E/W)
3. **Pitch ladder** — left edge, shows pitch in ±30° increments
4. **Roll indicator** — arc at top center (±60°), warning color if >±30°
5. **Data strip** — bottom panels: LAT, LON, ALT, HDG (left), VEL, SRC, AGE, PCH (right)
6. **FPS counter** — top right, color-coded (green ≥25, yellow ≥15, red <15)

### Status Bar (`lib/shared/status_bar.dart`)

Compact pill at top center showing:
- Colored dot + label for position source (ISS Live / TLE Estimated / Static / Connecting)
- Data age (seconds since last fix)
- Connectivity icon (WiFi / warning)
- "Stale" warning if tile cache >30 days old

### Layer Control Panel (`lib/shared/layer_control_panel.dart`)

Seven toggleable layers:

| Layer | Default | Notes |
|-------|---------|-------|
| Camera | ON (always on cold launch) | Not persisted |
| Relief | OFF | Raster overlay |
| Clouds | OFF | Future |
| Borders | ON | Natural Earth |
| Coastlines | ON | Natural Earth |
| Cities | ON | Labels for pop >1M |
| Rivers | OFF | Future |

### Navigation FAB (`lib/shared/nav_speed_dial.dart`)

Bottom-right speed dial with three secondary buttons (Map, Pins, Settings). Staggered scale/fade animation over 240ms.

---

## 13. Screens & Navigation

| Screen | Route | Features |
|--------|-------|----------|
| `ARScreen` | Home | Camera + globe + HUD + controls |
| `MapScreen` | Push | 2D map (placeholder) |
| `PinListScreen` | Push | Pin management (placeholder) |
| `SettingsScreen` | Push | Theme picker, HUD toggle, position source selector, static coordinate inputs |
| `CalibrationScreen` | Push | Magnetometer calibration with figure-8 animation + confidence ring |

Navigation uses `pushReplacement` between non-AR screens. The speed dial FAB is present on all screens.

---

## 14. Onboarding

Three-step onboarding tracked via bitmask in SharedPreferences:

| Step | Bit | Purpose |
|------|-----|---------|
| Welcome | 0x1 | Introduction |
| Tile download | 0x2 | Pre-cache map tiles for offline use |
| Calibration | 0x4 | Magnetometer figure-8 calibration |

`OnboardingBanner` shows a non-blocking "Finish setup" prompt on the AR screen until all steps are complete. The banner can be dismissed per-session.

`CalibrationScreen` shows a Lissajous figure-8 animation guiding the user, with a circular confidence ring (0–100%). The "Done" button enables at 80% confidence.

---

## 15. Build Pipeline

### CesiumJS Globe Build

```bash
scripts/build_globe.sh
```

1. `cd web_globe && npm ci` — install exact dependency versions
2. `npx vite build --outDir ../assets/globe` — bundle CesiumJS + satellite.js
3. Case normalization: rename `Assets/` → `assets/` (macOS case-insensitive vs Linux case-sensitive)
4. `mkdir -p` on all declared `pubspec.yaml` asset directories (prevents `flutter analyze` warnings)

Must run before `flutter run` and whenever `web_globe/src/` changes.

### GeoJSON Preprocessing

```bash
scripts/preprocess_geodata.sh
```

Downloads Natural Earth vectors and simplifies with `mapshaper`:
- Countries: 10% simplification, keep NAME + SOV_A3
- Coastlines: 15% simplification
- Lakes: 10% simplification
- Cities: filter pop >100k, keep NAME + POP_MAX

Output: `assets/geodata/*.geojson`

### Flutter Codegen

```bash
dart run build_runner build --delete-conflicting-outputs
```

Required after editing Drift table definitions or `@riverpod` annotations.

---

## 16. CI/CD

### CI Pipeline (`.github/workflows/ci.yml`)

**Triggers:** Push to main (except docs/), PRs to main

```
┌─────────────────────────────────────────────────────────┐
│  build (ubuntu-latest)                                   │
│  npm ci → vite build → pub get → build_runner →          │
│  flutter analyze → flutter test → flutter build apk      │
└──────────────┬───────────────────────┬──────────────────┘
               │                       │
    ┌──────────▼──────────┐  ┌────────▼─────────────────┐
    │  build-ios           │  │  integration-test        │
    │  (macos-latest)      │  │  (macos-latest)          │
    │  flutter build ios   │  │  Boot iOS simulator →    │
    │  --no-codesign       │  │  flutter test             │
    │  --debug             │  │  integration_test/        │
    └─────────────────────┘  └──────────────────────────┘
```

**Caching:** Node modules (keyed by `package-lock.json`), Flutter pub cache (keyed by `pubspec.lock`).

### Release Pipeline (`.github/workflows/release.yml`)

Triggered by `v*` tags. Currently a placeholder for signed APK/IPA builds.

---

## 17. Testing

**~200+ tests across 35 files**

### Test Categories

| Category | Files | Tests | Key Coverage |
|----------|-------|-------|-------------|
| Position sources & controller | 6 | ~63 | API polling, TLE propagation, fallback logic, source switching |
| Sensor fusion & calibration | 4 | ~27 | Complementary filter math, interference detection, hard-iron correction |
| Database & persistence | 4 | ~27 | Drift CRUD, LRU eviction, soft delete, cache status |
| Theme & display | 4 | ~26 | Theme registry, lerp, persistence, HUD painter format helpers |
| Navigation & controls | 3 | ~25 | Speed dial, layer toggles, panel open/close |
| Screen integration | 3 | ~15 | Settings UI, map/pin screens |
| Onboarding | 3 | ~23 | Bitmask state, banner visibility, calibration confidence |
| Bridge | 2 | ~11 | Message serialization, FPS notifier, skybox dispatch |
| Utilities | 2 | ~8 | Tile enumeration, pass calculation response parsing |

### Testing Patterns

- **Mockito** for HTTP clients (Dio), TleManager, PositionSource
- **fake_async** for timer/polling logic (position sources, sensor fusion)
- **NativeDatabase.memory()** for in-memory SQLite in tests
- **Provider overrides** via `ProviderScope(overrides: [...])` for widget tests
- **`closeTo()`** with degree tolerances for floating-point sensor math
- **No `pumpAndSettle()`** on WebView widgets (WebGL never settles via `requestAnimationFrame`)

### Integration Tests

`integration_test/smoke_test.dart` runs on iOS Simulator in CI:
- Verifies app launches within 15 seconds
- Verifies GlobeView mounts
- Verifies `UPDATE_POSITION` dispatch from StaticPositionSource

---

## 18. Configuration & Environment

### Runtime Configuration

All config is injected at build time via `--dart-define`:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xyz.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=key \
  --dart-define=ISS_POSITION_API=https://api.wheretheiss.at/v1/satellites/25544 \
  --dart-define=TLE_API=https://celestrak.org/NORAD/elements/gp.php?CATNR=25544&FORMAT=TLE \
  --dart-define=TILE_SERVER_PORT=8765 \
  --dart-define=CESIUM_LOCALHOST_PORT=8080
```

No `.env` file at runtime. See `.env.example` for all available keys and defaults.

### Platform Minimums

| Platform | Minimum | Target |
|----------|---------|--------|
| iOS | 16.0 | Latest |
| Android | API 31 (Android 12) | API 35 |

### Key Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_inappwebview` | ^6.1.5 | WebView + JS bridge |
| `sensors_plus` | ^7.0.0 | Accelerometer, gyroscope, magnetometer |
| `drift` | ^2.30.0 | SQLite ORM with code generation |
| `flutter_riverpod` | ^3.0.0 | State management |
| `shelf` / `shelf_router` | ^1.4.2 / ^1.1.4 | Local HTTP servers |
| `dio` | ^5.7.0 | HTTP client |
| `satellite.js` (JS) | 4.1.4 | SGP4 orbital propagation |
| `cesium` (JS) | 1.138.0 | WebGL 3D globe |

---

## 19. Data Flow Diagrams

### Position Pipeline

```
WhereTheISS.at API (2s poll)          CelesTrak (6h refresh)
        │                                      │
        ▼                                      ▼
  ISSLiveSource                          TleManager
        │                               (disk cache)
        │                                      │
        ▼                                      ▼
  PositionController ◄──── fallback ──── TLESource
  (unified stream)                    (SGP4 via bridge)
        │
        ▼
  ARScreen._startPosition()
        │
        ▼
  BridgeController.send(UPDATE_POSITION)
        │
        ▼
  CesiumJS viewer (smooth lerp interpolation)
```

### Orientation Pipeline

```
Accelerometer ──► accelPitchRoll()
                        │
Magnetometer ──► tiltCompensatedHeading()
                        │
Gyroscope ──────► applyFilter(α=0.98) ──► DeviceOrientation
   (drives tick)        │
                        ▼
              SensorFusionEngine.orientationStream
                        │
                        ▼
              ARScreen._startOrientation()
                        │
                        ▼
              BridgeController.send(UPDATE_ORIENTATION)
                        │
                        ▼
              CesiumJS camera rotation
```

### HUD Pipeline

```
ARScreen caches:
  _lastPosition ──┐
  _lastOrientation ┤
                   ▼
            _updateHud() → HudData
                   │
                   ▼
            hudDataProvider ──► TelemetryHud (ConsumerWidget)
                                      │
            fpsProvider ──────────────►│
                                      ▼
                              HudPainter (CustomPaint)
                              ├── Reticle
                              ├── Heading tape
                              ├── Pitch ladder
                              ├── Roll indicator
                              ├── Data strip
                              └── FPS counter
```

### Layer Visibility Pipeline

```
LayerControlPanel (UI toggle)
        │
        ▼
layerVisibilityProvider.toggle(layerId)
        │
        ├──► SharedPreferences (persist)
        │
        ▼
ARScreen watches provider changes
        │
        ▼
BridgeController.send(TOGGLE_LAYER, { layerId, visible })
        │
        ▼
CesiumJS layers.js: layersRegistry[layerId].show = visible
```

---

*This document describes the architecture as of commit `117fe4b` on branch `main`.*
*For authoritative subsystem details, see [TECH_SPEC.md](TECH_SPEC.md). Section numbers are cited in code comments (e.g., `// TECH_SPEC §3.2`).*
