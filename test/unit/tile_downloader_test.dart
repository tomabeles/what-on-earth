import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:what_on_earth/tile_cache/tile_downloader.dart';

void main() {
  group('TileDownloader.enumerateTiles', () {
    test('zoom 0 produces 1 tile', () {
      final tiles = TileDownloader.enumerateTiles(0, 0);
      expect(tiles, hasLength(1));
      expect(tiles.first.z, 0);
      expect(tiles.first.x, 0);
      expect(tiles.first.y, 0);
    });

    test('zoom 0-1 produces 5 tiles', () {
      final tiles = TileDownloader.enumerateTiles(0, 1);
      // zoom 0: 1, zoom 1: 4
      expect(tiles, hasLength(5));
    });

    test('zoom 0-2 produces 21 tiles', () {
      final tiles = TileDownloader.enumerateTiles(0, 2);
      // zoom 0: 1, zoom 1: 4, zoom 2: 16
      expect(tiles, hasLength(21));
    });

    test('zoom 0-5 produces 1365 tiles', () {
      final tiles = TileDownloader.enumerateTiles(0, 5);
      // 1 + 4 + 16 + 64 + 256 + 1024 = 1365
      expect(tiles, hasLength(1365));
    });

    test('single zoom 3 produces 64 tiles', () {
      final tiles = TileDownloader.enumerateTiles(3, 3);
      expect(tiles, hasLength(64));
    });
  });

  group('TileDownloader.downloadLayer', () {
    test('cancellation stops the download', () async {
      final cancelToken = CancelToken();
      final downloader = TileDownloader(
        dio: Dio(), // won't actually reach network
        concurrency: 1,
      );

      // Cancel immediately
      cancelToken.cancel('test cancel');

      final progress = <TileDownloadProgress>[];
      await downloader
          .downloadLayer(
            layerId: 'test',
            sourceUrlTemplate: 'http://invalid/{z}/{x}/{y}.png',
            documentsPath: Directory.systemTemp.path,
            minZoom: 0,
            maxZoom: 2,
            cancelToken: cancelToken,
          )
          .listen(progress.add)
          .asFuture<void>();

      // Should have completed 0 or very few tiles due to cancellation
      expect(progress.length, lessThanOrEqualTo(1));
    });

    test('skips existing files', () async {
      final tmpDir = await Directory.systemTemp.createTemp('tile_test_');
      try {
        // Pre-create a tile file
        final tileFile = File('${tmpDir.path}/tiles/test/0/0/0.png');
        await tileFile.parent.create(recursive: true);
        await tileFile.writeAsBytes([1, 2, 3]);

        final downloader = TileDownloader(
          dio: Dio(), // won't reach network for existing tiles
          concurrency: 1,
        );

        final progress = <TileDownloadProgress>[];
        await downloader
            .downloadLayer(
              layerId: 'test',
              sourceUrlTemplate: 'http://invalid/{z}/{x}/{y}.png',
              documentsPath: tmpDir.path,
              minZoom: 0,
              maxZoom: 0,
            )
            .listen(progress.add)
            .asFuture<void>();

        // The one tile at zoom 0 should be skipped (file exists), 0 bytes
        expect(progress.last.completedTiles, 1);
        expect(progress.last.bytesDownloaded, 0);
      } finally {
        await tmpDir.delete(recursive: true);
      }
    });
  });
}
