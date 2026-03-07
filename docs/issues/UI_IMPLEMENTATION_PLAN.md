# UI Spec Implementation Plan

**Date:** 2026-03-07
**Source:** UI_SPEC.md v1.0
**New tickets:** WOE-063 through WOE-084 (22 tickets)

---

## 1. Superseded Tickets

These existing tickets are replaced by new UI spec tickets. Mark as superseded.

| Ticket | Title | Replaced By | Reason |
|--------|-------|-------------|--------|
| WOE-015 | Position Source Status Indicator | WOE-067 | UI spec redesigns as semi-transparent pill bar (SS5.1) |
| WOE-016 | StaticSource for Training Mode | WOE-060 | Already implemented as StaticPositionSource |
| WOE-049 | Settings Screen | WOE-080 to WOE-083 | Split into 4 isolated, independently testable tickets |

## 2. Existing Tickets to Adjust

These tickets remain valid but need updates to align with the UI spec.

| Ticket | Adjustment |
|--------|------------|
| WOE-023 | Update Stack to 4 layers (add HUD CustomPaint as Layer 3 per SS4.1). Reference WOE-067 for Status Bar instead of WOE-015. |
| WOE-027 | Scope down to bridge message + JS handler ONLY. UI panel portion moved to WOE-068. |
| WOE-037 | Add SS4.5 details: half-height sheet, coordinate caption style, `hudPrimary` icon selection ring, `fabBackground` button fill, 100-char name limit. |
| WOE-039 | Add SS4.3 details: swipe-to-delete with confirmation, "in X h Y m" countdown format, sort by next pass ascending, independent "+" FAB for pin placement mode. |
| WOE-042 | Add SS4.4 details: inline-editable name/note, icon tappable to change, 5 upcoming passes list, auto-save on blur (no Save button), destructive Delete at bottom. |
| WOE-046 | Add SS4.7 details: pill dots at bottom for progress, skippable flags per step, specific content per step. |
| WOE-048 | Add SS4.7 banner: non-blocking "Finish setup ->" banner above Status Bar on AR view when onboarding incomplete. |

## 3. New Tickets Summary

| # | Title | UI Spec | Depends On |
|---|-------|---------|------------|
| 063 | Theme System -- AppTokens + 4 Named Themes | SS2 | -- |
| 064 | Theme Riverpod Provider + Persistence | SS2.1 | 063 |
| 065 | Speed-Dial NAV FAB Component | SS3.1, SS5.4 | 063 |
| 066 | Screen Navigation Routing | SS3.1 | 065 |
| 067 | Status Bar Widget | SS5.1 | 063 |
| 068 | Controls Button + Layer Control Panel | SS3.2, SS5.3 | 063 |
| 069 | SET_SKYBOX Bridge Message + Viewer Init | SS6.1 | 006 |
| 070 | Telemetry HUD -- Scaffold, Toggle, Reticle | SS5.2 | 063 |
| 071 | Telemetry HUD -- Heading Tape | SS5.2 | 070 |
| 072 | Telemetry HUD -- Pitch Ladder | SS5.2 | 070 |
| 073 | Telemetry HUD -- Roll Indicator | SS5.2 | 070 |
| 074 | Telemetry HUD -- Data Strip | SS5.2 | 070 |
| 075 | Telemetry HUD -- FPS Counter | SS5.2 | 070 |
| 076 | Telemetry HUD -- Mag Interference Banner | SS5.2 | 070, 021 |
| 077 | Camera Toggle in Control Panel | SS5.3 | 068, 069, 022 |
| 078 | 2D Map View Screen + SET_MODE Bridge | SS4.2 | 066, 067 |
| 079 | 2D Map -- ISS Ground Track + Footprint | SS4.2 | 078, 011 |
| 080 | Settings -- Display Section | SS4.6 | 064 |
| 081 | Settings -- Position Source Section | SS4.6 | 013 |
| 082 | Settings -- Layers + Tile Cache Sections | SS4.6 | 068, 031 |
| 083 | Settings -- Account, Sensor, Power, About | SS4.6 | 045, 084, 051 |
| 084 | Calibration Screen UI | SS4.8 | 063, 020 |

## 4. Master Implementation Order

