# web_globe

Vite project that bundles [CesiumJS](https://cesium.com/platform/cesiumjs/) and
[satellite.js](https://github.com/shashwatak/satellite-js) for the What On Earth?!
Flutter WebView.

## Local build

From the **repo root**:

```bash
scripts/build_globe.sh
```

Or from this directory:

```bash
npm ci
npx vite build --outDir ../assets/globe
```

The output is written to `assets/globe/` and is **git-ignored** (a `.gitkeep`
placeholder is committed so the directory exists for `pubspec.yaml` asset
declarations). Rebuild before `flutter run` whenever JS sources change.

## Dev server (optional)

```bash
npm run dev
```

Opens a hot-reloading browser page at `http://localhost:5173` — useful for
iterating on the CesiumJS scene without a Flutter build cycle.
