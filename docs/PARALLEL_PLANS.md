# Parallel Implementation Plans

Two agents working in parallel. Agent A owns backend/bridge/infrastructure. Agent B owns UI/screens/theming. Each phase's tickets can be done in any order within the phase, but all tickets in a phase must complete before starting the next phase.

**Note:** WOE-049 (Settings Screen) is superseded by WOE-080 + WOE-081 + WOE-082 + WOE-083.

---

## Shared File Conflict Zones

Both agents touch these files at different times. Merge Agent A's PR first when both modify the same file in the same phase window.

| File | Agent A adds | Agent B adds |
|------|-------------|-------------|
| `lib/globe/bridge.dart` | SET_SKYBOX, TOGGLE_LAYER, MAP_TAP, SYNC_PINS, REQUEST_PASS_CALC, SET_FRAMERATE | SET_MODE (WOE-078) |
| `web_globe/src/main.js` | All JS handlers for above messages | SET_MODE handler (WOE-078) |
| `lib/screens/ar_screen.dart` | Orientation wiring (WOE-019) | HUD, NAV FAB, Controls, Status Bar integration |

---

## Agent A -- Backend, Bridge & Infrastructure (32 tickets)

Primary directories: `lib/sensors/`, `lib/tile_cache/`, `lib/pins/` (data layer), `lib/globe/bridge.dart`, `web_globe/src/`, `scripts/`, `supabase/`, `assets/geodata/`, `integration_test/`

### Phase A1 -- Foundation (all deps satisfied, start immediately)

| Order | Ticket | Title | Key Files |
|-------|--------|-------|-----------|
| 1 | WOE-017 | SensorFusionEngine in Background Isolate | `lib/sensors/sensor_fusion.dart` |
| 2 | WOE-028 | shelf Tile Server in Background Isolate | `lib/tile_cache/tile_server.dart` |
| 3 | WOE-034 | Drift Database Schema (Pins + TileMetadata) | `lib/pins/pin_database.dart`, `lib/tile_cache/tile_database.dart` |
| 4 | WOE-025 | Natural Earth GeoJSON Download & Preprocessing | `assets/geodata/`, `scripts/preprocess_geodata.sh` |
| 5 | WOE-069 | SET_SKYBOX Bridge Message + Viewer Init | `lib/globe/bridge.dart`, `web_globe/src/main.js` |

### Phase A2 (after A1)

| Order | Ticket | Title | Depends on |
|-------|--------|-------|------------|
| 6 | WOE-018 | DeviceOrientation Model + orientationStream | WOE-017 |
| 7 | WOE-020 | Magnetometer Calibration Store + Hard-Iron Correction | WOE-017 |
| 8 | WOE-035 | PinRepository CRUD Implementation | WOE-034 |
| 9 | WOE-030 | TileDownloader Implementation | WOE-028 |
| 10 | WOE-029 | CesiumJS Base Raster Tile Imagery Layer | WOE-028 |
| 11 | WOE-026 | CesiumJS GeoJSON Layer Rendering (layers.js) | WOE-025 |

### Phase A3 (after A2)

| Order | Ticket | Title | Depends on |
|-------|--------|-------|------------|
| 12 | WOE-019 | Wire orientationStream to CesiumJS Camera | WOE-018 |
| 13 | WOE-021 | Magnetometer Interference Detection + UI Banner | WOE-018, WOE-020 |
| 14 | WOE-036 | MAP_TAP Bridge Message + Add Pin Trigger | WOE-035 |
| 15 | WOE-038 | SYNC_PINS Bridge + CesiumJS Pin Entities (pins.js) | WOE-035 |
| 16 | WOE-040 | Pass Calculator Bridge Integration | WOE-035 |
| 17 | WOE-031 | TileCacheManager with LRU Eviction | WOE-030 |
| 18 | WOE-027 | TOGGLE_LAYER Bridge Message | WOE-026 |
| 19 | WOE-043 | Supabase Project Setup + Pins Table Schema | WOE-034 |

