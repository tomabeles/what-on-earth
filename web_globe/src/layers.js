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

// ── Country borders + labels ────────────────────────────────────────────────

/**
 * Load Natural Earth country polygons, convert to border polylines, and add
 * a label at each country's centroid.
 *
 * @param {Cesium.Viewer} viewer
 * @param {number} assetServerPort
 */
export async function loadBorders(viewer, assetServerPort = 8080) {
  const url = `http://localhost:${assetServerPort}/geodata/ne_10m_admin_0_countries.geojson`;
  try {
    const ds = await Cesium.GeoJsonDataSource.load(url, {
      stroke: Cesium.Color.TRANSPARENT,
      fill: Cesium.Color.TRANSPARENT,
    });

    const borderColor = Cesium.Color.fromCssColorString('#ffcc00').withAlpha(0.7);
    const labelColor = Cesium.Color.WHITE;

    // First pass: find the largest polygon per country name so we only
    // label each country once (Natural Earth has many polygons per country
    // for islands/territories).
    const bestByName = new Map(); // name → { entity, posCount }
    for (const entity of ds.entities.values) {
      if (!entity.polygon) continue;
      const name = entity.properties?.NAME?.getValue();
      if (!name) continue;
      try {
        const hierarchy = entity.polygon.hierarchy.getValue(Cesium.JulianDate.now());
        const count = hierarchy?.positions?.length ?? 0;
        const prev = bestByName.get(name);
        if (!prev || count > prev.posCount) {
          bestByName.set(name, { entity, posCount: count });
        }
      } catch (_) { /* skip degenerate */ }
    }
    const labelEntities = new Set([...bestByName.values()].map(v => v.entity));

    // Second pass: convert polygons to polylines, add labels only on the
    // largest polygon per country.
    for (const entity of ds.entities.values) {
      // Convert polygon outlines to lightweight polylines (polygon fill is
      // transparent and degenerate geometries crash CesiumJS).
      if (entity.polygon) {
        try {
          const hierarchy = entity.polygon.hierarchy.getValue(Cesium.JulianDate.now());
          if (hierarchy?.positions?.length >= 2) {
            entity.polyline = new Cesium.PolylineGraphics({
              positions: hierarchy.positions,
              width: 1,
              material: borderColor,
            });

            // Only label the largest polygon for this country name.
            if (labelEntities.has(entity)) {
              const name = entity.properties?.NAME?.getValue();
              const centroid = Cesium.BoundingSphere.fromPoints(hierarchy.positions).center;
              Cesium.Cartesian3.normalize(centroid, centroid);
              const carto = Cesium.Cartographic.fromCartesian(centroid);
              const surfacePos = Cesium.Cartesian3.fromRadians(
                carto.longitude, carto.latitude, 0
              );

              entity.position = surfacePos;
              entity.label = new Cesium.LabelGraphics({
                text: name,
                font: '17px sans-serif',
                fillColor: labelColor,
                outlineColor: Cesium.Color.BLACK,
                outlineWidth: 3,
                style: Cesium.LabelStyle.FILL_AND_OUTLINE,
                verticalOrigin: Cesium.VerticalOrigin.CENTER,
                horizontalOrigin: Cesium.HorizontalOrigin.CENTER,
                distanceDisplayCondition: new Cesium.DistanceDisplayCondition(0, 3750000),
                scaleByDistance: new Cesium.NearFarScalar(500000, 1.2, 3750000, 0.4),
              });
            }
          }
        } catch (_) { /* skip degenerate polygon */ }
        entity.polygon = undefined;
      }

      // Remove any billboard that GeoJsonDataSource may have created
      if (entity.billboard) entity.billboard = undefined;
    }

    viewer.dataSources.add(ds);
    layersRegistry['borders'] = ds;
    console.log(`Loaded ${ds.entities.values.length} country borders`);
  } catch (e) {
    console.warn('Failed to load country borders:', e);
  }
}

// ── Water body labels ───────────────────────────────────────────────────────

/**
 * Load labels for oceans, seas, lakes, and major rivers.
 *
 * - Oceans/seas: centroid labels from ne_10m_geography_marine_polys
 * - Lakes: centroid labels from ne_10m_lakes
 * - Rivers: midpoint labels from ne_10m_rivers
 *
 * All geometry is stripped — only labels are rendered (no polygons or lines).
 *
 * @param {Cesium.Viewer} viewer
 * @param {number} assetServerPort
 */
