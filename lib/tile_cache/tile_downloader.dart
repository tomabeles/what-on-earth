import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Progress snapshot for a tile download batch.
class TileDownloadProgress {
  final int completedTiles;
  final int totalTiles;
  final int bytesDownloaded;

  const TileDownloadProgress({
    required this.completedTiles,
    required this.totalTiles,
    required this.bytesDownloaded,
  });

  double get fraction =>
      totalTiles > 0 ? completedTiles / totalTiles : 0.0;
}

/// A single tile coordinate in the XYZ scheme.
class TileCoordinate {
  final int z;
  final int x;
  final int y;
  const TileCoordinate(this.z, this.x, this.y);
}

/// Downloads raster tiles from remote servers and stores them on disk
/// in the structure expected by [TileServer] (TECH_SPEC §7.3).
///
/// Tiles are saved to `{documentsPath}/tiles/{layerId}/{z}/{x}/{y}.{ext}`.
class TileDownloader {
  final Dio _dio;

  /// Maximum concurrent downloads.
  final int concurrency;

  TileDownloader({Dio? dio, this.concurrency = 4})
      : _dio = dio ??
            Dio(BaseOptions(headers: {
              // OSM tile usage policy requires a descriptive User-Agent.
              'User-Agent': 'WhatOnEarth/1.0 (tile prefetch)',
            }));

  /// Enumerate all tile coordinates for a Web Mercator tileset across
  /// the given zoom range.
  ///
  /// At zoom z, there are 2^z × 2^z tiles.
  static List<TileCoordinate> enumerateTiles(int minZoom, int maxZoom) {
    final tiles = <TileCoordinate>[];
    for (var z = minZoom; z <= maxZoom; z++) {
      final count = 1 << z; // 2^z
      for (var x = 0; x < count; x++) {
        for (var y = 0; y < count; y++) {
          tiles.add(TileCoordinate(z, x, y));
        }
      }
    }
    return tiles;
  }

  /// Download all tiles for [layerId] at zoom levels [minZoom]..[maxZoom].
  ///
  /// [sourceUrlTemplate] uses `{z}`, `{x}`, `{y}` placeholders, e.g.
  /// `https://tile.openstreetmap.org/{z}/{x}/{y}.png`.
  ///
  /// [ext] is the file extension to use when saving (e.g. `png`, `webp`).
  ///
  /// Returns a stream of [TileDownloadProgress] updates.
  /// The download can be cancelled by setting [cancelToken].
  Stream<TileDownloadProgress> downloadLayer({
    required String layerId,
    required String sourceUrlTemplate,
    required String documentsPath,
    required int minZoom,
    required int maxZoom,
    String ext = 'png',
    CancelToken? cancelToken,
  }) {
    final controller = StreamController<TileDownloadProgress>();
    _runDownload(
      layerId: layerId,
      sourceUrlTemplate: sourceUrlTemplate,
      documentsPath: documentsPath,
      minZoom: minZoom,
      maxZoom: maxZoom,
      ext: ext,
      cancelToken: cancelToken,
      controller: controller,
    );
    return controller.stream;
  }

  Future<void> _runDownload({
    required String layerId,
    required String sourceUrlTemplate,
    required String documentsPath,
    required int minZoom,
    required int maxZoom,
    required String ext,
    required CancelToken? cancelToken,
    required StreamController<TileDownloadProgress> controller,
  }) async {
    final tiles = enumerateTiles(minZoom, maxZoom);
    var completed = 0;
    var bytesDownloaded = 0;

    // Process tiles sequentially in batches of [concurrency].
    for (var i = 0; i < tiles.length; i += concurrency) {
      if (cancelToken?.isCancelled ?? false) break;

      final batch = tiles.skip(i).take(concurrency);
      await Future.wait(batch.map((tile) async {
        if (cancelToken?.isCancelled ?? false) return;
        final bytes = await _downloadTile(
          layerId: layerId,
          sourceUrlTemplate: sourceUrlTemplate,
          documentsPath: documentsPath,
          tile: tile,
          ext: ext,
          cancelToken: cancelToken,
        );
        completed++;
        bytesDownloaded += bytes;
        if (!controller.isClosed) {
          controller.add(TileDownloadProgress(
            completedTiles: completed,
            totalTiles: tiles.length,
            bytesDownloaded: bytesDownloaded,
          ));
        }
      }));
    }

    await controller.close();
  }

  /// Download a single tile. Returns bytes written.
  /// Retries once on failure. Returns 0 if both attempts fail.
  Future<int> _downloadTile({
    required String layerId,
    required String sourceUrlTemplate,
    required String documentsPath,
    required TileCoordinate tile,
    required String ext,
    CancelToken? cancelToken,
  }) async {
    final filePath =
        '$documentsPath/tiles/$layerId/${tile.z}/${tile.x}/${tile.y}.$ext';

    // Skip if file already exists on disk
    if (File(filePath).existsSync()) return 0;

    final url = sourceUrlTemplate
        .replaceAll('{z}', '${tile.z}')
        .replaceAll('{x}', '${tile.x}')
        .replaceAll('{y}', '${tile.y}');

    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await _dio.get<List<int>>(
          url,
          options: Options(responseType: ResponseType.bytes),
          cancelToken: cancelToken,
        );
        final bytes = response.data!;
        final file = File(filePath);
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes);
        return bytes.length;
      } on DioException catch (e) {
        if (e.type == DioExceptionType.cancel) rethrow;
        if (attempt == 0) {
          await Future<void>.delayed(const Duration(seconds: 1));
          continue;
        }
        debugPrint('TileDownloader: failed $url after 2 attempts: $e');
        return 0;
      }
    }
    return 0;
  }
}
