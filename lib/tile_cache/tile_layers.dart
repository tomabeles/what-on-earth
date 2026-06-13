/// Single source of truth for downloadable tile layers (TECH_SPEC §7.5).
///
/// Consumed by the startup background download in `main.dart` and the
/// onboarding tile download step. Add or edit layer URLs/metadata here only.
class TileLayerConfig {
  final String id;
  final String displayName;

  /// Approximate on-disk size of zoom 0–5, shown in the onboarding picker.
  final double estimatedSizeMb;
  final String urlTemplate;
  final String fileExtension;

  /// Whether the layer is offered in the onboarding download step.
  /// Layers not shown there are still downloaded in the background on launch.
  final bool showInOnboarding;

  const TileLayerConfig({
    required this.id,
    required this.displayName,
    required this.estimatedSizeMb,
    required this.urlTemplate,
    required this.fileExtension,
    this.showInOnboarding = true,
  });
}

const kTileLayers = <TileLayerConfig>[
  // Satellite imagery (ESRI World Imagery) — primary base layer.
  // Note: ESRI uses {z}/{y}/{x} order in the URL (Y before X).
  TileLayerConfig(
    id: 'satellite',
    displayName: 'Satellite Imagery',
    estimatedSizeMb: 150,
    urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/'
        'World_Imagery/MapServer/tile/{z}/{y}/{x}',
    fileExtension: 'jpg',
  ),
  // NASA VIIRS Black Marble (2016 composite) — city lights at night.
  TileLayerConfig(
    id: 'nightlights',
    displayName: 'Night Lights',
    estimatedSizeMb: 80,
    urlTemplate: 'https://gibs.earthdata.nasa.gov/wmts/epsg3857/best/'
        'VIIRS_Black_Marble/default/2016-01-01/'
        'GoogleMapsCompatible_Level8/{z}/{y}/{x}.png',
    fileExtension: 'png',
  ),
  // CartoDB Dark Matter — minimal dark-themed political map.
  TileLayerConfig(
    id: 'darkmatter',
    displayName: 'Dark Map',
    estimatedSizeMb: 40,
    urlTemplate: 'https://cartodb-basemaps-a.global.ssl.fastly.net/'
        'dark_nolabels/{z}/{x}/{y}.png',
    fileExtension: 'png',
  ),
  // NASA Blue Marble Next Generation — classic cloud-free Earth composite.
  TileLayerConfig(
    id: 'bluemarble',
    displayName: 'Blue Marble',
    estimatedSizeMb: 30,
    urlTemplate: 'https://gibs.earthdata.nasa.gov/wmts/epsg3857/best/'
        'BlueMarble_NextGeneration/default/'
        'GoogleMapsCompatible_Level8/{z}/{y}/{x}.jpeg',
    fileExtension: 'jpeg',
    showInOnboarding: false,
  ),
];
