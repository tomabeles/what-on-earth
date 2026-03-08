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

  // Country borders — white polylines
  try {
    const borders = await Cesium.GeoJsonDataSource.load(`${base}/ne_10m_admin_0_countries.geojson`, {
      stroke: Cesium.Color.WHITE.withAlpha(0.7),
      strokeWidth: 1,
      fill: Cesium.Color.TRANSPARENT,
    });
    viewer.dataSources.add(borders);
    layersRegistry['borders'] = borders;
  } catch (e) {
    console.warn('Failed to load country borders:', e);
  }

  // Coastlines — light blue polylines
  try {
    const coastlines = await Cesium.GeoJsonDataSource.load(`${base}/ne_10m_coastline.geojson`, {
      stroke: Cesium.Color.fromCssColorString('#6ab0cc'),
      strokeWidth: 1.5,
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
    // Style labels: only show for cities with POP_MAX > 500000
    const entities = cities.entities.values;
    for (let i = 0; i < entities.length; i++) {
      const entity = entities[i];
      const popMax = entity.properties?.POP_MAX?.getValue();
      if (entity.label) {
        entity.label.show = popMax > 500000;
        entity.label.font = '11px sans-serif';
        entity.label.fillColor = Cesium.Color.WHITE;
        entity.label.outlineColor = Cesium.Color.BLACK;
        entity.label.outlineWidth = 2;
        entity.label.style = Cesium.LabelStyle.FILL_AND_OUTLINE;
        entity.label.pixelOffset = new Cesium.Cartesian2(0, -8);
        entity.label.distanceDisplayCondition =
          new Cesium.DistanceDisplayCondition(0, 15000000);
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
 * Configure raster imagery layers pointing at the local tile server.
 *
 * @param {Cesium.Viewer} viewer
 * @param {number} tileServerPort - port of the tile server (default 8765)
 */
export function loadRasterLayers(viewer, tileServerPort = 8765) {
  // Base layer (e.g. OpenStreetMap tiles cached locally)
  const baseProvider = new Cesium.UrlTemplateImageryProvider({
    url: `http://localhost:${tileServerPort}/tiles/base/{z}/{x}/{y}.png`,
    minimumLevel: 0,
    maximumLevel: 5,
    tilingScheme: new Cesium.WebMercatorTilingScheme(),
    credit: 'OpenStreetMap contributors',
  });
  const baseLayer = viewer.imageryLayers.addImageryProvider(baseProvider);
  layersRegistry['base'] = baseLayer;

  // Relief layer
  const reliefProvider = new Cesium.UrlTemplateImageryProvider({
    url: `http://localhost:${tileServerPort}/tiles/relief/{z}/{x}/{y}.png`,
    minimumLevel: 0,
    maximumLevel: 5,
    tilingScheme: new Cesium.WebMercatorTilingScheme(),
    credit: 'Natural Earth',
  });
  const reliefLayer = viewer.imageryLayers.addImageryProvider(reliefProvider);
  reliefLayer.show = false; // hidden by default, toggled via TOGGLE_LAYER
  layersRegistry['relief'] = reliefLayer;
}
