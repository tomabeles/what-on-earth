# Product Requirements Document: *What On Earth?!*

**Version:** 1.0
**Date:** 2026-03-02
**Status:** Draft

---

## Table of Contents

1. [Overview](#1-overview)
2. [Problem Statement](#2-problem-statement)
3. [Goals and Success Metrics](#3-goals-and-success-metrics)
4. [User Personas](#4-user-personas)
5. [User Stories](#5-user-stories)
6. [Functional Requirements](#6-functional-requirements)
7. [Non-Functional Requirements](#7-non-functional-requirements)
8. [Technical Architecture](#8-technical-architecture)
9. [Data Requirements](#9-data-requirements)
10. [UX and Design Requirements](#10-ux-and-design-requirements)
11. [Platform and Distribution](#11-platform-and-distribution)
12. [Risks and Mitigations](#12-risks-and-mitigations)
13. [Out of Scope (V1)](#13-out-of-scope-v1)
14. [Open Questions](#14-open-questions)

---

## 1. Overview

*What On Earth?!* is an offline-first, augmented-reality Earth-viewing application built for crew members aboard the International Space Station and future Low Earth Orbit (LEO) platforms. The app fuses onboard smartphone sensors (magnetometer, IMU, camera) with orbital position data to render a live, orientation-aware 3D globe overlaid on the device camera feed — allowing astronauts to identify any geography visible from any viewport in real time.

The app is not a flight-critical system. It is a situational-awareness and personal-connection tool designed to operate reliably in the uniquely constrained environment of human spaceflight: intermittent and bandwidth-limited connectivity, magnetic interference, managed device ecosystems, and a safety-critical operational context where the app must never compete with mission systems.

---

## 2. Problem Statement

### 2.1 Core Problem

Astronauts aboard the ISS orbit Earth at approximately 400 km altitude, completing a full orbit every 90 minutes and seeing 16 sunrises per day. Despite this extraordinary vantage point, orientation is routinely difficult:

- Earth's curvature and the absence of familiar ground-level references make coastlines, rivers, and cities hard to identify without reference materials.
- Existing map and globe tools are designed for Earth-surface users with reliable GPS and persistent connectivity — both of which are unavailable in orbit.
- No dedicated tool exists that fuses the spacecraft's real-time orbital position with device orientation to produce an accurate, annotated view of the surface below.

### 2.2 Secondary Problem

Crew members spend months in orbit separated from family and familiar places. They have expressed a desire to see and mark locations of personal significance — home towns, family homes, launch sites — and to know exactly when the station passes overhead.

### 2.3 Market Context

The commercial LEO station market is expanding rapidly. Multiple private stations are in development this decade. Each represents an enterprise deployment opportunity for a proven crew-facing application. The ISS use case is both a real market and a validation environment for a platform with adjacencies in aviation, maritime, backcountry, and other connectivity-challenged domains.

---

## 3. Goals and Success Metrics

### 3.1 V1 Goals

| Goal | Description |
|---|---|
| **Core AR experience** | Any crew member can hold up a device at any viewport and correctly identify what geography is below within 10 seconds of app launch. |
| **Full offline operation** | 100% of core features available during communication blackouts of up to 30 minutes, with no degraded UX besides absence of real-time cloud layer. |
| **Personal connection** | Crew members can pin meaningful locations and receive accurate pass-overhead notifications. |
| **Zero-config ISS deployment** | App works for ISS crew from first launch with no manual configuration of position source. |
| **Safe deployment** | App causes no interference with mission-critical systems, does not consume excessive CPU/battery, and makes no network calls that could block normal operations. |

### 3.2 Success Metrics

| Metric | Target (90 days post-launch) |
|---|---|
| Crew adoption rate (ISS) | ≥ 80% of crew members with compatible devices have launched the app at least once |
| Session frequency | ≥ 3 sessions/week per active user |
| AR orientation accuracy | Globe alignment error ≤ 5° on supported devices in crew-reported usage |
| Offline reliability | Zero reported failures of core AR function due to connectivity loss |
| Personal pin usage | ≥ 60% of active users have created at least one personal pin |
| App store rating | ≥ 4.5 stars (public listing) |
| Crash-free session rate | ≥ 99.5% |

---

## 4. User Personas

### 4.1 Primary Persona — ISS Crew Member

**Who:** Active crew member on a 6-month ISS rotation. Uses personal smartphone or agency-issued tablet. Has moderate technical literacy but is mission-focused and time-constrained.

**Goals:**
- Quickly identify what part of Earth is visible from the cupola or a viewport.
- Mark and revisit personal locations during passes.
- Share orbital views (photos with AR overlay) with family.

**Constraints:**
- Device is likely managed by agency IT (MDM); app store access may be restricted.
- Connectivity is intermittent; assumes offline operation is the norm.
- Cannot spend time troubleshooting or calibrating equipment.
- Safety protocol prohibits using any app that could interfere with mission systems.

### 4.2 Secondary Persona — Flight Controller / Mission Planner

**Who:** Ground-based mission planner or crew trainer preparing astronauts for specific observational tasks or using the app in simulation/training scenarios.

**Goals:**
- Set up the app with static orbital coordinates for training scenarios.
- Verify that a crew member's device is correctly configured before a mission begins.
- Preview what geography will be visible during a planned EVA or observation window.

**Constraints:**
- Uses the app on a ground-based device, not in orbit.
- Needs static/simulated position source rather than live ISS feed.

### 4.3 Tertiary Persona — Commercial Station Operator

**Who:** Engineering or product lead at a commercial LEO station (e.g., Axiom, Starlab). Evaluating *What On Earth?!* for crew licensing on their platform.

**Goals:**
- Integrate the app's position module with their proprietary onboard telemetry system.
- Deploy the app to crew devices via their own MDM infrastructure.
- Potentially white-label or co-brand the experience.

**Constraints:**
- Has custom telemetry protocol (not ISS feed).
- May have specific data sovereignty or security requirements.
- Needs an enterprise licensing and support relationship.

---

## 5. User Stories

### 5.1 AR Earth Viewing

| ID | Story | Priority |
|---|---|---|
| US-001 | As a crew member, I want to hold my device toward a viewport and see a correctly oriented 3D globe so that I can immediately identify what I'm looking at below. | P0 |
| US-002 | As a crew member, I want country borders and coastlines displayed on the AR globe so that I can recognize geographic regions. | P0 |
| US-003 | As a crew member, I want city and settlement labels displayed on the AR globe so that I can identify major urban areas. | P0 |
| US-004 | As a crew member, I want to see topographic relief shading so that I can understand terrain. | P1 |
| US-005 | As a crew member, I want to see real-time cloud cover on the globe so that I can understand current weather patterns. | P1 |
| US-006 | As a crew member, I want to switch between AR camera view and a 2D map view so that I can browse geography beyond what is currently visible. | P1 |
| US-007 | As a crew member, I want to see major road and highway networks on the globe so that I can understand human infrastructure below. | P2 |

### 5.2 Position and Orientation

| ID | Story | Priority |
|---|---|---|
| US-010 | As a crew member on the ISS, I want the app to automatically use the live ISS position feed with no manual configuration so that I can start using the app immediately. | P0 |
| US-011 | As a crew member, I want the globe to update in real time as I move and tilt the device so that the AR view remains accurate as I reorient. | P0 |
| US-012 | As a crew member, I want to clearly see when the app is using estimated position (TLE propagation) vs. live position so that I trust the data I see. | P0 |
| US-013 | As a mission planner, I want to configure a static orbital position so that I can run training scenarios on the ground. | P1 |
| US-014 | As a commercial station operator, I want to integrate my own telemetry feed over a local IP connection so that my crew can use the app with accurate position data. | P1 |
| US-015 | As a crew member, I want a guided magnetometer calibration routine during onboarding so that the AR orientation is as accurate as possible. | P1 |

### 5.3 Offline Operation

| ID | Story | Priority |
|---|---|---|
| US-020 | As a crew member, I want all core app features to be available during a 30-minute communication blackout so that I can use the app throughout any orbit. | P0 |
| US-021 | As a crew member, I want to pre-download all map tiles and layers before a mission so that the app is fully functional from day one of the rotation. | P0 |
| US-022 | As a crew member, I want the app to automatically sync updated tiles and layer data in the background when connectivity is available so that I don't have to manage updates manually. | P1 |
| US-023 | As a crew member, I want to see my current tile cache status and storage usage so that I know whether the offline data is current. | P2 |

### 5.4 Personal Pins

| ID | Story | Priority |
|---|---|---|
| US-030 | As a crew member, I want to tap any location on the globe or map to add a personal pin so that I can mark meaningful places. | P0 |
| US-031 | As a crew member, I want to name my pin and add a note so that I remember why a location is meaningful. | P0 |
| US-032 | As a crew member, I want to see a countdown to the next time the station's orbital path will bring me within viewing distance of a pinned location so that I can plan to look for it. | P0 |
| US-033 | As a crew member, I want my pins to persist across sessions and sync to the cloud when connectivity returns so that I never lose them. | P1 |
| US-034 | As a crew member, I want to choose an icon for my pin from a small set of options so that I can visually distinguish different categories of pins. | P2 |
| US-035 | As a crew member, I want to receive a notification (in-app) when I am within viewing distance of a pinned location so that I don't miss the pass. | P2 |

---

## 6. Functional Requirements

### 6.1 Position Module

**FR-POS-001:** The app MUST support three position source modes, selectable at configuration time:
1. **Live ISS Feed** — polls a configurable real-time ISS position API endpoint at ≥ 1 Hz.
2. **Onboard Telemetry** — receives position data from a local-network TCP/IP connection (operator-defined protocol, documented in integration spec).
3. **Static / TLE Propagation** — user-entered TLE set with onboard SGP4 propagation.

**FR-POS-002:** The default position source on first launch MUST be the Live ISS Feed with no user configuration required.

**FR-POS-003:** When the Live ISS Feed or Onboard Telemetry source is unavailable, the app MUST automatically fall back to TLE propagation and clearly indicate this in the UI.

**FR-POS-004:** TLE sets MUST be refreshed from a configurable remote source whenever connectivity is available. The app MUST store the last successfully fetched TLE set locally for offline use.

**FR-POS-005:** The UI MUST display a persistent position-source status indicator showing: (a) source type, (b) live vs. estimated, (c) age of last live fix.

**FR-POS-006:** The position module interface MUST be documented and versioned so that third-party operators can implement custom position source adapters.

### 6.2 Sensor Fusion Engine

**FR-SEN-001:** The sensor fusion engine MUST combine magnetometer heading and IMU (accelerometer + gyroscope) data to produce a world-frame orientation quaternion.

**FR-SEN-002:** The orientation quaternion MUST be updated at a rate of ≥ 60 Hz to support smooth AR rendering.

**FR-SEN-003:** The app MUST provide a guided magnetometer calibration routine available from onboarding and from settings. The routine MUST follow standard figure-8 calibration protocol or equivalent.

**FR-SEN-004:** Globe rendering orientation error MUST be ≤ 5° on devices with magnetometer accuracy rated "High" (iOS) or equivalent (Android) after calibration.

**FR-SEN-005:** The engine MUST detect and flag suspected magnetometer interference (large, sudden, inconsistent heading changes) and prompt the user to recalibrate.

### 6.3 AR Globe Renderer

**FR-GLO-001:** The app MUST render a real-time GPU-accelerated 3D spherical globe composited over the live camera feed.

**FR-GLO-002:** The globe MUST orient itself based on the current orientation quaternion from the sensor fusion engine, updating continuously at display frame rate (≥ 30 fps, target 60 fps).

**FR-GLO-003:** The following layers MUST be available in V1 (P0 layers always visible; P1 layers toggleable):
  - Country and territory borders (P0)
  - Coastlines and bodies of water (P0)
  - Cities and settlements with labels (P0)
  - Topographic relief shading (P1, toggleable)
  - Major road and highway networks (P1, toggleable)
  - Real-time cloud cover (P1, toggleable, requires connectivity or recent cache)

**FR-GLO-004:** The app MUST provide a 2D flat-map view that can be accessed from the AR view. The 2D map MUST share the same layers, pins, and position data as the AR view.

**FR-GLO-005:** Globe tiles MUST render at a zoom level appropriate for the orbital altitude (~400 km), showing geography at a scale where continents, countries, major coastlines, and large cities are clearly distinguishable.

**FR-GLO-006:** Personal pins MUST be rendered on the AR globe and the 2D map view at their correct geographic coordinates.

### 6.4 Tile Cache Manager

**FR-TCH-001:** The app MUST support pre-fetching the full global tile set at orbital-relevant zoom levels for offline use.

**FR-TCH-002:** The compressed offline tile cache MUST fit within 2–4 GB of device storage.

**FR-TCH-003:** The app MUST run a background sync process that fetches updated tiles and layers opportunistically whenever connectivity is available, without user intervention.

**FR-TCH-004:** The app MUST display current tile cache status including: last sync time, current cache size, and whether all layers are available offline.

**FR-TCH-005:** The background sync MUST be rate-limited and bandwidth-conscious, respecting any system-level data restrictions. It MUST NOT initiate large downloads during active AR sessions.

**FR-TCH-006:** The tile cache MUST use vector tiles for base map layers (borders, roads, coastlines) and compressed raster tiles for imagery layers (relief shading, cloud cover).

### 6.5 Pin and Annotation Store

**FR-PIN-001:** Users MUST be able to create a pin by tapping any location on the AR globe or 2D map.

**FR-PIN-002:** Each pin MUST support: name (required), note (optional), icon (selectable from a set of ≥ 5 icons).

**FR-PIN-003:** The app MUST calculate and display the next predicted overhead pass for each pin based on the current orbital position and propagated orbital mechanics. The calculation MUST account for minimum viewing elevation (≥ 10° above local horizon from the station's altitude).

**FR-PIN-004:** Pins MUST be stored in a local SQLite database. Pin data MUST persist across app restarts.

**FR-PIN-005:** When connectivity is available, pins MUST sync to a cloud backend using a conflict-free merge strategy (last-write-wins per pin, no pin deletions without explicit user action).

**FR-PIN-006:** An in-app notification MUST alert the user when the station is approaching viewing distance of a pinned location (configurable lead time, default 5 minutes).

### 6.6 Onboarding

**FR-ONB-001:** On first launch, the app MUST present an onboarding flow that: (a) explains the position source default, (b) prompts tile pre-fetch, (c) guides magnetometer calibration.

**FR-ONB-002:** The pre-fetch step MUST allow the user to select which optional layers to include in the offline cache (to manage storage).

**FR-ONB-003:** The onboarding flow MUST be resumable — if interrupted, it MUST resume from the last incomplete step on next launch.

**FR-ONB-004:** The app MUST be usable (AR view visible, position source active) before onboarding is fully complete, with a banner prompting completion.

---

## 7. Non-Functional Requirements

### 7.1 Performance

| Requirement | Target |
|---|---|
| App cold launch to AR view active | ≤ 5 seconds on supported hardware |
| Sensor fusion update rate | ≥ 60 Hz |
| AR globe frame rate | ≥ 30 fps (target 60 fps) on supported devices |
| Globe tile render latency (cached) | ≤ 100 ms per tile |
| Pin pass-overhead calculation | ≤ 2 seconds for next pass for any pin |
| Background sync CPU ceiling | ≤ 5% CPU utilization during sync |

### 7.2 Battery and Resource Constraints

**NFR-BAT-001:** During active AR session, the app MUST NOT cause device battery drain exceeding 20% per hour on supported mid-range hardware.

**NFR-BAT-002:** In background mode, the app MUST NOT prevent device from entering low-power state.

**NFR-BAT-003:** The app MUST expose a power-saving mode that reduces sensor fusion rate to 20 Hz and frame rate to 20 fps when battery level falls below a configurable threshold (default 20%).

### 7.3 Reliability and Offline

**NFR-REL-001:** All P0 features (AR globe, position, layers, pins) MUST function with zero network connectivity for at least 30 continuous minutes after the last connectivity window.

**NFR-REL-002:** The app MUST NOT crash or display error states due to network unavailability.

**NFR-REL-003:** The crash-free session rate MUST be ≥ 99.5% as measured in production telemetry.

**NFR-REL-004:** The app MUST gracefully degrade when individual subsystems (position API, cloud backend) are unreachable, without affecting other subsystems.

### 7.4 Security and Privacy

**NFR-SEC-001:** All cloud sync traffic (pins, tile updates) MUST use TLS 1.3 or later.

**NFR-SEC-002:** User pin data (names, notes, coordinates) MUST be encrypted at rest on the device using the platform keychain / Android Keystore.

**NFR-SEC-003:** The app MUST NOT collect or transmit any telemetry, analytics, or usage data without explicit user opt-in.

**NFR-SEC-004:** The app MUST NOT require any permissions beyond: camera, motion sensors (IMU/magnetometer), local network access, and storage.

**NFR-SEC-005:** The app MUST be distributable via enterprise MDM side-loading without requiring a public app store connection.

### 7.5 Accessibility

**NFR-ACC-001:** Text labels on the globe and in the UI MUST meet WCAG 2.1 AA contrast ratios.

**NFR-ACC-002:** All interactive UI elements MUST be reachable via VoiceOver (iOS) and TalkBack (Android).

**NFR-ACC-003:** The app MUST support system-level font scaling.

### 7.6 Compatibility

**NFR-CMP-001:** The app MUST support iOS 16+ and Android 12+ on devices with: rear camera, magnetometer, and 6-axis IMU (accelerometer + gyroscope).

**NFR-CMP-002:** The app MUST be deployable via Apple MDM (Enterprise Distribution) and Android MDM (APK sideload / managed Google Play).

**NFR-CMP-003:** The tile cache MUST be transferable via USB (ADB / iTunes File Sharing) to support pre-seeding in environments with no connectivity at all.

---

## 8. Technical Architecture

### 8.1 Component Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Application Layer                        │
│   AR View   │   2D Map View   │   Onboarding   │   Settings     │
├─────────────┬───────────────────┬───────────────┬───────────────┤
│  Position   │  Sensor Fusion    │  3D Globe     │  Tile Cache   │
│  Module     │  Engine           │  Renderer     │  Manager      │
├─────────────┴───────────────────┴───────────────┴───────────────┤
│  Pin & Annotation Store       │  Cloud Sync Daemon              │
├───────────────────────────────┴─────────────────────────────────┤
│                        Platform Layer                           │
│   iOS / Android   │   GPU   │   SQLite   │   Keychain          │
└─────────────────────────────────────────────────────────────────┘
```

### 8.2 Position Module

The position module is implemented as an abstract interface with three concrete implementations:

1. **ISSLiveFeedPositionSource** — HTTP/WebSocket client to a configurable real-time ISS position API. Polls at 1 Hz. Writes latest fix to a shared in-memory position store.
2. **LocalTelemetryPositionSource** — TCP client that connects to an operator-configured local IP:port. Parses an open documented protocol (defined in Integration Spec v1). Supports reconnection with exponential backoff.
3. **TLEPropagationPositionSource** — Implements SGP4 orbital propagation. Reads TLE sets from local storage. Propagates position on demand. TLE refresh daemon fetches updated sets from a configurable URL when online.

The active position source is selected at startup via configuration. The module emits `PositionUpdate` events consumed by the globe renderer and pin store.

### 8.3 Sensor Fusion Engine

- Reads raw magnetometer, accelerometer, and gyroscope samples from platform sensor APIs.
- Applies a complementary filter (gyroscope integration for high-frequency, magnetometer/accelerometer for low-frequency drift correction) to produce a stable world-frame quaternion.
- Publishes orientation updates at ≥ 60 Hz to the globe renderer via a lock-free ring buffer.
- Includes a calibration subsystem: stores per-device hard-iron and soft-iron magnetometer calibration parameters in local storage, applied as a pre-processing step on each raw magnetometer sample.

### 8.4 3D Globe Renderer

- Built on a cross-platform GPU graphics layer (Metal on iOS, Vulkan/OpenGL ES on Android).
- Renders an Earth sphere with a Mercator-projected tile texture. Tiles are fetched from the Tile Cache Manager and uploaded to GPU texture memory as they arrive.
- Camera feed is rendered as a full-screen background layer; globe is blended over it using alpha compositing based on orientation.
- Layer compositing order (back to front): camera feed → relief shading → base map → cloud cover → roads → labels → pins → UI chrome.
- Zoom level is fixed for V1 at orbital-altitude-appropriate scale; pinch-to-zoom is a V2 feature.

### 8.5 Tile Cache Manager

- Manages a local tile store on the filesystem, organized by layer, zoom level, and tile coordinates.
- On onboarding and subsequently on any connectivity window, a background daemon enumerates missing or stale tiles and fetches them from configured tile servers.
- Vector tiles (MVT format) are used for borders, roads, and labels. Raster tiles (WebP) are used for relief shading and cloud cover.
- Maximum total cache size is enforced; oldest/least recently used tiles are evicted when the limit is reached (LRU eviction).
- Provides a cache status API (last sync time, bytes used, tiles missing) for display in the UI.

### 8.6 Pin and Annotation Store

- Local store: SQLite database via platform-appropriate ORM.
- Schema: `pins(id UUID, lat REAL, lon REAL, name TEXT, note TEXT, icon_id INTEGER, created_at INTEGER, updated_at INTEGER, deleted_at INTEGER)`.
- Soft deletes: pins are never hard-deleted locally; `deleted_at` is set and filtered in queries.
- Cloud sync: when connectivity is available, a sync daemon diffs the local store against the cloud backend (REST API, returns last-modified timestamps). Conflict resolution: last `updated_at` wins per pin. Deleted pins are propagated to cloud as tombstones.
- Overhead pass calculator: given a pin's coordinates and the current TLE set, computes upcoming passes using a geometric elevation-angle model. Returns next pass start time, max elevation, and pass duration.

---

## 9. Data Requirements

### 9.1 Map Data

| Layer | Source | License | Offline Caching |
|---|---|---|---|
| Country/territory borders | OpenStreetMap (via vector tile service) | ODbL | Permitted with attribution |
| Coastlines, water bodies | OpenStreetMap | ODbL | Permitted with attribution |
| Cities and settlements | OpenStreetMap | ODbL | Permitted with attribution |
| Road networks | OpenStreetMap | ODbL | Permitted with attribution |
| Topographic relief shading | Configurable raster provider (enterprise agreement) | Enterprise — offline permitted | Permitted under agreement |
| Real-time cloud cover | Configurable provider (enterprise agreement) | Enterprise — offline caching for ≤ 24 hrs | Permitted under agreement |
| ISS live position | Public ISS position API | Open | N/A (live only; TLE used offline) |
| TLE sets | CelesTrak or equivalent open source | Public domain | Permitted |

All data sources MUST have confirmed offline-caching rights before inclusion. Data provenance MUST be documented in an in-app open data registry accessible from the settings screen.

### 9.2 User Data

| Data | Storage | Sync |
|---|---|---|
| Personal pins (coordinates, name, note, icon) | Local SQLite (encrypted at rest) | Cloud sync when online |
| Magnetometer calibration parameters | Local keychain/keystore | Device-local only |
| Selected layers and UI preferences | Local user defaults | Device-local only |
| TLE sets | Local filesystem | Refreshed from remote when online |
| Tile cache | Local filesystem | Managed by background daemon |

### 9.3 Cloud Backend Requirements

The cloud backend is a simple, low-complexity service:

- **Pin sync endpoint:** REST API accepting and returning pin records with last-modified timestamps. Supports differential sync (returns only records updated since a given timestamp).
- **Authentication:** Crew member identity managed via a provider-configurable auth mechanism (OAuth 2.0 with PKCE recommended). In V1, agency or operator provides identity; the app supports configurable identity provider endpoints.
- **Data residency:** Cloud backend MUST support deployment in a region configurable by the operator for data sovereignty compliance.

---

## 10. UX and Design Requirements

### 10.1 Core Principles

1. **Zero friction to first value.** The primary experience (AR globe in correct orientation) MUST be accessible within 5 seconds of cold launch with no required configuration.
2. **Obvious state at all times.** Position source, data freshness, and offline status must always be visible without requiring navigation.
3. **Non-intrusive.** The app never demands attention. Notifications are in-app only. Background processes are silent.
4. **One-handed use.** Core interactions (viewing the globe, checking a pin, toggling a layer) MUST be achievable with one hand on a standard-size smartphone.

### 10.2 Screen Inventory

| Screen | Description |
|---|---|
| **AR View** | Full-screen camera feed with 3D globe overlay. Status bar showing position source and data freshness. Layer toggle controls. Nav to 2D Map and Pins. |
| **2D Map View** | Flat interactive map with same layers and pins. Current ISS ground track and footprint visible. |
| **Pin List** | Scrollable list of all pins with next-pass countdown. Tap to highlight on map. |
| **Pin Detail** | Pin name, note, icon, next pass schedule, edit and delete actions. |
| **Add Pin** | Appears as a bottom sheet after tapping map. Name field, note field, icon picker. Confirm / Cancel. |
| **Onboarding** | Multi-step flow: welcome → position source (default confirmed) → tile pre-fetch (layer selection + download progress) → magnetometer calibration. |
| **Settings** | Position source configuration, layer management, tile cache status, auth, data attribution, about. |
| **Calibration** | Guided magnetometer calibration with animated device motion diagram and live accuracy indicator. |

### 10.3 Status Indicators

The AR View and 2D Map View MUST display a persistent compact status bar containing:

- **Position source icon + label:** "ISS Live", "Telemetry", or "Estimated (TLE)" with visual distinction (green / yellow / grey).
- **Data age:** Time since last live position fix.
- **Connectivity icon:** Online / offline indicator.
- **Tile cache freshness:** Indicator if tile cache is > 30 days stale.

### 10.4 Visual Design

- **Color palette:** Dark mode primary (appropriate for low-light cupola use). Light mode option in settings.
- **Globe style:** Realistic satellite imagery base with simplified, high-contrast annotation layers for legibility at orbital zoom.
- **Typography:** System font (SF Pro on iOS, Roboto on Android) for labels; minimum 12pt for any globe annotation.

---

## 11. Platform and Distribution

### 11.1 Target Platforms

| Platform | Minimum OS | Primary Distribution |
|---|---|---|
| iOS | iOS 16 | Apple App Store + Enterprise MDM |
| Android | Android 12 (API 31) | Google Play Store + APK sideload / Managed Google Play |

### 11.2 Distribution Channels

**Public App Store Listing:**
Available on both Apple App Store and Google Play Store for public download. Public listing serves: (a) crew member personal device installs, (b) public awareness, (c) future consumer market expansion.

**Enterprise MDM Distribution:**
The primary distribution mechanism for crew devices. The app MUST be packaged as:
- iOS: `.ipa` for enterprise distribution (requires Apple Developer Enterprise Program membership or agency MDM enrollment).
- Android: `.apk` for direct install via ADB or MDM platform.

MDM distribution packages MUST support pre-configuration (tile cache pre-seeded, position source default confirmed, identity provider configured) via MDM-pushed configuration profiles.

**USB / Offline Pre-seed:**
The tile cache MUST be pre-seedable via USB transfer (iTunes File Sharing on iOS, ADB push on Android) for situations where no over-the-air download is possible before a mission.

### 11.3 Update Strategy

- Public app store updates follow standard app store review cycles.
- Enterprise MDM updates are distributed directly by the agency/operator.
- The app MUST support in-app update notification (banner) when a newer version is available via the app store.
- The app MUST function fully on the version installed at mission start, even if no updates are available during the rotation.

---

## 12. Risks and Mitigations

### 12.1 Magnetometer Interference Aboard Spacecraft

**Risk:** Metal hulls, electrical equipment, and magnetic shielding materials perturb compass readings, causing AR globe misalignment.

**Likelihood:** High
**Impact:** High — core AR orientation accuracy degraded

**Mitigations:**
1. Per-device hard-iron and soft-iron calibration stored and applied on each use.
2. Guided recalibration routine easily accessible from the AR view.
3. Real-time interference detection alerts crew to recalibrate when detected.
4. **Contingency (V2):** Camera-based horizon detection mode that derives device orientation from the visual horizon in the camera feed, bypassing the magnetometer entirely. This is the primary V2 investment if magnetometer interference proves severe.

### 12.2 Connectivity Unpredictability

**Risk:** ISS connectivity windows are structured but vary in bandwidth, latency, and availability. Background sync may not complete reliably.

**Likelihood:** High
**Impact:** Medium — stale tiles or cloud data, but offline operation not compromised

**Mitigations:**
1. Offline-first architecture means zero core features require connectivity.
2. Background sync uses bandwidth-adaptive chunked downloads that resume across sessions.
3. Pre-flight pre-seeding via USB for guaranteed offline readiness.
4. Sync daemon respects system data restrictions and low-bandwidth conditions.

### 12.3 App Store Distribution in Crew Environments

**Risk:** Agency-managed devices may have restricted app store access. Standard consumer installation flow unavailable.

**Likelihood:** High (expected for ISS)
**Impact:** High if not addressed — app never reaches devices

**Mitigations:**
1. Enterprise MDM distribution path built and tested before public launch.
2. USB pre-seed capability for tile cache to remove dependency on over-the-air download.
3. Direct relationship established with relevant agency IT teams before mission.

### 12.4 Position API Unavailability

**Risk:** Public ISS position API may be unavailable, rate-limited, or deprecated.

**Likelihood:** Medium
**Impact:** Medium — fallback to TLE propagation, slight accuracy degradation

**Mitigations:**
1. TLE propagation fallback is always active, with accuracy sufficient for globe orientation use case.
2. TLE sets are refreshed frequently and cached locally for extended offline use.
3. Position source is configurable, so alternative APIs can be substituted without app update.

### 12.5 Data Licensing Changes

**Risk:** Map data or layer data providers change licensing terms, removing offline caching rights.

**Likelihood:** Low
**Impact:** High — specific layers would need to be removed or replaced

**Mitigations:**
1. All data sources documented in open data registry with license version and expiry.
2. OpenStreetMap (ODbL) base map is the foundational layer and is perpetually licensed.
3. Enterprise agreements for specialized layers negotiated with offline caching rights explicitly documented.

---

## 13. Out of Scope (V1)

The following are explicitly deferred to V2 or later:

| Feature | Rationale |
|---|---|
| Camera-based horizon detection (magnetometer-free orientation) | V2 contingency if magnetometer interference is severe; significant CV engineering investment |
| Pinch-to-zoom on AR globe | V1 zoom level is fixed; zoom at orbital altitudes has limited utility |
| Social / pin sharing between crew members | Pin sync is user-local in V1; crew sharing is V2 |
| Additional layers (night-time lights, wildfires, ocean currents, agriculture) | Planned based on crew feedback; data sourcing and licensing required |
| Apple Vision Pro / mixed-reality headset support | Future platform target; requires dedicated rendering pipeline |
| External hardware integrations (window mounts with IMU, crew-worn sensors) | Accessory ecosystem; V1 uses consumer device sensors only |
| Offline photo capture with AR overlay | Requires post-processing pipeline; V2 |
| Ground-track predictive orbit visualization | Pass calculation for pins is in-scope; general orbit visualization is V2 |
| White-label / operator branding | Commercial feature for enterprise operators; V2 |
| Localization (languages other than English) | V1 launches in English only |

---

## 14. Open Questions

| ID | Question | Owner | Target Resolution |
|---|---|---|---|
| OQ-001 | What is the specific ISS position API endpoint and rate limit? Is this an official NASA/ESA feed or a third-party aggregator? | Engineering | Pre-development |
| OQ-002 | What is the cloud backend hosting provider and data residency region? Does the agency have a preferred provider? | Product / Ops | Pre-development |
| OQ-003 | Which specific raster data providers will be used for relief shading and cloud cover? Are enterprise offline-caching agreements in place? | Product / Legal | Pre-development |
| OQ-004 | What is the target crew device model(s) for ISS V1 deployment? Magnetometer accuracy varies significantly by device. | Product / Agency Partnership | Pre-development |
| OQ-005 | What is the agency MDM platform (JAMF, Intune, other)? Configuration profile format must match. | Engineering / Agency IT | Pre-development |
| OQ-006 | Is crew identity (for pin cloud sync) managed by the agency's IdP, or does *What On Earth?!* run its own auth? | Product / Engineering | Pre-development |
| OQ-007 | At what point, if any, does the app require flight safety assessment or agency approval for crew device use? What is the process? | Product / Legal | Pre-launch |
| OQ-008 | What is the tile cache pre-seeding plan for the first ISS mission? Will a connectivity window be available, or is USB transfer required? | Engineering / Ops | Pre-launch |
| OQ-009 | What are the minimum pass elevation angle and viewing footprint parameters to use in pin pass calculation? (10° assumed; confirm with domain expert.) | Engineering | V1 development |
| OQ-010 | Will commercial station operators require a formal Integration Spec before evaluating the position module? What format is preferred? | Business Development | Post-V1 |

---

*What On Earth?!* | Making every orbit a moment of discovery.

---

*Document Owner: Product Team*
*Next Review: TBD*
