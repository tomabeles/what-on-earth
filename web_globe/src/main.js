// CESIUM_BASE_URL is set in index.html <head> before this module runs.
// It must match the Flutter asset path prefix (/assets/globe/) so that
// Cesium workers and static assets resolve via InAppLocalhostServer.

import * as Cesium from 'cesium';
import * as satellite from 'satellite.js';
import { initTLE, propagateNow } from './satellite_propagator.js';
import { loadVectorLayers, loadRasterLayers, layersRegistry } from './layers.js';
import { syncPins } from './pins.js';
import { calculateNextPass } from './satellite_propagator.js';

// Active SGP4 propagation interval handle; cleared on each new SET_TLE.
let _propagationInterval = null;

// Disable Ion — all imagery is served locally (no token needed).
Cesium.Ion.defaultAccessToken = undefined;

// Full transparent globe configuration — TECH_SPEC §3.2.
const viewer = new Cesium.Viewer('cesiumContainer', {
  baseLayer: false,                              // no default imagery (no Ion Bing Maps)
  terrainProvider: new Cesium.EllipsoidTerrainProvider(), // flat ellipsoid, no Ion terrain
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
      alpha: true,                               // required for WebView transparency
    },
  },
});

// Catch render errors and restart the render loop (CesiumJS stops it by default).
// Limit restarts to avoid infinite error loops from persistent bad geometry.
let _renderErrorCount = 0;
viewer.scene.renderError.addEventListener((scene, error) => {
  console.error('CesiumJS render error (non-fatal):', error);
  _renderErrorCount++;
  if (_renderErrorCount <= 5) {
    setTimeout(() => { viewer.useDefaultRenderLoop = true; }, 0);
  }
});

// Skybox (star field) is available but hidden by default — camera feed is
// visible through the transparent background. SET_SKYBOX toggles it on when
// the camera preview is paused (WOE-077).
if (viewer.scene.skyBox) {
  viewer.scene.skyBox.show = false;
}
viewer.scene.backgroundColor = new Cesium.Color(0, 0, 0, 0);
viewer.scene.highDynamicRange = false;           // HDR breaks alpha compositing
viewer.scene.fog.enabled = false;
viewer.scene.sun.show = false;
viewer.scene.moon.show = false;

// Globe translucency — baseColor alpha is unreliable in Cesium; use translucency API.
viewer.scene.globe.translucency.enabled = true;
viewer.scene.globe.translucency.frontFaceAlpha = 1.0;
viewer.scene.globe.baseColor = new Cesium.Color(0.1, 0.1, 0.15, 1.0); // dark ocean fill

// Static camera: ISS orbital altitude (420 km = 420,000 m), looking straight down.
viewer.camera.setView({
  destination: Cesium.Cartesian3.fromDegrees(0, 0, 30000000), // DEBUG: far out to see whole globe
  orientation: {
    heading: Cesium.Math.toRadians(0),
    pitch: Cesium.Math.toRadians(-90),
    roll: 0.0,
  },
});

// ── Load vector layers from bundled GeoJSON assets ──────────────────────────
loadVectorLayers(viewer, 8080).catch(e => console.warn('Vector layer load error:', e));

// Raster layers are loaded after INIT_CONFIG provides the tile server port.
// Default: try loading immediately with the standard port.
loadRasterLayers(viewer, 8765);

// ── Flutter → CesiumJS bridge (TECH_SPEC §8.1) ───────────────────────────────
// All messages arrive as `flutter_message` CustomEvents with
// { type: string, payload: object } in the detail field.

const handlers = {
  UPDATE_POSITION(payload) {
    // DEBUG: ignore position updates to keep the far-out camera view
    console.log('UPDATE_POSITION ignored (debug)', payload);
  },
  UPDATE_ORIENTATION(payload) {
    viewer.camera.setView({
      destination: viewer.camera.position, // preserve current position
      orientation: {
        heading: Cesium.Math.toRadians(payload.heading),
        pitch: Cesium.Math.toRadians(payload.pitch),
        roll: Cesium.Math.toRadians(payload.roll),
      },
    });
  },
  SET_TLE(payload) {
    // Clear any running propagation interval before starting a new one so
    // multiple SET_TLE messages don't stack up duplicate intervals.
    clearInterval(_propagationInterval);
    initTLE(payload.line1, payload.line2);
    _propagationInterval = setInterval(() => {
      const pos = propagateNow();
      if (pos) {
        window.flutter_inappwebview.callHandler('POSITION_UPDATE', pos);
      }
    }, 2000);
  },
  TOGGLE_LAYER({ layerId, visible }) {
    const layer = layersRegistry[layerId];
    if (!layer) {
      console.warn(`TOGGLE_LAYER: unknown layer "${layerId}"`);
      return;
    }
    // GeoJsonDataSource uses .show, ImageryLayer uses .show
    layer.show = visible;
  },
  SYNC_PINS(payload) {
    syncPins(viewer, payload.pins || []);
  },
  SET_MODE(payload) {
    // Implemented in a later issue.
  },
  REQUEST_PASS_CALC(payload) {
    const result = calculateNextPass(payload.lat, payload.lon);
    window.flutter_inappwebview.callHandler('PASS_CALC_RESULT', {
      requestId: payload.requestId,
      ...(result || { error: 'no_pass_found' }),
    });
  },
  SET_SKYBOX({ enabled }) {
    if (viewer.scene.skyBox) {
      viewer.scene.skyBox.show = enabled;
    }
    viewer.scene.backgroundColor = enabled
      ? new Cesium.Color(0, 0, 0, 1)   // opaque black behind stars
      : new Cesium.Color(0, 0, 0, 0);  // transparent for AR camera
  },
};

window.addEventListener('flutter_message', (e) => {
  const { type, payload } = e.detail;
  handlers[type]?.(payload);
});

// ── MAP_TAP: globe click → Flutter (WOE-036) ───────────────────────────────
const clickHandler = new Cesium.ScreenSpaceEventHandler(viewer.canvas);
clickHandler.setInputAction((event) => {
  const cartesian = viewer.camera.pickEllipsoid(
    event.position, viewer.scene.globe.ellipsoid);
  if (!cartesian) return; // tapped sky — ignore
  const carto = Cesium.Cartographic.fromCartesian(cartesian);
  window.flutter_inappwebview.callHandler('MAP_TAP', {
    lat: Cesium.Math.toDegrees(carto.latitude),
    lon: Cesium.Math.toDegrees(carto.longitude),
  });
}, Cesium.ScreenSpaceEventType.LEFT_CLICK);

// Notify Flutter that CesiumJS is fully initialized.
// The 'flutterInAppWebViewPlatformReady' event fires once the Flutter
// JavaScript handler bridge is available.
window.addEventListener('flutterInAppWebViewPlatformReady', function () {
  window.flutter_inappwebview.callHandler('GLOBE_READY', {});
});

export { Cesium, satellite };
