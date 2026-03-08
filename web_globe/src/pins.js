// pins.js — CesiumJS pin entity rendering (TECH_SPEC §7.4)
//
// Renders user pins as billboard + label entities on the globe surface.
// Called via SYNC_PINS bridge message with the full pin list.

import * as Cesium from 'cesium';

let _pinDataSource = null;

// 5 icon colors for V1 — simple circle markers as SVG data URIs.
const ICON_COLORS = ['#FFFFFF', '#FFC107', '#F44336', '#4CAF50', '#2196F3'];

function _makeMarkerSvg(color) {
  return `data:image/svg+xml,${encodeURIComponent(
    `<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16">` +
    `<circle cx="8" cy="8" r="6" fill="${color}" stroke="#000" stroke-width="1.5"/>` +
    `</svg>`
  )}`;
}

const ICON_URIS = ICON_COLORS.map(_makeMarkerSvg);

/**
 * Clear all existing pin entities and re-render from the provided list.
 *
 * @param {Cesium.Viewer} viewer
 * @param {Array<{id: string, lat: number, lon: number, name: string, iconId: number}>} pins
 */
export function syncPins(viewer, pins) {
  if (!_pinDataSource) {
    _pinDataSource = new Cesium.CustomDataSource('pins');
    viewer.dataSources.add(_pinDataSource);
  }

  _pinDataSource.entities.removeAll();

  for (const pin of pins) {
    const iconIdx = (pin.iconId ?? 0) % ICON_URIS.length;
    _pinDataSource.entities.add({
      id: pin.id,
      position: Cesium.Cartesian3.fromDegrees(pin.lon, pin.lat),
      billboard: {
        image: ICON_URIS[iconIdx],
        width: 16,
        height: 16,
        verticalOrigin: Cesium.VerticalOrigin.CENTER,
        disableDepthTestDistance: Number.POSITIVE_INFINITY,
      },
      label: {
        text: pin.name,
        font: '11px sans-serif',
        fillColor: Cesium.Color.WHITE,
        outlineColor: Cesium.Color.BLACK,
        outlineWidth: 2,
        style: Cesium.LabelStyle.FILL_AND_OUTLINE,
        pixelOffset: new Cesium.Cartesian2(0, -12),
        distanceDisplayCondition: new Cesium.DistanceDisplayCondition(0, 15000000),
        disableDepthTestDistance: Number.POSITIVE_INFINITY,
      },
    });
  }
}