Tickets are grouped into sprints. Groups with the same number can be worked in parallel.

### Sprint 1: Theme Foundation
| Order | Ticket | Title | Can Parallel |
|-------|--------|-------|--------------|
| 1 | WOE-063 | Theme System -- AppTokens + 4 Named Themes | -- |
| 2 | WOE-064 | Theme Riverpod Provider + Persistence | -- |

### Sprint 2: Position Wiring + AR Chrome
| Order | Ticket | Title | Can Parallel |
|-------|--------|-------|--------------|
| 3 | WOE-013 | PositionController Riverpod Provider | A |
| 4 | WOE-065 | Speed-Dial NAV FAB Component | A |
| 5 | WOE-067 | Status Bar Widget | A |
| 6 | WOE-068 | Controls Button + Layer Control Panel | A |
| 7 | WOE-069 | SET_SKYBOX Bridge Message + Viewer Init | A |
| 8 | WOE-014 | Wire PositionController to GlobeView | after 013 |
| 9 | WOE-066 | Screen Navigation Routing | after 065 |

### Sprint 3: Telemetry HUD
| Order | Ticket | Title | Can Parallel |
|-------|--------|-------|--------------|
| 10 | WOE-070 | HUD Scaffold + Reticle | -- |
| 11 | WOE-071 | Heading Tape | B |
| 12 | WOE-072 | Pitch Ladder | B |
| 13 | WOE-073 | Roll Indicator | B |
| 14 | WOE-074 | Data Strip | B |
| 15 | WOE-075 | FPS Counter | B |

### Sprint 4: Sensor Fusion
| Order | Ticket | Title | Can Parallel |
|-------|--------|-------|--------------|
| 16 | WOE-017 | SensorFusionEngine | -- |
| 17 | WOE-018 | DeviceOrientation Model | after 017 |
| 18 | WOE-019 | Wire Orientation to CesiumJS | after 018 |
| 19 | WOE-020 | Magnetometer Calibration Store | C |
| 20 | WOE-021 | Interference Detection | after 020 |
| 21 | WOE-076 | Mag Interference Banner (HUD) | after 021 |

### Sprint 5: Camera + AR Compositing
| Order | Ticket | Title | Can Parallel |
|-------|--------|-------|--------------|
| 22 | WOE-022 | Camera Plugin Integration | -- |
| 23 | WOE-023 | ARView Stack Assembly (updated for 4 layers) | after 022 |
| 24 | WOE-024 | Cross-platform AR Testing | after 023 |
| 25 | WOE-077 | Camera Toggle in Control Panel | after 022+069 |

### Sprint 6: Map Layers
| Order | Ticket | Title | Can Parallel |
|-------|--------|-------|--------------|
| 26 | WOE-025 | GeoJSON Download + Preprocessing | D |
| 27 | WOE-028 | Shelf Tile Server (port 8765) | D |
| 28 | WOE-026 | CesiumJS GeoJSON Rendering | after 025 |
| 29 | WOE-027 | TOGGLE_LAYER Bridge Message (bridge only) | after 026 |
| 30 | WOE-029 | CesiumJS Base Raster Imagery | after 028 |
| 31 | WOE-030 | TileDownloader | after 028 |
| 32 | WOE-031 | TileCacheManager | after 030 |
| 33 | WOE-033 | Relief + Cloud Layers | after 029 |

### Sprint 7: 2D Map + Early Settings
| Order | Ticket | Title | Can Parallel |
|-------|--------|-------|--------------|
| 34 | WOE-078 | 2D Map Screen + SET_MODE | -- |
| 35 | WOE-079 | Ground Track + Footprint | after 078 |
| 36 | WOE-080 | Settings -- Display Section | E |
| 37 | WOE-081 | Settings -- Position Source | E |

### Sprint 8: Pins
| Order | Ticket | Title | Can Parallel |
|-------|--------|-------|--------------|
| 38 | WOE-034 | Drift Database Schema | -- |
| 39 | WOE-035 | PinRepository CRUD | after 034 |
| 40 | WOE-036 | MAP_TAP Bridge Message | F |
| 41 | WOE-038 | SYNC_PINS Bridge + pins.js | F |
| 42 | WOE-037 | Add Pin Bottom Sheet (updated) | after 035+036 |
| 43 | WOE-039 | Pin List Screen (updated) | after 035 |
| 44 | WOE-040 | Pass Calculator | after 035 |
| 45 | WOE-041 | Pass Notification Service | after 040 |
| 46 | WOE-042 | Pin Detail Screen (updated) | after 040 |