export async function loadWaterLabels(viewer, assetServerPort = 8080) {
  const base = `http://localhost:${assetServerPort}/geodata`;
  const labelColor = Cesium.Color.fromCssColorString('#66ccff');
  const ds = new Cesium.CustomDataSource('water');

  // ── Oceans & Seas ─────────────────────────────────────────────────────
  try {
    const marine = await Cesium.GeoJsonDataSource.load(`${base}/ne_10m_geography_marine_polys.geojson`, {
      fill: Cesium.Color.TRANSPARENT,
      stroke: Cesium.Color.TRANSPARENT,
    });

    // Deduplicate: one label per name, using the largest polygon.
    const bestMarine = new Map();
    for (const entity of marine.entities.values) {
      const name = entity.properties?.NAME?.getValue();
      if (!name || !entity.polygon) continue;
      try {
        const hierarchy = entity.polygon.hierarchy.getValue(Cesium.JulianDate.now());
        const count = hierarchy?.positions?.length ?? 0;
        const prev = bestMarine.get(name);
        if (!prev || count > prev.count) {
          bestMarine.set(name, { entity, count });
        }
      } catch (_) { /* skip degenerate */ }
    }

    for (const [name, { entity }] of bestMarine) {
      try {
        const hierarchy = entity.polygon.hierarchy.getValue(Cesium.JulianDate.now());
        if (!hierarchy?.positions?.length) continue;
        const centroid = Cesium.BoundingSphere.fromPoints(hierarchy.positions).center;
        Cesium.Cartesian3.normalize(centroid, centroid);
        const carto = Cesium.Cartographic.fromCartesian(centroid);
        const surfacePos = Cesium.Cartesian3.fromRadians(carto.longitude, carto.latitude, 0);

        const scalerank = entity.properties?.scalerank?.getValue() ?? 0;
        const fontSize = scalerank <= 0 ? 18 : scalerank <= 2 ? 16 : 14;

        ds.entities.add({
          position: surfacePos,
          label: new Cesium.LabelGraphics({
            text: name,
            font: `italic ${fontSize}px sans-serif`,
            fillColor: labelColor,
            outlineColor: Cesium.Color.BLACK,
            outlineWidth: 3,
            style: Cesium.LabelStyle.FILL_AND_OUTLINE,
            verticalOrigin: Cesium.VerticalOrigin.CENTER,
            horizontalOrigin: Cesium.HorizontalOrigin.CENTER,
            distanceDisplayCondition: new Cesium.DistanceDisplayCondition(
              0, scalerank <= 0 ? 5000000 : 3750000
            ),
            scaleByDistance: new Cesium.NearFarScalar(500000, 1.2, 3750000, 0.4),
          }),
        });
      } catch (_) { /* skip */ }
    }
    console.log(`Water labels: ${bestMarine.size} ocean/sea labels`);
  } catch (e) {
    console.warn('Failed to load marine polys:', e);
  }

  // ── Lakes ─────────────────────────────────────────────────────────────
  try {
    const lakes = await Cesium.GeoJsonDataSource.load(`${base}/ne_10m_lakes.geojson`, {
      fill: Cesium.Color.TRANSPARENT,
      stroke: Cesium.Color.TRANSPARENT,
    });

    const bestLake = new Map();
    for (const entity of lakes.entities.values) {
      const name = entity.properties?.NAME?.getValue();
      if (!name || !entity.polygon) continue;
      try {
        const hierarchy = entity.polygon.hierarchy.getValue(Cesium.JulianDate.now());
        const count = hierarchy?.positions?.length ?? 0;
        const prev = bestLake.get(name);
        if (!prev || count > prev.count) {
          bestLake.set(name, { entity, count });
        }
      } catch (_) { /* skip */ }
    }

    for (const [name, { entity }] of bestLake) {
      try {
        const hierarchy = entity.polygon.hierarchy.getValue(Cesium.JulianDate.now());
        if (!hierarchy?.positions?.length) continue;
        const centroid = Cesium.BoundingSphere.fromPoints(hierarchy.positions).center;
        Cesium.Cartesian3.normalize(centroid, centroid);
        const carto = Cesium.Cartographic.fromCartesian(centroid);
        const surfacePos = Cesium.Cartesian3.fromRadians(carto.longitude, carto.latitude, 0);

        ds.entities.add({
          position: surfacePos,
          label: new Cesium.LabelGraphics({
            text: name,
            font: 'italic 14px sans-serif',
            fillColor: labelColor,
            outlineColor: Cesium.Color.BLACK,
            outlineWidth: 2,
            style: Cesium.LabelStyle.FILL_AND_OUTLINE,
            verticalOrigin: Cesium.VerticalOrigin.CENTER,
            horizontalOrigin: Cesium.HorizontalOrigin.CENTER,
            distanceDisplayCondition: new Cesium.DistanceDisplayCondition(0, 2000000),
            scaleByDistance: new Cesium.NearFarScalar(200000, 1.0, 2000000, 0.3),
          }),
        });
      } catch (_) { /* skip */ }
    }
    console.log(`Water labels: ${bestLake.size} lake labels`);
  } catch (e) {
    console.warn('Failed to load lakes:', e);
  }

  // ── Rivers ────────────────────────────────────────────────────────────
  try {
    const rivers = await Cesium.GeoJsonDataSource.load(`${base}/ne_10m_rivers.geojson`, {
      stroke: Cesium.Color.TRANSPARENT,
    });

    // Deduplicate river names (many segments share the same name).
    const bestRiver = new Map();
    for (const entity of rivers.entities.values) {
      const name = entity.properties?.NAME?.getValue();
      if (!name || !entity.polyline) continue;
      try {
        const positions = entity.polyline.positions.getValue(Cesium.JulianDate.now());
        const count = positions?.length ?? 0;
        const prev = bestRiver.get(name);
        if (!prev || count > prev.count) {
          bestRiver.set(name, { entity, count, positions });
        }
      } catch (_) { /* skip */ }
    }

    for (const [name, { positions }] of bestRiver) {
      if (!positions || positions.length < 2) continue;
      // Place label at the midpoint of the longest segment.
      const midIdx = Math.floor(positions.length / 2);
      const midPos = positions[midIdx];

      ds.entities.add({
        position: midPos,
        label: new Cesium.LabelGraphics({
          text: name,
          font: 'italic 13px sans-serif',
          fillColor: labelColor,
          outlineColor: Cesium.Color.BLACK,
          outlineWidth: 2,
          style: Cesium.LabelStyle.FILL_AND_OUTLINE,
          verticalOrigin: Cesium.VerticalOrigin.CENTER,
          horizontalOrigin: Cesium.HorizontalOrigin.CENTER,
          distanceDisplayCondition: new Cesium.DistanceDisplayCondition(0, 1500000),
          scaleByDistance: new Cesium.NearFarScalar(200000, 1.0, 1500000, 0.3),
        }),
      });
    }
    console.log(`Water labels: ${bestRiver.size} river labels`);
  } catch (e) {
    console.warn('Failed to load rivers:', e);
  }

  viewer.dataSources.add(ds);
  layersRegistry['water'] = ds;
  console.log(`Water labels layer loaded (${ds.entities.values.length} total labels)`);
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
  // Probe whether the local tile server is running and has tiles.
  let localAvailable = false;
  const probeUrl = `http://localhost:${tileServerPort}/`;
  try {
    const resp = await fetch(probeUrl, { signal: AbortSignal.timeout(500) });
    localAvailable = resp.ok;
    console.log(`Tile server probe ${probeUrl} → ${resp.status} (localAvailable=${localAvailable})`);
  } catch (e) {
    console.log(`Tile server probe ${probeUrl} failed:`, e.message || e);
  }

  // ── Base layer: satellite imagery (ESRI) or OSM fallback ──────────────
  const baseUrl = localAvailable
    ? `http://localhost:${tileServerPort}/tiles/satellite/{z}/{x}/{y}.jpg`
    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  console.log(`Raster base URL: ${baseUrl}`);

  const baseProvider = new Cesium.UrlTemplateImageryProvider({
    url: baseUrl,
    minimumLevel: 0,
    maximumLevel: localAvailable ? 7 : 7,
    tilingScheme: new Cesium.WebMercatorTilingScheme(),
    credit: localAvailable ? 'Esri World Imagery' : 'OpenStreetMap contributors',
  });
  const baseLayer = viewer.imageryLayers.addImageryProvider(baseProvider);
  layersRegistry['base'] = baseLayer;

  if (!localAvailable) {
    console.log('Tile server not available — using online OSM tiles');
  }

  // ── Night lights layer: NASA VIIRS Black Marble (local only) ──────────
  if (localAvailable) {
    const nightProvider = new Cesium.UrlTemplateImageryProvider({
      url: `http://localhost:${tileServerPort}/tiles/nightlights/{z}/{x}/{y}.png`,
      minimumLevel: 0,
      maximumLevel: 7,
      tilingScheme: new Cesium.WebMercatorTilingScheme(),
      credit: 'NASA VIIRS Black Marble',
    });
    const nightLayer = viewer.imageryLayers.addImageryProvider(nightProvider);
    nightLayer.show = false;
    layersRegistry['nightlights'] = nightLayer;
    console.log('Night lights layer available (hidden by default)');
  }

  // ── Dark Matter layer: CartoDB dark-themed map (local only) ─────────
  if (localAvailable) {
    const darkProvider = new Cesium.UrlTemplateImageryProvider({
      url: `http://localhost:${tileServerPort}/tiles/darkmatter/{z}/{x}/{y}.png`,
      minimumLevel: 0,
      maximumLevel: 7,
      tilingScheme: new Cesium.WebMercatorTilingScheme(),
      credit: 'CartoDB Dark Matter',
    });
    const darkLayer = viewer.imageryLayers.addImageryProvider(darkProvider);
    darkLayer.show = false;
    layersRegistry['darkmatter'] = darkLayer;
    console.log('Dark Matter layer available (hidden by default)');
  }

  // ── Blue Marble layer: NASA Blue Marble Next Generation (local only) ─
  if (localAvailable) {
    const bmProvider = new Cesium.UrlTemplateImageryProvider({
      url: `http://localhost:${tileServerPort}/tiles/bluemarble/{z}/{x}/{y}.jpeg`,
      minimumLevel: 0,
      maximumLevel: 7,
      tilingScheme: new Cesium.WebMercatorTilingScheme(),
      credit: 'NASA Blue Marble',
    });
    const bmLayer = viewer.imageryLayers.addImageryProvider(bmProvider);
    bmLayer.show = false;
    layersRegistry['bluemarble'] = bmLayer;
    console.log('Blue Marble layer available (hidden by default)');
  }
}
