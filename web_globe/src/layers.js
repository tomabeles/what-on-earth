// layers.js — CesiumJS vector and raster layer management (TECH_SPEC §3.5, §4.5)
//
// Vector layers: Natural Earth GeoJSON served from the globe asset server.
// Raster layers: XYZ tiles served from the tile server on a separate port.

import * as Cesium from 'cesium';

/// Registry of all layers by ID. Used by TOGGLE_LAYER to show/hide.
export const layersRegistry = {};

// ── Vector layers (WOE-026) ─────────────────────────────────────────────────

/**
 * Load and style the four Natural Earth GeoJSON layers.
 *
 * @param {Cesium.Viewer} viewer
 * @param {number} assetServerPort - port of the globe asset server (default 8080)
 */
export async function loadVectorLayers(viewer, assetServerPort = 8080) {
  const base = `http://localhost:${assetServerPort}/geodata`;

  // Country borders — bright yellow polylines for visibility at orbital altitude
  try {
    const borders = await Cesium.GeoJsonDataSource.load(`${base}/ne_10m_admin_0_countries.geojson`, {
      stroke: Cesium.Color.YELLOW,
      strokeWidth: 1,
      fill: Cesium.Color.TRANSPARENT,
    });
    // Strip polygon geometry entirely — fill is transparent so polygon
    // primitives serve no purpose and degenerate Natural Earth polygons
    // crash CesiumJS createGeometry (undefined .length errors).
    // Convert outlines to lightweight polylines instead.
    const borderColor = Cesium.Color.fromCssColorString('#ffcc00').withAlpha(0.9);
    for (const entity of borders.entities.values) {
      if (entity.polygon) {
        try {
          const hierarchy = entity.polygon.hierarchy.getValue(Cesium.JulianDate.now());
          if (hierarchy?.positions?.length >= 2) {
            entity.polyline = new Cesium.PolylineGraphics({
              positions: hierarchy.positions,
              width: 2,
              material: borderColor,
            });
          }
        } catch (_) { /* skip degenerate */ }
        entity.polygon = undefined;
      }
    }
    viewer.dataSources.add(borders);
    layersRegistry['borders'] = borders;
  } catch (e) {
    console.warn('Failed to load country borders:', e);
  }

  // Coastlines — cyan polylines
  try {
    const coastlines = await Cesium.GeoJsonDataSource.load(`${base}/ne_10m_coastline.geojson`, {
      stroke: Cesium.Color.fromCssColorString('#00e5ff'),
      strokeWidth: 2,
      fill: Cesium.Color.TRANSPARENT,
    });
    viewer.dataSources.add(coastlines);
    layersRegistry['coastlines'] = coastlines;
  } catch (e) {
    console.warn('Failed to load coastlines:', e);
  }

  // Lakes — semi-transparent blue polygons
  try {
    const lakes = await Cesium.GeoJsonDataSource.load(`${base}/ne_10m_lakes.geojson`, {
      fill: Cesium.Color.fromCssColorString('#1a4a6b').withAlpha(0.6),
      stroke: Cesium.Color.TRANSPARENT,
      strokeWidth: 0,
    });
    // GeoJsonDataSource hardcodes arcType = RHUMB, which crashes on
    // degenerate Natural Earth polygons in subdivideRhumbLine.
    // Override to GEODESIC (NONE is invalid for polygon geometry).
    const toRemove = [];
    for (const entity of lakes.entities.values) {
      if (entity.polygon) {
        try {
          const hierarchy = entity.polygon.hierarchy.getValue(Cesium.JulianDate.now());
          if (!hierarchy?.positions || hierarchy.positions.length < 3) {
            toRemove.push(entity);
          } else {
            entity.polygon.arcType = Cesium.ArcType.GEODESIC;
          }
        } catch (_) {
          toRemove.push(entity);
        }
      }
    }
    toRemove.forEach(e => lakes.entities.remove(e));
    viewer.dataSources.add(lakes);
    layersRegistry['lakes'] = lakes;
  } catch (e) {
    console.warn('Failed to load lakes:', e);
  }

  // City points — white dots with name labels for large cities
  try {
    const cities = await Cesium.GeoJsonDataSource.load(`${base}/ne_10m_populated_places.geojson`, {
      markerSize: 4,
      markerColor: Cesium.Color.WHITE,
    });
    // Style labels: only show for major cities (POP_MAX > 1M at orbit altitude)
    const entities = cities.entities.values;
    for (let i = 0; i < entities.length; i++) {
      const entity = entities[i];
      const popMax = entity.properties?.POP_MAX?.getValue();
      if (entity.label) {
        entity.label.show = popMax > 1000000;
        entity.label.font = '14px sans-serif';
        entity.label.fillColor = Cesium.Color.WHITE;
        entity.label.outlineColor = Cesium.Color.BLACK;
        entity.label.outlineWidth = 3;
        entity.label.style = Cesium.LabelStyle.FILL_AND_OUTLINE;
        entity.label.pixelOffset = new Cesium.Cartesian2(0, -10);
        entity.label.distanceDisplayCondition =
          new Cesium.DistanceDisplayCondition(0, 20000000);
        entity.label.scaleByDistance =
          new Cesium.NearFarScalar(100000, 1.5, 5000000, 0.5);
      }
      // Scale markers for orbital viewing
      if (entity.billboard) {
        entity.billboard.scaleByDistance =
          new Cesium.NearFarScalar(100000, 2.0, 5000000, 0.5);
      }
    }
    viewer.dataSources.add(cities);
    layersRegistry['cities'] = cities;
  } catch (e) {
    console.warn('Failed to load cities:', e);
  }
}

