# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

**Before the first `flutter run` and whenever `web_globe/src/` changes:**
```bash
scripts/build_globe.sh          # npm ci + vite build → assets/globe/
```

**Flutter:**
```bash
flutter pub get
flutter analyze                 # must be clean before committing
flutter test                    # run all tests
flutter test test/globe/bridge_test.dart   # run a single test file
dart run build_runner build     # re-run after editing Drift tables or Riverpod providers
flutter run --dart-define=SUPABASE_URL=https://xyz.supabase.co --dart-define=SUPABASE_ANON_KEY=key
flutter build apk --debug
flutter build ios --no-codesign --debug
```

**JS (run from `web_globe/`):**
```bash
npm ci
npx vite build --outDir ../assets/globe
```

All runtime config is injected at build time via `--dart-define`. Keys and defaults are in `.env.example`. There is no `.env` file — pass values directly or use `--dart-define-from-file`.

## Architecture

### Two rendering layers (AR view)

```
┌─────────────────────────────────┐
│  InAppWebView (CesiumJS globe)  │  ← transparent WebGL canvas
│  CameraPreview (camera plugin)  │  ← full-screen live feed
└─────────────────────────────────┘
```

Flutter `Stack`: camera at the bottom, WebView on top with `transparentBackground: true` and `useHybridComposition: false` (Android TextureView — required for reliable alpha blending; see flutter_inappwebview#99).

### CesiumJS bundle

`web_globe/` is a Vite project (entry: `src/main.js`) that bundles CesiumJS 1.138 + satellite.js. `scripts/build_globe.sh` outputs to `assets/globe/` (git-ignored). `vite-plugin-cesium` externalises Cesium.js as a separate script tag; `base: '/'` keeps all asset paths at the root of the output directory.

### Two local HTTP servers

| Port | Purpose | Owner |
|------|---------|-------|
| 8080 | Serves `assets/globe/` as virtual root so WebView can load `http://localhost:8080/index.html` | Custom `shelf` handler in `lib/globe/globe_view.dart` — **not** `InAppLocalhostServer` (which can't mount a subdirectory as root) |
| 8765 | Serves XYZ map tiles from the device's documents directory | `lib/tile_cache/tile_server.dart`, runs in a background isolate |

### Flutter ↔ CesiumJS bridge (`lib/globe/bridge.dart`)

All communication goes through `BridgeController`:

- **Flutter → JS**: `BridgeController.send(OutboundMessage, payload)` calls `evaluateJavascript` to fire `window.dispatchEvent(new CustomEvent('flutter_message', { detail: {type, payload} }))`. The JS side dispatches to a `handlers` map in `main.js`.
- **JS → Flutter**: CesiumJS calls `window.flutter_inappwebview.callHandler(name, payload)`. Handlers are registered in `BridgeController.registerHandlers()`, which must be called from `onWebViewCreated` (before page load).
- `BridgeController.buildDispatchSource()` is a static method — use it in tests to verify serialization without a live WebView.

Message type enums (`OutboundMessage`, `InboundMessage`) with `.messageName` / `.handlerName` getters live in `bridge.dart`. The full payload schema for each message is in `docs/TECH_SPEC.md §8`.

### State management

Riverpod 3.x (`flutter_riverpod`). Providers are code-generated with `riverpod_generator` — run `dart run build_runner build` after editing `@riverpod` annotations.

### Persistence

Drift 2.30 on SQLite. Drift table definitions are in annotated Dart classes; run `dart run build_runner build` after changing any `Table` subclass. The pin database lives in `lib/pins/pin_database.dart`. A separate `tile_metadata.db` (managed by the tile cache isolate) tracks tile LRU eviction metadata.

### Issue backlog

`docs/issues/WOE-NNN.md` — each file is a self-contained ticket with Description, Definition of Done, and Sub-tasks. `docs/issues/COMPLETED.md` tracks shipped issues with commit hashes. `docs/TECH_SPEC.md` is the authoritative reference for all subsystem decisions; section numbers are cited in code comments (e.g. `// TECH_SPEC §3.2`).