### Sprint 9: Onboarding + Calibration
| Order | Ticket | Title | Can Parallel |
|-------|--------|-------|--------------|
| 47 | WOE-084 | Calibration Screen UI | -- |
| 48 | WOE-047 | Calibration Routine (algorithm) | after 084 |
| 49 | WOE-046 | Onboarding Flow (updated) | after 047 |
| 50 | WOE-032 | Onboarding Tile Download UI | G |
| 51 | WOE-048 | Onboarding State + Banner (updated) | after 046 |
| 52 | WOE-082 | Settings -- Layers + Tile Cache | after 031 |

### Sprint 10: Cloud Sync + Late Settings
| Order | Ticket | Title | Can Parallel |
|-------|--------|-------|--------------|
| 53 | WOE-043 | Supabase Project Setup | -- |
| 54 | WOE-044 | PinSync Differential Sync | after 043 |
| 55 | WOE-045 | Supabase Auth Flow | after 043 |
| 56 | WOE-083 | Settings -- Account, Sensor, Power, About | after 045+084+051 |

### Sprint 11: NFR Pass
| Order | Ticket | Title |
|-------|--------|-------|
| 57 | WOE-050 | Performance Profiling |
| 58 | WOE-051 | Battery Power-Saving Mode |
| 59 | WOE-052 | Offline Reliability Tests |
| 60 | WOE-053 | Security Audit |
| 61 | WOE-054 | Accessibility |
| 62 | WOE-055 | Dark/Light Mode Verification |
| 63 | WOE-056 | MDM Packaging |
| 64 | WOE-057 | USB Tile Pre-seed |
| 65 | WOE-058 | Error Monitoring |
| 66 | WOE-059 | App Store Submission |

## 5. Dependency Graph

```
WOE-063 (Theme System)
  +-- WOE-064 (Theme Provider)
  |     +-- WOE-080 (Settings: Display)
  +-- WOE-065 (NAV FAB)
  |     +-- WOE-066 (Navigation Routing)
  |           +-- WOE-078 (2D Map Screen)
  |                 +-- WOE-079 (Ground Track)
  +-- WOE-067 (Status Bar)
  +-- WOE-068 (Controls + Panel)
  |     +-- WOE-077 (Camera Toggle) <-- also needs 069, 022
  |     +-- WOE-082 (Settings: Layers) <-- also needs 031
  +-- WOE-070 (HUD Scaffold + Reticle)
  |     +-- WOE-071 (Heading Tape)
  |     +-- WOE-072 (Pitch Ladder)
  |     +-- WOE-073 (Roll Indicator)
  |     +-- WOE-074 (Data Strip)
  |     +-- WOE-075 (FPS Counter)
  |     +-- WOE-076 (Mag Banner) <-- also needs 021
  +-- WOE-084 (Calibration Screen) <-- also needs 020

WOE-006 (Bridge Skeleton) [completed]
  +-- WOE-069 (SET_SKYBOX Bridge)

WOE-013 (PositionController)
  +-- WOE-014 (Wire to Globe)
  +-- WOE-067 (Status Bar) [optional, can use mock]
  +-- WOE-081 (Settings: Position Source)
```

## 6. Notes

- **Mock data**: HUD tickets (070-075) and Status Bar (067) can be built with mock/static data before sensor fusion and position wiring are complete. This allows UI work to proceed independently of backend work.
- **WOE-023 update**: The ARView Stack must be updated from 3 layers to 4 layers per UI spec SS4.1 (camera, WebView, HUD CustomPaint, UI chrome).
- **WOE-027 scope reduction**: TOGGLE_LAYER UI panel is now in WOE-068. WOE-027 should only implement the bridge message and JS handler.
- **Font**: JetBrainsMono is added in WOE-063 via `google_fonts` package or bundled in `assets/fonts/`.
- **Testing**: Every new ticket produces a visible/interactive change testable on a real device or simulator.
