// reticle_label.js — Identifies geographic features at the globe view center.
//
// Builds lightweight spatial indices from loaded CesiumJS layer data and a
// bundled city GeoJSON.  A throttled query function picks the best label
// for the screen center (the reticle) and sends it to Flutter.

import * as Cesium from 'cesium';

// ── Spatial index data ──────────────────────────────────────────────────────

// [{ name, rings: [[[lat, lon], ...], ...] }]
let _countries = [];
// [{ name, lat, lon, pop }]
let _cities = [];
// [{ name, lat, lon }]
let _waterBodies = [];

let _ready = false;
let _lastLabel = '';

// ── Index building ──────────────────────────────────────────────────────────

/**
 * Build spatial indices from loaded layer data.
 * Call once after all geographic layers have finished loading.
 *
 * @param {object} layersRegistry
 * @param {number} assetServerPort - port serving geodata files (default 8080)
 */
export async function buildIndex(layersRegistry, assetServerPort = 8080) {
  _buildCountryIndex(layersRegistry['borders']);
  _buildWaterIndex(layersRegistry['water']);
  await _loadCities(assetServerPort);
  _ready = true;
  console.log(
    `Reticle index ready: ${_countries.length} countries, ` +
    `${_cities.length} cities, ${_waterBodies.length} water bodies`
  );
}

function _buildCountryIndex(borderDs) {
  if (!borderDs) return;
  const byName = new Map();
  const now = Cesium.JulianDate.now();

  for (const entity of borderDs.entities.values) {
    const name = entity.properties?.NAME?.getValue();
    if (!name || !entity.polyline) continue;
    try {
      const positions = entity.polyline.positions.getValue(now);
      if (!positions || positions.length < 3) continue;
      const ring = [];
      for (const p of positions) {
        const c = Cesium.Cartographic.fromCartesian(p);
        ring.push([
          Cesium.Math.toDegrees(c.latitude),
          Cesium.Math.toDegrees(c.longitude),
        ]);
      }
      if (!byName.has(name)) byName.set(name, []);
      byName.get(name).push(ring);
    } catch (_) { /* skip degenerate */ }
  }

  _countries = [...byName.entries()].map(([name, rings]) => ({ name, rings }));
}

function _buildWaterIndex(waterDs) {
  if (!waterDs) return;
  const now = Cesium.JulianDate.now();

  for (const entity of waterDs.entities.values) {
    const label = entity.label?.text?.getValue();
    if (!label || !entity.position) continue;
    try {
      const pos = entity.position.getValue(now);
      const c = Cesium.Cartographic.fromCartesian(pos);
      _waterBodies.push({
        name: label,
        lat: Cesium.Math.toDegrees(c.latitude),
        lon: Cesium.Math.toDegrees(c.longitude),
      });
    } catch (_) { /* skip */ }
  }
}

async function _loadCities(port) {
  try {
    const resp = await fetch(
      `http://localhost:${port}/geodata/ne_10m_populated_places.geojson`
    );
    const geojson = await resp.json();
    for (const feature of geojson.features) {
      const name = feature.properties?.NAME;
      const pop = feature.properties?.POP_MAX || 0;
      if (!name || !feature.geometry?.coordinates) continue;
      const [lon, lat] = feature.geometry.coordinates;
      _cities.push({ name, lat, lon, pop });
    }
    // Sort descending by population so we prefer larger cities on ties.
    _cities.sort((a, b) => b.pop - a.pop);
    console.log(`Reticle index: ${_cities.length} cities`);
  } catch (e) {
    console.warn('Failed to load cities for reticle label:', e);
  }
}

// ── Geometry helpers ────────────────────────────────────────────────────────

/** Ray-casting point-in-polygon (2D lat/lon). */
function pointInPolygon(lat, lon, ring) {
  let inside = false;
  for (let i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    const [yi, xi] = ring[i];
    const [yj, xj] = ring[j];
    if (
      ((yi > lat) !== (yj > lat)) &&
      (lon < ((xj - xi) * (lat - yi)) / (yj - yi) + xi)
    ) {
      inside = !inside;
    }
  }
  return inside;
}

/** Approximate angular distance in degrees (Euclidean on lat/lon). */
function angularDist(lat1, lon1, lat2, lon2) {
  const dLat = lat2 - lat1;
  const dLon = lon2 - lon1;
  return Math.sqrt(dLat * dLat + dLon * dLon);
}

// ── Query ───────────────────────────────────────────────────────────────────

/**
 * Determine the best label for the current screen center.
 *
 * @param {Cesium.Viewer} viewer
 * @returns {string} The label text, or '' if nothing identifiable.
 */
export function queryLabel(viewer) {
  if (!_ready) return '';

  const canvas = viewer.canvas;
  const center = new Cesium.Cartesian2(
    canvas.clientWidth / 2,
    canvas.clientHeight / 2
  );

  const cartesian = viewer.camera.pickEllipsoid(
    center, viewer.scene.globe.ellipsoid
  );
  if (!cartesian) return ''; // looking at sky

  const carto = Cesium.Cartographic.fromCartesian(cartesian);
  const lat = Cesium.Math.toDegrees(carto.latitude);
  const lon = Cesium.Math.toDegrees(carto.longitude);

  // ── Country lookup (point-in-polygon) ───────────────────────────────
  let country = null;
  for (const c of _countries) {
    for (const ring of c.rings) {
      if (pointInPolygon(lat, lon, ring)) {
        country = c.name;
        break;
      }
    }
    if (country) break;
  }

  // ── Nearest city within threshold ───────────────────────────────────
  const cityThreshold = 1.5; // ~165 km
  let nearestCity = null;
  let nearestCityDist = cityThreshold;
  for (const city of _cities) {
    const d = angularDist(lat, lon, city.lat, city.lon);
    if (d < nearestCityDist) {
      nearestCityDist = d;
      nearestCity = city;
    }
  }

  // ── Nearest water body ──────────────────────────────────────────────
  // Use a generous threshold when over water, tight when over land.
  const waterThreshold = country ? 1.0 : 20.0;
  let nearestWater = null;
  let nearestWaterDist = waterThreshold;
  for (const wb of _waterBodies) {
    const d = angularDist(lat, lon, wb.lat, wb.lon);
    if (d < nearestWaterDist) {
      nearestWaterDist = d;
      nearestWater = wb;
    }
  }

  // ── Compose label ───────────────────────────────────────────────────
  if (nearestCity && country) {
    return `${nearestCity.name}, ${country}`;
  }
  if (nearestCity) {
    return nearestCity.name;
  }
  if (!country && nearestWater) {
    return nearestWater.name;
  }
  if (country) {
    return country;
  }
  return '';
}

// ── Throttled update loop ───────────────────────────────────────────────────

/**
 * Start a periodic loop that queries the reticle label and sends changes
 * to Flutter via the bridge.
 *
 * @param {Cesium.Viewer} viewer
 * @param {number} intervalMs - update interval in milliseconds
 */
export function startLabelLoop(viewer, intervalMs = 500) {
  setInterval(() => {
    const label = queryLabel(viewer);
    if (label !== _lastLabel) {
      _lastLabel = label;
      if (window.flutter_inappwebview?.callHandler) {
        window.flutter_inappwebview.callHandler('RETICLE_LABEL', { label });
      }
    }
  }, intervalMs);
}