### Phase A4 (after A3)

| Order | Ticket | Title | Depends on |
|-------|--------|-------|------------|
| 20 | WOE-047 | Magnetometer Calibration Routine Implementation | WOE-020 |
| 21 | WOE-041 | In-App Pass Approach Notification | WOE-040 |
| 22 | WOE-044 | PinSync Differential Sync Implementation | WOE-043, WOE-035 |
| 23 | WOE-045 | Supabase OAuth 2.0 PKCE Auth Flow | WOE-043 |
| 24 | WOE-033 | Relief and Cloud Cover Imagery Layers | WOE-029, WOE-031 |
| 25 | WOE-057 | USB Tile Pre-seed Tooling | WOE-028, WOE-030 |

### Phase A5 (after A4)

| Order | Ticket | Title | Depends on |
|-------|--------|-------|------------|
| 26 | WOE-051 | Battery Power-Saving Mode | WOE-017, WOE-019 |
| 27 | WOE-052 | Offline Reliability Integration Tests | WOE-031, WOE-038 |
| 28 | WOE-053 | Security Audit and Hardening | WOE-044, WOE-045 |

### Phase A6 (after A5)

| Order | Ticket | Title | Depends on |
|-------|--------|-------|------------|
| 29 | WOE-056 | MDM Packaging and Distribution | WOE-007 (done) |
| 30 | WOE-058 | Error Monitoring Integration (Opt-In) | WOE-053 |
| 31 | WOE-050 | Performance Profiling and Optimization | WOE-019; also needs Agent B's WOE-024 |

### Phase A7 (after A6)

| Order | Ticket | Title | Depends on |
|-------|--------|-------|------------|
| 32 | WOE-059 | App Store Submission Preparation | WOE-056, WOE-058 |

---

## Agent B -- UI, Screens & Theming (30 tickets)

Primary directories: `lib/shared/` (theme, HUD, nav, controls, status bar), `lib/screens/`, `lib/onboarding/`, `lib/pins/` (UI only: add_pin_sheet.dart)

### Phase B1 -- Foundation (all deps satisfied, start immediately)

| Order | Ticket | Title | Key Files |
|-------|--------|-------|-----------|
| 1 | WOE-063 | Theme System -- AppTokens + 4 Named Themes | `lib/shared/theme.dart` |
| 2 | WOE-048 | Onboarding State Persistence + Completion Banner | `lib/onboarding/onboarding_state_manager.dart` |
| 3 | WOE-081 | Settings -- Position Source Section | `lib/screens/settings_screen.dart` |

### Phase B2 (after B1)

| Order | Ticket | Title | Depends on |
|-------|--------|-------|------------|
| 4 | WOE-064 | Theme Riverpod Provider + Persistence | WOE-063 |
| 5 | WOE-065 | Speed-Dial NAV FAB Component | WOE-063 |
| 6 | WOE-067 | Status Bar Widget (supersedes WOE-015) | WOE-063 |
| 7 | WOE-068 | Controls Button + Layer Control Panel | WOE-063 |
| 8 | WOE-070 | Telemetry HUD -- Scaffold, Toggle, Reticle | WOE-063 |
| 9 | WOE-084 | Calibration Screen UI | WOE-063 (WOE-020 from Agent A optional, mock confidence) |

### Phase B3 (after B2)

| Order | Ticket | Title | Depends on |
|-------|--------|-------|------------|
| 10 | WOE-066 | Screen Navigation Routing | WOE-065 |
| 11 | WOE-071 | Telemetry HUD -- Heading Tape | WOE-070 |
| 12 | WOE-072 | Telemetry HUD -- Pitch Ladder | WOE-070 |
| 13 | WOE-073 | Telemetry HUD -- Roll Indicator | WOE-070 |
| 14 | WOE-074 | Telemetry HUD -- Data Strip | WOE-070 |
| 15 | WOE-075 | Telemetry HUD -- FPS Counter | WOE-070 |
| 16 | WOE-080 | Settings -- Display Section | WOE-064 |
| 17 | WOE-077 | Camera Toggle in Control Panel | WOE-068; needs Agent A's WOE-069 merged first |