// ── Raster tile layers (WOE-029) ────────────────────────────────────────────

/**
 * Configure raster imagery layers.
 *
 * Tries the local tile server first; falls back to online OSM tiles if the
 * local server isn't reachable. The relief layer uses local tiles only
 * (no online fallback) and is hidden by default.
 *
 * @param {Cesium.Viewer} viewer
 * @param {number} tileServerPort - port of the tile server (default 8765)
 */
export async function loadRasterLayers(viewer, tileServerPort = 8765) {
  // Probe whether the local tile server is running.
  let localAvailable = false;
  try {
    const resp = await fetch(`http://localhost:${tileServerPort}/`, { signal: AbortSignal.timeout(500) });
    localAvailable = resp.ok;
  } catch (_) { /* server not running */ }

  const baseUrl = localAvailable
    ? `http://localhost:${tileServerPort}/tiles/base/{z}/{x}/{y}.png`
    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  const baseProvider = new Cesium.UrlTemplateImageryProvider({
    url: baseUrl,
    minimumLevel: 0,
    maximumLevel: localAvailable ? 5 : 6,
    tilingScheme: new Cesium.WebMercatorTilingScheme(),
    credit: 'OpenStreetMap contributors',
  });
  const baseLayer = viewer.imageryLayers.addImageryProvider(baseProvider);
  layersRegistry['base'] = baseLayer;

  if (!localAvailable) {
    console.log('Tile server not available — using online OSM tiles');
  }

  // Relief layer (local tiles only, hidden by default)
  if (localAvailable) {
    const reliefProvider = new Cesium.UrlTemplateImageryProvider({
      url: `http://localhost:${tileServerPort}/tiles/relief/{z}/{x}/{y}.png`,
      minimumLevel: 0,
      maximumLevel: 5,
      tilingScheme: new Cesium.WebMercatorTilingScheme(),
      credit: 'Natural Earth',
    });
    const reliefLayer = viewer.imageryLayers.addImageryProvider(reliefProvider);
    reliefLayer.show = false;
    layersRegistry['relief'] = reliefLayer;
  }
}
