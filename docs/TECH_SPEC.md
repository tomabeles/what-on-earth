# Technical Specification: *What On Earth?!*

**Version:** 1.0
**Date:** 2026-03-02
**Status:** Draft
**Depends on:** PRD v1.0

---

## Table of Contents

1. [Decision Summary](#1-decision-summary)
2. [Cross-Platform Framework](#2-cross-platform-framework)
3. [AR and Globe Rendering](#3-ar-and-globe-rendering)
4. [External APIs](#4-external-apis)
5. [Library Inventory](#5-library-inventory)
6. [Project Structure and Build Environment](#6-project-structure-and-build-environment)
7. [Subsystem Specifications](#7-subsystem-specifications)
8. [Flutter ↔ CesiumJS Bridge Protocol](#8-flutter--cesiumjs-bridge-protocol)
9. [Data Models](#9-data-models)
10. [Implementation Sequence](#10-implementation-sequence)

---

## 1. Decision Summary

| Area | Decision |
|---|---|
| Mobile framework | Flutter 3.27+ (Dart) |
| Globe / AR rendering | CesiumJS 1.138.0, bundled offline, hosted in `flutter_inappwebview` |
| AR camera compositing | Flutter `camera` plugin as background layer; WebView with transparent canvas on top |
| SGP4 propagation | `satellite.js` (npm) bundled into CesiumJS WebView — not Dart-side |
| ISS live position | `https://api.wheretheiss.at/v1/satellites/25544` |
| TLE source | `https://celestrak.org/NORAD/elements/gp.php?CATNR=25544&FORMAT=TLE` |
| Map vector data | Natural Earth GeoJSON (bundled assets, ~15 MB) loaded as CesiumJS DataSource |
| Map raster tiles | XYZ raster tiles (OSM/Mapbox) pre-downloaded and served by local `shelf` HTTP server |
| Cloud cover tiles | Raster XYZ from operator-configured provider; online fetch + local LRU cache |
| Sensor access | `sensors_plus` v7.0.0 |
| SQLite ORM | `drift` v2.32.0 |
| Local tile server | `shelf` + `shelf_static` on a background isolate |
| Cloud sync backend | Supabase (managed Postgres + Auth + Realtime) |
| CI | GitHub Actions |
| State management | Riverpod 2.x |

---

## 2. Cross-Platform Framework

### 2.1 Flutter

The app is built with **Flutter 3.27+** targeting iOS 16+ and Android 12+ (API 31+). All business logic, sensor processing, data access, and UI chrome are written in Dart. CesiumJS handles only globe rendering — it is an embedded rendering surface, not the app's primary framework.

**Why Flutter over React Native or Kotlin Multiplatform:**
- Custom rendering pipeline for the globe is handled by CesiumJS (not Flutter's widget tree), making the framework's rendering model irrelevant to the hardest subsystem.
- Single Dart codebase for sensor fusion, tile cache, pin store, cloud sync, and all UI screens.
- Strong support for background isolates (needed for tile cache manager and local HTTP server).
- `flutter_inappwebview` provides a more capable JS bridge than React Native's WebView for the bidirectional Flutter↔CesiumJS communication.

### 2.2 Minimum Hardware Requirements

The app requires devices with: rear camera, magnetometer, 6-axis IMU (accelerometer + gyroscope). All devices running iOS 16+ or Android 12+ and released in the last six years satisfy this.

---

## 3. AR and Globe Rendering

### 3.1 Architecture

The AR view is a Flutter `Stack` with two layers:

```
┌───────────────────────────────────────┐
│  Layer 2 (top): InAppWebView           │  ← CesiumJS globe, transparent canvas
│  Layer 1 (bottom): CameraPreview      │  ← Flutter camera plugin, full-screen
└───────────────────────────────────────┘
```

Flutter renders the live camera feed full-screen. The `InAppWebView` sits on top with a transparent background. CesiumJS renders the globe on a WebGL canvas with alpha enabled. The result: the camera feed shows through anywhere the globe is not rendered.

### 3.2 CesiumJS Setup (Transparent Globe)

CesiumJS 1.138.0 is built with **Vite** using `vite-plugin-cesium`. The build output is checked into `assets/globe/` and loaded by the WebView via `InAppLocalhostServer` (for the HTML/JS/CSS bundle) combined with the `shelf` tile server (for map tile assets from the filesystem). The Cesium Ion token is **not used** — all imagery is sourced from the local tile server.

**Required Viewer constructor configuration for transparency:**

```javascript
// web_globe/src/main.js
window.CESIUM_BASE_URL = '/';

const viewer = new Cesium.Viewer('cesiumContainer', {
  imageryProvider: false,          // all imagery from local tile server, added below
  terrainProvider: new Cesium.EllipsoidTerrainProvider(), // no terrain mesh
  skyBox: false,                   // disables star background
  skyAtmosphere: false,
  baseLayerPicker: false,
  geocoder: false,
  homeButton: false,
  sceneModePicker: false,
  navigationHelpButton: false,
  animation: false,
  timeline: false,
  fullscreenButton: false,
  infoBox: false,
  selectionIndicator: false,
  contextOptions: {
    webgl: {
      alpha: true,                 // enables alpha channel — required for transparency
    },
  },
});

viewer.scene.backgroundColor = new Cesium.Color(0, 0, 0, 0);
viewer.scene.highDynamicRange = false; // HDR breaks transparency
viewer.scene.fog.enabled = false;
viewer.scene.sun.show = false;
viewer.scene.moon.show = false;
```

**Globe base color transparency workaround** (globe.baseColor alpha is broken in Cesium):

```javascript
viewer.scene.globe.translucency.enabled = true;
viewer.scene.globe.translucency.frontFaceAlpha = 1.0; // opaque by default; set lower for ocean transparency effect
viewer.scene.globe.baseColor = new Cesium.Color(0.1, 0.1, 0.15, 1.0); // dark ocean fill
```

### 3.3 Android WebView Transparency Workaround

`flutter_inappwebview` v6 has a known Android bug where `transparentBackground: true` is not reliably applied. The fix is a one-time platform channel call immediately after the WebView is created:

```dart
// In the InAppWebView's onWebViewCreated callback (Android only)
if (Platform.isAndroid) {
  await controller.callAsyncJavaScript(
    functionBody: "document.body.style.background = 'transparent'",
  );
  // Also set via Android platform channel: WebView.setBackgroundColor(0)
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
}
```

In addition, set `InAppWebViewSettings(transparentBackground: true, useHybridComposition: false)` on Android. Using `useHybridComposition: false` (TextureView rendering mode) provides more reliable alpha compositing on Android than SurfaceView.

### 3.4 Camera Orientation → CesiumJS Camera

The sensor fusion engine (§7.2) produces a heading/pitch/roll in degrees. Flutter sends these to CesiumJS via the bridge (§8). CesiumJS positions its camera at the current ISS geodetic position (lat/lon/alt) and orients it using:

```javascript
viewer.camera.setView({
  destination: Cesium.Cartesian3.fromDegrees(lon, lat, altMeters),
  orientation: {
    heading: Cesium.Math.toRadians(heading),
    pitch:   Cesium.Math.toRadians(pitch),
    roll:    Cesium.Math.toRadians(roll),
  },
});
```

This call is made on every `preRender` event, driven by the Flutter-side sensor fusion update cadence (50 Hz).

### 3.5 Map Data Strategy

| Data | Format | Source | Delivery |
|---|---|---|---|
| Country borders | GeoJSON | Natural Earth 1:10m admin-0 | Bundled Flutter asset |
| Coastlines | GeoJSON | Natural Earth 1:10m coastline | Bundled Flutter asset |
| Lakes and rivers | GeoJSON | Natural Earth 1:10m water | Bundled Flutter asset |
| Cities (points) | GeoJSON | Natural Earth populated places | Bundled Flutter asset |
| Base imagery (land/ocean color) | Raster XYZ tiles (WebP) | OpenStreetMap or Mapbox | Pre-downloaded offline cache |
| Topographic relief | Raster XYZ tiles (WebP) | ESRI World Shaded Relief or equivalent | Pre-downloaded offline cache |
| Cloud cover | Raster XYZ tiles (PNG) | OpenWeatherMap tile layer or equivalent | Online + 6-hour LRU cache |

GeoJSON assets are loaded via `Cesium.GeoJsonDataSource.load()` pointing at the `localhost:8765` shelf server (which serves Flutter assets via their path). All GeoJSON files are processed at build time to remove unnecessary precision beyond what is visible at orbital zoom levels (simplification tolerance: 0.01°).

### 3.6 Orbital Zoom Level

CesiumJS camera altitude is fixed in AR mode at the ISS orbital altitude (~420,000 m above Earth's surface). The camera distance to Earth's center is therefore ~6,791 km. At this altitude, the visible circle of Earth subtends ~60° of arc, so the app renders tiles at zoom level 3–5. No user-controlled zoom is implemented in V1.

---

## 4. External APIs

### 4.1 ISS Live Position

| Property | Value |
|---|---|
| Endpoint | `https://api.wheretheiss.at/v1/satellites/25544` |
| Protocol | HTTPS / REST |
| Auth | None |
| Response | JSON: `latitude`, `longitude`, `altitude` (km), `velocity`, `timestamp` |
| Rate limit | ~1 request/second (enforced via `X-Rate-Limit` response headers) |
| Poll interval | 2 seconds (within rate limit; sufficient for smooth orbital tracking) |
| Fallback | TLE propagation (§4.2) on any non-2xx response or network error |

### 4.2 TLE Data (CelesTrak)

| Property | Value |
|---|---|
| Endpoint | `https://celestrak.org/NORAD/elements/gp.php?CATNR=25544&FORMAT=TLE` |
| Protocol | HTTPS / REST |
| Auth | None |
| Response | Plain text: 3-line TLE (name + line 1 + line 2) |
| Refresh interval | Every 6 hours when online; stored locally for offline use |
| Storage | App documents directory: `tle/iss_latest.tle` + timestamp file |
| Propagation | `satellite.js` in the WebView JS bundle (§4.3) |

### 4.3 SGP4 Propagation (`satellite.js`)

`satellite.js` is bundled into the CesiumJS Vite build. It is not called from Dart. Flutter sends the raw TLE string to the WebView once at startup (and again after a TLE refresh). The WebView initializes `satellite.js` with the TLE and propagates position on a 2-second `setInterval` when the live API is unavailable.

```javascript
// web_globe/src/satellite_propagator.js
import * as satellite from 'satellite.js';

let satrec = null;

export function initTLE(tleLine1, tleLine2) {
  satrec = satellite.twoline2satrec(tleLine1, tleLine2);
}

export function propagateNow() {
  const now = new Date();
  const posVel = satellite.propagate(satrec, now);
  const gmst = satellite.gstime(now);
  const geodetic = satellite.eciToGeodetic(posVel.position, gmst);
  return {
    lat: satellite.degreesLat(geodetic.latitude),
    lon: satellite.degreesLong(geodetic.longitude),
    alt: geodetic.height,  // km
  };
}
```

### 4.4 Cloud Sync Backend (Supabase)

| Property | Value |
|---|---|
| Provider | Supabase (managed Postgres) |
| Auth | Supabase Auth with OAuth 2.0 PKCE (configurable IdP) |
| SDK | `supabase_flutter` v2.x |
| Data stored | User pins (see §9.1) |
| Sync strategy | Differential: fetch rows where `updated_at > last_sync_timestamp` |
| Region | Configurable per deployment (operator data residency) |

For V1/ISS deployment, Supabase project is operator-hosted or uses Supabase's managed cloud with a region appropriate to the agency. The app's Supabase URL and anon key are injected at build time via Dart `--dart-define`.

### 4.5 Local Tile Server

The `shelf` HTTP server runs on `localhost:8765` inside a Flutter background isolate. It serves two roots:

| Path prefix | Source | Description |
|---|---|---|
| `/assets/` | Flutter assets (via asset manifest) | GeoJSON files, CesiumJS workers/assets |
| `/tiles/{layer}/{z}/{x}/{y}.{ext}` | App documents directory | Pre-downloaded raster tiles |

---

## 5. Library Inventory

### 5.1 Flutter / Dart (`pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # WebView
  flutter_inappwebview: ^6.1.5

  # Sensors
  sensors_plus: ^7.0.0

  # Camera
  camera: ^0.11.0

  # SQLite ORM
  drift: ^2.32.0
  drift_flutter: ^0.2.4

  # Local HTTP server (tile serving)
  shelf: ^1.4.2
  shelf_static: ^1.4.1
  shelf_router: ^1.1.4

  # HTTP client
  dio: ^5.7.0

  # Filesystem
  path_provider: ^2.1.4
  path: ^1.9.0

  # Secure storage (magnetometer calibration params)
  flutter_secure_storage: ^9.2.2

  # Cloud sync backend
  supabase_flutter: ^2.8.4

  # State management
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1

  # Utilities
  uuid: ^4.5.1
  intl: ^0.19.0
  connectivity_plus: ^6.1.1   # online/offline detection
  flutter_background_fetch: ^1.2.0  # periodic background tile sync

dev_dependencies:
  flutter_test:
    sdk: flutter
  drift_dev: ^2.32.0
  build_runner: ^2.4.15
  riverpod_generator: ^2.6.1
  flutter_lints: ^5.0.0
  mockito: ^5.4.4
  build_verify: ^3.1.0
```

### 5.2 JavaScript (CesiumJS WebView bundle — `web_globe/package.json`)

```json
{
  "dependencies": {
    "cesium": "^1.138.0",
    "satellite.js": "^4.1.4"
  },
  "devDependencies": {
    "vite": "^6.1.0",
    "vite-plugin-cesium": "^1.3.3"
  }
}
```

### 5.3 Why These Choices

| Library | Why |
|---|---|
| `flutter_inappwebview` over `webview_flutter` | Richer JS bridge (`addJavaScriptHandler`), `InAppLocalhostServer`, more control over rendering mode and background color |
| `drift` over `sqflite` | Type-safe, reactive queries, explicit migrations, bundles SQLite automatically in v2.32+ |
| `shelf` over custom server | Official Dart team library, composable middleware, serves arbitrary filesystem paths (needed for downloaded tile cache) |
| `sensors_plus` | Official Flutter community plugin; covers magnetometer + IMU in a single package |
| `supabase_flutter` | Managed backend, built-in auth, offline-safe REST sync without custom server code |
| `dio` over `http` | Interceptors (auth headers, retry logic), cancellation tokens, download progress for tile fetching |
| `riverpod` over BLoC | Less boilerplate, works well with async data, compatible with Dart isolates |
| `satellite.js` in WebView | Only maintained SGP4 implementation available; avoids unmaintained Dart alternatives (`orbit` 0.0.15, last updated 2024) |

---

## 6. Project Structure and Build Environment

### 6.1 Repository Layout

```
what-on-earth/
├── lib/                          # Flutter / Dart source
│   ├── main.dart
│   ├── app.dart                  # root widget, Riverpod ProviderScope
│   ├── position/                 # Position module
│   │   ├── position_source.dart  # abstract interface
│   │   ├── iss_live_source.dart  # WhereTheISS.at client
│   │   ├── tle_source.dart       # TLE fetch + satellite.js bridge
│   │   └── static_source.dart    # static coordinates (training mode)
│   ├── sensors/                  # Sensor fusion
│   │   ├── sensor_fusion.dart    # complementary filter → quaternion → H/P/R
│   │   └── calibration.dart      # hard/soft iron calibration
│   ├── globe/                    # WebView + bridge
│   │   ├── globe_view.dart       # InAppWebView widget
│   │   ├── bridge.dart           # Flutter→JS and JS→Flutter message contracts
│   │   └── ar_view.dart          # Stack(camera, globe)
│   ├── tile_cache/               # Offline tile management
│   │   ├── tile_server.dart      # shelf server isolate
│   │   ├── tile_downloader.dart  # background tile fetch + storage
│   │   └── cache_manager.dart    # LRU eviction, status reporting
│   ├── pins/                     # Pin store
│   │   ├── pin_database.dart     # drift table definition + DAO
│   │   ├── pass_calculator.dart  # next overhead pass computation (via JS bridge)
│   │   └── pin_sync.dart         # Supabase differential sync
│   ├── onboarding/
│   │   ├── onboarding_flow.dart
│   │   └── calibration_screen.dart
│   ├── screens/
│   │   ├── ar_screen.dart
│   │   ├── map_screen.dart
│   │   ├── pin_list_screen.dart
│   │   ├── pin_detail_screen.dart
│   │   └── settings_screen.dart
│   └── shared/
│       ├── status_bar.dart       # position source / connectivity indicator
│       └── theme.dart
│
├── web_globe/                    # CesiumJS Vite project
│   ├── src/
│   │   ├── main.js               # Cesium Viewer init, bridge event handlers
│   │   ├── satellite_propagator.js  # satellite.js wrapper
│   │   ├── layers.js             # imagery layer management
│   │   └── pins.js               # CesiumJS entity management for pins
│   ├── index.html
│   ├── vite.config.js
│   └── package.json
│
├── assets/
│   ├── globe/                    # built CesiumJS bundle (git-ignored; generated by CI)
│   │   └── .gitkeep
│   └── geodata/                  # Natural Earth GeoJSON (committed)
│       ├── ne_10m_admin_0_countries.geojson
│       ├── ne_10m_coastline.geojson
│       ├── ne_10m_lakes.geojson
│       └── ne_10m_populated_places.geojson
│
├── test/
│   ├── unit/
│   └── widget/
│
├── integration_test/
│
├── scripts/
│   ├── build_globe.sh            # npm install + vite build → assets/globe/
│   ├── seed_tiles.sh             # CLI tool to pre-download tile cache to a directory
│   └── preprocess_geodata.sh     # simplify + minimize GeoJSON assets
│
├── .github/
│   └── workflows/
│       ├── ci.yml
│       └── release.yml
│
├── pubspec.yaml
├── pubspec.lock
└── TECH_SPEC.md
```

### 6.2 Build Environment

| Tool | Version |
|---|---|
| Flutter | 3.27.x (pinned in `.flutter-version` / FVM) |
| Dart | 3.6.x (bundled with Flutter) |
| Node.js | 22 LTS (for CesiumJS build only) |
| npm | 10.x |
| Xcode | 16.x (iOS builds) |
| Android SDK | API 31+ target; API 35 compile |
| Java | 17 (Android Gradle) |

### 6.3 CesiumJS Build Pipeline

The `web_globe/` directory is a standard Vite project. The build script runs before Flutter compilation in CI:

```bash
# scripts/build_globe.sh
cd web_globe
npm ci
npx vite build --outDir ../assets/globe
```

`vite.config.js` uses `vite-plugin-cesium` which automatically copies the mandatory Cesium static asset directories (`Workers/`, `Assets/`, `ThirdParty/`, `Widgets/`) into the build output. `CESIUM_BASE_URL` is set to `/` (served by `InAppLocalhostServer` from `localhost:8080`).

The built output in `assets/globe/` is **git-ignored** and generated by CI. Local development requires running `build_globe.sh` before `flutter run`.

### 6.4 Flutter Asset Declaration

```yaml
# pubspec.yaml (assets section)
flutter:
  assets:
    - assets/globe/             # CesiumJS bundle (all files recursively)
    - assets/geodata/           # Natural Earth GeoJSON
```

### 6.5 CI (GitHub Actions)

**`ci.yml`** runs on every PR:
1. Checkout
2. Install Node 22 + Flutter 3.27
3. `npm ci` + `vite build` in `web_globe/`
4. `flutter pub get`
5. `dart run build_runner build --delete-conflicting-outputs` (drift + riverpod codegen)
6. `flutter analyze`
7. `flutter test`
8. `flutter build apk --debug` (smoke build, Android)
9. `flutter build ios --no-codesign --debug` (smoke build, iOS)

**`release.yml`** runs on version tags:
- Builds signed release APK and IPA
- Uploads to internal distribution (Firebase App Distribution or equivalent)

### 6.6 Environment Configuration

Build-time variables injected via `--dart-define`:

| Variable | Description |
|---|---|
| `SUPABASE_URL` | Supabase project URL |
| `SUPABASE_ANON_KEY` | Supabase anon/public key |
| `ISS_POSITION_API` | Live position endpoint (defaults to WhereTheISS.at) |
| `TLE_API` | CelesTrak TLE endpoint |
| `TILE_SERVER_PORT` | Local shelf tile server port (default `8765`) |
| `CESIUM_LOCALHOST_PORT` | InAppLocalhostServer port for globe bundle (default `8080`) |

---

## 7. Subsystem Specifications

### 7.1 Position Module

**Abstract interface (`lib/position/position_source.dart`):**

```dart
abstract class PositionSource {
  Stream<OrbitalPosition> get positionStream;
  PositionSourceType get type;        // live | telemetry | estimated
  Future<void> start();
  Future<void> stop();
}

class OrbitalPosition {
  final double latDeg;
  final double lonDeg;
  final double altKm;
  final DateTime timestamp;
  final PositionSourceType sourceType;
}
```

**`ISSLiveSource`:** Polls `api.wheretheiss.at` every 2 seconds using `dio`. On non-2xx or timeout (5 s), emits the last known position re-tagged as `estimated` and starts the TLE fallback. Resumes live polling when the network recovers.

**`TLESource`:** Reads TLE from `tle/iss_latest.tle` in the app documents directory. Sends the TLE string to the WebView via bridge message `SET_TLE`. The WebView runs `satellite.js` propagation on a 2-second interval and sends `POSITION_UPDATE` messages back to Flutter. Flutter's `TLESource` converts these back into `OrbitalPosition` events tagged `estimated`.

**TLE refresh daemon:** A `flutter_background_fetch` periodic task attempts a TLE refresh every 6 hours. On success, writes to `tle/iss_latest.tle` and sends `SET_TLE` to the WebView.

**`StaticSource`:** Accepts a lat/lon/alt at construction, emits the same position every 10 seconds. Used for training scenarios.

**Position source selection:** Stored in shared preferences as `position_source_type`. Default is `live`. The active source is managed by a `PositionController` Riverpod provider that wraps the current source and exposes `positionStream` to the rest of the app.

### 7.2 Sensor Fusion Engine

**Sensors used:** magnetometer, accelerometer, gyroscope — all via `sensors_plus` at `SensorInterval.game` (50 Hz target).

**Algorithm:** Complementary filter running in a background Dart `Isolate`:

```
orientation(t) = α × (orientation(t-1) + gyro_delta(t)) + (1-α) × accel_mag_reference(t)
```

- `α = 0.98` (favors gyroscope for short-term, magnetometer/accelerometer for long-term drift correction)
- Gyroscope integration: `orientation += gyro_rad_per_s × dt`
- Gravity vector from accelerometer gives pitch and roll reference
- Magnetometer heading gives yaw reference (corrected for device tilt using pitch/roll from accelerometer)
- Output: heading (0–360°, degrees from magnetic north), pitch (−90 to +90°), roll (−180 to +180°)

**Calibration:** Hard-iron and soft-iron magnetometer calibration parameters are stored in `flutter_secure_storage` keyed by `mag_cal_hard_iron` (3-vector, µT) and `mag_cal_soft_iron` (3×3 matrix). Applied as a pre-processing step on each raw magnetometer sample before the complementary filter. The calibration routine (onboarding + settings) performs a figure-8 motion capture and computes these parameters using an ellipsoid fitting algorithm.

**Interference detection:** If the magnetometer heading changes by more than 30° in a single sample at a sensor rate of 50 Hz (implying ~1500°/s change — physically impossible from device motion alone), the engine flags suspected interference and emits a `MagnetometerInterferenceEvent` that triggers a UI banner prompting recalibration.

**Output stream:** The `SensorFusionEngine` exposes an `orientationStream` (stream of `DeviceOrientation` with heading, pitch, roll, and a reliability flag). This stream is consumed by the bridge (§8) to drive CesiumJS camera updates.

### 7.3 Local Tile Server

The tile server runs in a dedicated Dart `Isolate` started at app launch. It listens on `localhost:8765`.

**Request routing:**

```
GET /assets/{path}          → Flutter asset bundle (via asset manifest lookup)
GET /tiles/{layer}/{z}/{x}/{y}.webp  → documents/tiles/{layer}/{z}/{x}/{y}.webp
GET /tiles/{layer}/{z}/{x}/{y}.png   → documents/tiles/{layer}/{z}/{x}/{y}.png
GET /geodata/{filename}     → assets/geodata/{filename} (GeoJSON)
```

Missing tiles: return `404`. CesiumJS imagery layer configuration sets `maximumLevel` and `minimumLevel` to orbital-appropriate zoom range (3–5 for base imagery). Missing tiles at these zoom levels should be rare after a full pre-fetch.

**Tile directory structure on device:**

```
documents/
└── tiles/
    ├── base/          # OpenStreetMap or Mapbox raster tiles
    │   └── {z}/{x}/{y}.webp
    ├── relief/        # topographic shading raster tiles
    │   └── {z}/{x}/{y}.webp
    └── clouds/        # cloud cover raster tiles (6-hour TTL)
        └── {z}/{x}/{y}.png
```

**Tile cache manager:** A `TileCacheManager` class (runs in the tile server isolate) manages the download queue and LRU eviction. It tracks tile metadata (URL, size, last accessed, download time) in a separate `tile_metadata.db` drift database. Maximum cache size is configurable (default 3 GB). When the limit is reached, it evicts the least recently accessed tiles until under the limit.

**Pre-fetch:** During onboarding, the user taps "Download for offline use." The cache manager enumerates all tiles at zoom levels 3–5 (approximately 1,365 tiles per layer at zoom 0–5 for the full globe) and downloads them with a concurrency of 4. Progress is reported via a stream back to the UI. At full zoom range 0–5, tile counts per layer are modest (~340 tiles total), making this very fast.

### 7.4 Pin and Annotation Store

**Drift table (`lib/pins/pin_database.dart`):**

```dart
class Pins extends Table {
  TextColumn get id => text()();                        // UUID
  RealColumn get latDeg => real()();
  RealColumn get lonDeg => real()();
  TextColumn get name => text().withLength(max: 100)();
  TextColumn get note => text().nullable()();
  IntColumn get iconId => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();  // soft delete

  @override
  Set<Column> get primaryKey => {id};
}
```

**Conflict-free sync:** The `PinSync` class diffs local `updated_at` timestamps against Supabase row timestamps. Strategy: last `updated_at` wins per pin. Deleted pins propagate as tombstones (`deleted_at` set, row not physically deleted). Sync runs opportunistically whenever `connectivity_plus` reports a network state change from offline to online, and on app foreground.

**CesiumJS entities:** When pins change (create/update/delete), Flutter sends a `SYNC_PINS` bridge message with the full current pin list as JSON. The WebView clears and re-renders all pin entities. For V1, a full re-render on change is acceptable (expected pin count < 50).

**Pass calculator:** `PassCalculator` calls a JS bridge function `CALCULATE_NEXT_PASS` with `{lat, lon, currentTleLine1, currentTleLine2}`. The WebView uses `satellite.js` to iterate forward in time (1-minute steps, max 48-hour horizon) until the satellite elevation angle above the target location exceeds 10°. Returns `{passStartUtc, maxElevationDeg, passDurationSeconds}`.

### 7.5 Onboarding Flow

Three steps, resumable:

1. **Welcome / position source confirmation** — informs user that the ISS live feed is active. CTA: "Continue."
2. **Offline map download** — layer selection checkboxes (base map, relief, cloud cover). Shows estimated download size. Progress bar during download. Skippable (app warns that offline data is incomplete).
3. **Magnetometer calibration** — animated diagram showing figure-8 device motion. Live heading accuracy indicator. "Done" enabled when calibration confidence > 80% (ellipsoid fit residual below threshold). Skippable with warning.

Onboarding state is stored in shared preferences as a bitmask of completed steps. On each launch, if onboarding is incomplete, a non-blocking banner ("Finish setup →") appears on the AR screen.

---

## 8. Flutter ↔ CesiumJS Bridge Protocol

All messages use `flutter_inappwebview`'s `addJavaScriptHandler` / `callHandler` API. Messages are JSON objects.

### 8.1 Flutter → CesiumJS (via `controller.evaluateJavascript`)

| Message | Payload | Frequency | Description |
|---|---|---|---|
| `UPDATE_ORIENTATION` | `{heading, pitch, roll, ts}` | 50 Hz (sensor fusion rate) | Drive CesiumJS camera orientation |
| `UPDATE_POSITION` | `{lat, lon, altKm, ts, source}` | 0.5 Hz (2s poll) | Move CesiumJS camera destination |
| `SET_TLE` | `{line1, line2}` | On TLE refresh | Initialize satellite.js propagator |
| `TOGGLE_LAYER` | `{layerId, visible}` | On user toggle | Show/hide a CesiumJS imagery layer |
| `SYNC_PINS` | `{pins: [{id, lat, lon, name, iconId}]}` | On pin change | Redraw all pin entities |
| `SET_MODE` | `{mode}` where mode ∈ `ar \| map` | On view switch | Switch between AR and 2D map camera modes |
| `REQUEST_PASS_CALC` | `{requestId, lat, lon}` | On pin detail open | Trigger next-pass calculation |

**Delivery pattern:**

```dart
// Flutter side
await controller.evaluateJavascript(source: '''
  window.dispatchEvent(new CustomEvent('flutter_message', {
    detail: ${jsonEncode({'type': 'UPDATE_ORIENTATION', 'payload': payload})}
  }));
''');
```

```javascript
// CesiumJS side
window.addEventListener('flutter_message', (e) => {
  const { type, payload } = e.detail;
  handlers[type]?.(payload);
});
```

### 8.2 CesiumJS → Flutter (via `callHandler`)

| Message | Payload | Description |
|---|---|---|
| `GLOBE_READY` | `{}` | CesiumJS fully initialized; Flutter should send initial position + layers |
| `MAP_TAP` | `{lat, lon}` | User tapped the globe (for pin placement) |
| `PASS_CALC_RESULT` | `{requestId, passStartUtc, maxElevationDeg, passDurationSeconds}` | Result of a pass calculation request |
| `FRAME_RATE` | `{fps}` | Reported every 5 seconds (for performance monitoring) |

```javascript
// CesiumJS side
window.flutter_inappwebview.callHandler('MAP_TAP', {lat: 37.77, lon: -122.41});
```

```dart
// Flutter side
controller.addJavaScriptHandler(
  handlerName: 'MAP_TAP',
  callback: (args) => ref.read(pinControllerProvider.notifier).onMapTap(args[0]),
);
```

---

## 9. Data Models

### 9.1 OrbitalPosition

```dart
class OrbitalPosition {
  final double latDeg;
  final double lonDeg;
  final double altKm;
  final DateTime timestamp;
  final PositionSourceType sourceType; // live | estimated | static
}
```

### 9.2 DeviceOrientation

```dart
class DeviceOrientation {
  final double headingDeg;  // 0–360, degrees from magnetic north
  final double pitchDeg;    // –90 to +90 (positive = device tilted back/skyward)
  final double rollDeg;     // –180 to +180
  final bool reliable;      // false if magnetometer interference detected
  final DateTime timestamp;
}
```

### 9.3 Pin (Drift row)

```dart
class Pin {
  final String id;            // UUID
  final double latDeg;
  final double lonDeg;
  final String name;
  final String? note;
  final int iconId;           // 0–4 (five icon variants)
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;  // null = not deleted
}
```

### 9.4 TileMetadata (Drift row, separate DB)

```dart
class TileMetadata {
  final String tileKey;          // "{layer}/{z}/{x}/{y}"
  final String layerId;
  final int zoomLevel;
  final int tileX;
  final int tileY;
  final int fileSizeBytes;
  final DateTime downloadedAt;
  final DateTime lastAccessedAt;
}
```

### 9.5 CalibrationParams (secure storage)

```json
{
  "hard_iron": [hx, hy, hz],
  "soft_iron": [[sxx, sxy, sxz], [syx, syy, syz], [szx, szy, szz]],
  "calibrated_at": "ISO8601 timestamp",
  "confidence": 0.0-1.0
}
```

---

## 10. Implementation Sequence

Each phase produces a shippable build. Phases are ordered to maximize early testability on a real device.

### Phase 1 — Foundation (Days 1–5)

**Goal:** CesiumJS globe visible in a Flutter app with a static camera position.

| Step | Task |
|---|---|
| 1.1 | Create Flutter project. Configure `pubspec.yaml` with all dependencies. Set up `flutter_lints`. |
| 1.2 | Create `web_globe/` Vite project. Install CesiumJS + `satellite.js`. Configure `vite-plugin-cesium`. Run `vite build` → `assets/globe/`. Verify output is correct. |
| 1.3 | Declare `assets/globe/` and `assets/geodata/` in `pubspec.yaml`. |
| 1.4 | Implement `GlobeView` widget: `InAppLocalhostServer` on port 8080 + `InAppWebView` loading `assets/globe/index.html`. Transparent background (iOS + Android workaround). Static CesiumJS globe at ISS altitude with no imagery. |
| 1.5 | Verify globe renders in a dark theme with no white flash on Android. |
| 1.6 | Implement bridge skeleton: `GLOBE_READY` handler in Flutter. `UPDATE_POSITION` sender in Flutter. |
| 1.7 | GitHub Actions CI: install Flutter, run `build_globe.sh`, `flutter pub get`, `flutter analyze`, `flutter test`. |

**Milestone:** `flutter run` shows a CesiumJS globe in a WebView.

### Phase 2 — Position Module (Days 6–10)

**Goal:** Globe moves with ISS in real time.

| Step | Task |
|---|---|
| 2.1 | Implement `OrbitalPosition` model and `PositionSource` abstract interface. |
| 2.2 | Implement `ISSLiveSource`: `dio` polling `api.wheretheiss.at` every 2s. Emit `OrbitalPosition`. Handle errors gracefully. |
| 2.3 | Implement TLE download and file storage. Implement TLE refresh daemon. |
| 2.4 | Implement `satellite.js` propagator in `satellite_propagator.js`. Implement `SET_TLE` bridge message. Implement `POSITION_UPDATE` JS→Flutter callback. |
| 2.5 | Implement `TLESource` Dart class that drives propagation via the bridge. |
| 2.6 | Implement `PositionController` Riverpod provider: starts `ISSLiveSource`, falls back to `TLESource` on errors. |
| 2.7 | Wire `PositionController` to `GlobeView`: send `UPDATE_POSITION` messages to CesiumJS. Confirm globe camera moves with ISS position. |
| 2.8 | Implement position source status indicator widget (live / estimated / source type). |
| 2.9 | Implement `StaticSource` for training mode. |

**Milestone:** Globe camera tracks live ISS position; falls back to TLE propagation when API is unavailable.

### Phase 3 — Sensor Fusion and AR Camera (Days 11–18)

**Goal:** Device orientation drives globe orientation. Camera feed visible through globe.

| Step | Task |
|---|---|
| 3.1 | Implement `SensorFusionEngine` in a background `Isolate`. Subscribe to `sensors_plus` streams (magnetometer, accelerometer, gyroscope) at 50 Hz. Implement complementary filter → heading/pitch/roll output stream. |
| 3.2 | Implement `DeviceOrientation` model. Expose `orientationStream` from `SensorFusionEngine`. |
| 3.3 | Wire `orientationStream` to bridge: send `UPDATE_ORIENTATION` at 50 Hz. Implement CesiumJS `camera.setView()` on each message. |
| 3.4 | Implement magnetometer calibration store (secure storage). Implement hard-iron correction in sensor fusion engine. |
| 3.5 | Implement magnetometer interference detection. Implement interference warning banner. |
| 3.6 | Implement `camera` plugin integration: `CameraController` with rear camera, resolution preset medium. Render `CameraPreview` full-screen. |
| 3.7 | Assemble `ARView` widget: `Stack([CameraPreview, InAppWebView])`. Verify camera feed visible behind globe. |
| 3.8 | Test AR compositing on both iOS and Android. Fix any Android transparency issues. |

**Milestone:** Holding the device toward a viewport shows a live, orientation-correct globe overlaid on the camera feed.

### Phase 4 — Map Layers (Days 19–25)

**Goal:** Geographic features visible on the globe.

| Step | Task |
|---|---|
| 4.1 | Download and preprocess Natural Earth GeoJSON files. Run simplification script (`scripts/preprocess_geodata.sh` using `mapshaper`). Commit to `assets/geodata/`. |
| 4.2 | Implement `layers.js` in CesiumJS: load country borders, coastlines, lakes, city points as `GeoJsonDataSource` from `/geodata/` paths on the localhost server. Style: borders white 0.7 opacity, coastlines light blue, cities white dots with labels. |
| 4.3 | Implement `TOGGLE_LAYER` bridge message. Add layer toggle controls to AR view UI (collapsible panel). |
| 4.4 | Start `shelf` tile server on port 8765 in a background isolate at app launch. |
| 4.5 | Configure CesiumJS `ImageryLayer` for base raster tiles: `UrlTemplateImageryProvider` pointing to `http://localhost:8765/tiles/base/{z}/{x}/{y}.webp`. Verify it loads (returns 404 for uncached tiles — expected). |
| 4.6 | Implement `TileDownloader`: accepts a layer ID, zoom range, and bounding box; downloads tiles with 4-worker concurrency; stores in `documents/tiles/{layer}/{z}/{x}/{y}.ext`. |
| 4.7 | Implement `TileCacheManager`: download queue, LRU metadata in `tile_metadata.db`, eviction, status reporting. |
| 4.8 | Add tile download UI to onboarding step 2: layer selection + progress bar. Wire to `TileDownloader`. |
| 4.9 | Configure CesiumJS relief and cloud imagery layers. Implement cloud cover layer toggle (online: live tiles; offline: cached tiles up to 6h old; stale/missing: hide layer). |

**Milestone:** Country borders, coastlines, cities, and terrain relief visible on the globe. Offline mode works after pre-download.

### Phase 5 — Pins (Days 26–33)

**Goal:** Users can create, view, and receive pass notifications for personal pins.

| Step | Task |
|---|---|
| 5.1 | Generate drift database code: define `Pins` and `TileMetadata` tables. Run `build_runner`. |
| 5.2 | Implement `PinRepository`: CRUD operations on drift `Pins` table. Soft delete. |
| 5.3 | Implement `MAP_TAP` JS→Flutter bridge message. Show "Add Pin" bottom sheet on tap. |
| 5.4 | Implement Add Pin bottom sheet: name field, optional note, icon picker (5 icons). Saves via `PinRepository`. |
| 5.5 | Implement `SYNC_PINS` Flutter→JS message. Implement `pins.js` in CesiumJS: add/update/remove `BillboardEntity` per pin at correct lat/lon on globe surface. |
| 5.6 | Implement Pin List screen: sorted list with pass countdown. Tap to highlight pin on map. |
| 5.7 | Implement Pass Calculator: `REQUEST_PASS_CALC` bridge message + JS `satellite.js` computation + `PASS_CALC_RESULT` response. Integrate with Pin Detail screen. |
| 5.8 | Implement in-app pass notification: a `Timer.periodic` running every 60 seconds checks whether any pin pass starts within 5 minutes; shows an in-app notification banner if so. |
| 5.9 | Implement Pin Detail screen: name, note, icon, next pass details, edit and delete actions. |

**Milestone:** Full pin workflow: create pins on globe, view pass times, receive approach alerts.

### Phase 6 — Cloud Sync and Onboarding (Days 34–42)

**Goal:** Pins sync to Supabase; onboarding flow guides new users.

| Step | Task |
|---|---|
| 6.1 | Create Supabase project. Define `pins` table schema (mirrors Dart model). Enable Row Level Security: users can only read/write their own pins. |
| 6.2 | Implement `PinSync`: differential sync logic using Supabase REST. Triggered on connectivity change (via `connectivity_plus`) and app foreground. |
| 6.3 | Implement Supabase auth: OAuth 2.0 PKCE flow via `supabase_flutter`. Auth is optional in V1 (pins work fully offline/local without sign-in; sync requires sign-in). |
| 6.4 | Implement onboarding flow: 3-step `PageView`. Step 1: welcome + position confirmation. Step 2: tile download (wire to `TileDownloader`). Step 3: magnetometer calibration UI with animated figure-8 diagram and live accuracy indicator. |
| 6.5 | Implement calibration routine: collect magnetometer samples during figure-8 motion, compute hard-iron bias (mean of min/max per axis), store in `flutter_secure_storage`. |
| 6.6 | Implement onboarding state persistence (shared preferences bitmask). Show "Finish setup →" banner if incomplete. |
| 6.7 | Implement Settings screen: position source selector, layer toggles, tile cache status (size + last sync), account (Supabase auth), data attribution, about. |

**Milestone:** Full onboarding flow. Pins persist across device restarts and sync to cloud when online.

### Phase 7 — NFR Pass and Polish (Days 43–55)

**Goal:** App meets all non-functional requirements from PRD §7.

| Step | Task |
|---|---|
| 7.1 | **Performance:** Profile sensor fusion isolate. Profile CesiumJS frame rate on target devices. Ensure 50 Hz orientation + 30 fps globe on mid-range hardware. |
| 7.2 | **Battery:** Add power-saving mode (reduce sensor rate to 20 Hz, frame rate to 20 fps) when battery < 20%. Use `battery_plus` package. |
| 7.3 | **Offline reliability:** Integration tests: disable network; verify all P0 features function. Verify no crash or error state from network loss. |
| 7.4 | **Security:** Verify TLS on all external calls. Verify pin data encrypted at rest. Review permissions manifest (camera, motion, network, storage — nothing else). Remove all analytics/telemetry not behind explicit opt-in. |
| 7.5 | **Accessibility:** Add `Semantics` labels to all interactive elements. Test with VoiceOver (iOS) and TalkBack (Android). Verify contrast ratios on globe labels. Test system font scaling. |
| 7.6 | **Dark mode:** Verify all UI screens in both dark and light mode. Globe label colors readable on both. |
| 7.7 | **MDM packaging:** Build and test `.ipa` for Apple Enterprise Distribution. Build and test `.apk` for MDM sideload. Document MDM configuration profile format with supported `--dart-define` keys. |
| 7.8 | **USB tile pre-seed:** Implement and document `scripts/seed_tiles.sh` CLI tool. Test tile transfer via `adb push` (Android) and iTunes File Sharing (iOS). |
| 7.9 | **Crash-free session rate:** Integrate error monitoring (Sentry or equivalent, with opt-in). Verify crash-free rate > 99.5% in internal testing. |
| 7.10 | **Store submission:** Prepare App Store and Google Play listings. Privacy policy, screenshots, app review notes (explain ISS use case and sensor permissions). |

**Milestone:** App ready for crew deployment and public store submission.

---

*What On Earth?!* | Technical Specification v1.0