### Phase B4 (after B3)

| Order | Ticket | Title | Depends on |
|-------|--------|-------|------------|
| 18 | WOE-078 | 2D Map View Screen + SET_MODE Bridge | WOE-066, WOE-067 |
| 19 | WOE-076 | Telemetry HUD -- Mag Interference Banner | WOE-070 (WOE-021 from Agent A optional, mock `reliable`) |

### Phase B5 -- Cross-agent sync required (after B4, needs Agent A outputs merged to main)

| Order | Ticket | Title | Needs from Agent A |
|-------|--------|-------|--------------------|
| 20 | WOE-037 | Add Pin Bottom Sheet UI | WOE-035 (PinRepository), WOE-036 (MAP_TAP bridge) |
| 21 | WOE-039 | Pin List Screen | WOE-035 (PinRepository), WOE-040 (PassCalculator) |
| 22 | WOE-042 | Pin Detail Screen | WOE-035 (PinRepository), WOE-040 (PassCalculator) |
| 23 | WOE-079 | 2D Map -- ISS Ground Track + Viewing Footprint | WOE-078 |
| 24 | WOE-032 | Onboarding Tile Download UI | WOE-030 (TileDownloader), WOE-031 (TileCacheManager) |
| 25 | WOE-082 | Settings -- Layers + Tile Cache Sections | WOE-068, WOE-031 (TileCacheManager) |

### Phase B6 (after B5)

| Order | Ticket | Title | Depends on |
|-------|--------|-------|------------|
| 26 | WOE-046 | Onboarding Flow 3-Step PageView | WOE-032, WOE-048 |
| 27 | WOE-083 | Settings -- Account, Sensor, Power, About | WOE-084; needs Agent A's WOE-045, WOE-051 |

### Phase B7 -- Polish (after B6)

| Order | Ticket | Title | Depends on |
|-------|--------|-------|------------|
| 28 | WOE-024 | AR Compositing Cross-Platform Testing | Physical device testing |
| 29 | WOE-054 | Accessibility Implementation | WOE-039, WOE-042, WOE-080+083 |
| 30 | WOE-055 | Dark and Light Mode Verification | WOE-080+083 |

---

## Cross-Agent Sync Points

These are moments where Agent B is blocked until specific Agent A tickets are merged to main.

| Agent B blocked at | Waiting for Agent A ticket | Why |
|--------------------|---------------------------|-----|
| B3: WOE-077 | A1: WOE-069 (SET_SKYBOX) | Camera toggle needs `setSkybox()` bridge method |
| B5: WOE-037 | A2: WOE-035 + A3: WOE-036 | Add Pin sheet needs PinRepository + MAP_TAP bridge |
| B5: WOE-039, WOE-042 | A2: WOE-035 + A3: WOE-040 | Pin screens need PinRepository + PassCalculator |
| B5: WOE-032 | A2: WOE-030 + A3: WOE-031 | Tile download UI needs TileDownloader + CacheManager |
| B5: WOE-082 | A3: WOE-031 | Settings tile cache section needs CacheManager |
| B6: WOE-083 | A4: WOE-045, A5: WOE-051 | Settings account/power sections need Auth + PowerMode |
| A6: WOE-050 | B7: WOE-024 | Performance profiling needs AR compositing tested |

## Recommended Workflow

1. Both agents start their Phase 1 tickets immediately in parallel worktrees
2. Each completed ticket = one PR. User merges to main via GitHub UI
3. Agent B can work through Phases B1-B4 (~19 tickets) without waiting for Agent A
4. Agent A should aim to complete through Phase A3 (~19 tickets) before Agent B reaches Phase B5
5. Late-stage tickets (Phases A6-A7, B6-B7) require most cross-agent outputs merged
