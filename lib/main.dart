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
  _downloadBaseTiles(docsDir.path);

  runApp(
    const ProviderScope(
      child: WhatOnEarthApp(),
    ),
  );
}

void _downloadBaseTiles(String documentsPath) {
  final downloader = TileDownloader();
  downloader
      .downloadLayer(
        layerId: 'base',
        sourceUrlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        documentsPath: documentsPath,
        minZoom: 0,
        maxZoom: 5,
      )
      .listen(
        (progress) {
          if (progress.completedTiles % 100 == 0 ||
              progress.completedTiles == progress.totalTiles) {
            debugPrint(
              'TileDownload: ${progress.completedTiles}/${progress.totalTiles}'
              ' (${(progress.fraction * 100).toStringAsFixed(1)}%)',
            );
          }
        },
        onError: (Object e) => debugPrint('TileDownload error: $e'),
      );
}
