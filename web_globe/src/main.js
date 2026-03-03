// CESIUM_BASE_URL is set in index.html <head> before this module runs.
// It must match the Flutter asset path prefix (/assets/globe/) so that
// Cesium workers and static assets resolve via InAppLocalhostServer.

import * as Cesium from 'cesium';
import * as satellite from 'satellite.js';

// Disable Ion — all imagery is served locally (no token needed).
Cesium.Ion.defaultAccessToken = undefined;

// Full transparent globe configuration — TECH_SPEC §3.2.
const viewer = new Cesium.Viewer('cesiumContainer', {
  baseLayer: false,                              // no default imagery (no Ion Bing Maps)
  terrainProvider: new Cesium.EllipsoidTerrainProvider(), // flat ellipsoid, no Ion terrain
  skyBox: false,                                 // disables star background
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
  destination: Cesium.Cartesian3.fromDegrees(0, 0, 420000),
  orientation: {
    heading: Cesium.Math.toRadians(0),
    pitch: Cesium.Math.toRadians(-90),
    roll: 0.0,
  },
});

// ── Flutter → CesiumJS bridge (TECH_SPEC §8.1) ───────────────────────────────
// All messages arrive as `flutter_message` CustomEvents with
// { type: string, payload: object } in the detail field.

const handlers = {
  UPDATE_POSITION(payload) {
    console.log('UPDATE_POSITION received', payload);
    // Camera movement wired in WOE-2.7; log confirms bridge works.
  },
  UPDATE_ORIENTATION(payload) {
    // Implemented in WOE-3.3.
  },
  SET_TLE(payload) {
    // Implemented in WOE-2.5.
  },
  TOGGLE_LAYER(payload) {
    // Implemented in a later issue.
  },
  SYNC_PINS(payload) {
    // Implemented in a later issue.
  },
  SET_MODE(payload) {
    // Implemented in a later issue.
  },
  REQUEST_PASS_CALC(payload) {
    // Implemented in a later issue.
  },
};

window.addEventListener('flutter_message', (e) => {
  const { type, payload } = e.detail;
  handlers[type]?.(payload);
});

// Notify Flutter that CesiumJS is fully initialized.
// The 'flutterInAppWebViewPlatformReady' event fires once the Flutter
// JavaScript handler bridge is available.
window.addEventListener('flutterInAppWebViewPlatformReady', function () {
  window.flutter_inappwebview.callHandler('GLOBE_READY', {});
});

export { Cesium, satellite };
