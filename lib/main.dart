import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'app.dart';
import 'position/tle_manager.dart';
import 'position/tle_refresh_daemon.dart';
import 'tile_cache/tile_downloader.dart';
import 'tile_cache/tile_server.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(true);
  }

  final docsDir = await getApplicationDocumentsDirectory();
  await TleRefreshDaemon.init(TleManager.create(docsDir));

  // Start the local tile server so CesiumJS can use cached tiles.
  final tileServer = TileServer();
  await tileServer.start(docsDir.path);

  // Kick off base tile download in the background. Tiles accumulate on disk
  // and will be served on subsequent app launches (or within this session once
  // the download reaches the root tile that the health probe checks).
  _downloadTileLayers(docsDir.path);

  runApp(
    const ProviderScope(
      child: WhatOnEarthApp(),
    ),
  );
}

void _downloadTileLayers(String documentsPath) {
  final downloader = TileDownloader();

  // Satellite imagery (ESRI World Imagery) — primary base layer.
  // Note: ESRI uses {z}/{y}/{x} order in the URL (Y before X).
  downloader
      .downloadLayer(
        layerId: 'satellite',
        sourceUrlTemplate:
            'https://server.arcgisonline.com/ArcGIS/rest/services/'
            'World_Imagery/MapServer/tile/{z}/{y}/{x}',
        documentsPath: documentsPath,
        minZoom: 0,
        maxZoom: 6,
        ext: 'jpg',
      )
      .listen(
        (p) {
          if (p.completedTiles % 100 == 0 ||
              p.completedTiles == p.totalTiles) {
            debugPrint('TileDownload [satellite]: '
                '${p.completedTiles}/${p.totalTiles} '
                '(${(p.fraction * 100).toStringAsFixed(1)}%)');
          }
        },
        onError: (Object e) => debugPrint('TileDownload [satellite] error: $e'),
        onDone: () {
          // After satellite tiles finish, download night lights.
          _downloadNightLights(downloader, documentsPath);
        },
      );
}

void _downloadNightLights(TileDownloader downloader, String documentsPath) {
  // NASA VIIRS Black Marble (2016 composite) — city lights at night.
  downloader
      .downloadLayer(
        layerId: 'nightlights',
        sourceUrlTemplate:
            'https://gibs.earthdata.nasa.gov/wmts/epsg3857/best/'
            'VIIRS_Black_Marble/default/2016-01-01/'
            'GoogleMapsCompatible_Level8/{z}/{y}/{x}.png',
        documentsPath: documentsPath,
        minZoom: 0,
        maxZoom: 6,
      )
      .listen(
        (p) {
          if (p.completedTiles % 100 == 0 ||
              p.completedTiles == p.totalTiles) {
            debugPrint('TileDownload [nightlights]: '
                '${p.completedTiles}/${p.totalTiles} '
                '(${(p.fraction * 100).toStringAsFixed(1)}%)');
          }
        },
        onError: (Object e) =>
            debugPrint('TileDownload [nightlights] error: $e'),
      );
}
