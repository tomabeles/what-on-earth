// Integration test: TileServer + TileDownloader full pipeline.
// Verifies that tiles downloaded by TileDownloader are correctly served by
// TileServer, and that the health probe reflects tile availability.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:what_on_earth/tile_cache/tile_downloader.dart';
import 'package:what_on_earth/tile_cache/tile_server.dart';

/// A tiny HTTP server that serves fake tile PNGs so TileDownloader has a
/// real upstream to fetch from without hitting the internet.
class _FakeTileOrigin {
  HttpServer? _server;
  int get port => _server!.port;

  Future<void> start() async {
    _server = await HttpServer.bind('localhost', 0);
    _server!.listen((request) {
      // Return a small PNG-like payload for any request path.
      final fakePayload = [137, 80, 78, 71, 13, 10, 26, 10]; // PNG header
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType('image', 'png')
        ..add(fakePayload)
        ..close();
    });
  }

  Future<void> stop() async {
    await _server?.close(force: true);
  }
}

void main() {
  group('Tile pipeline integration', () {
    late Directory tmpDir;
    late TileServer tileServer;
    late _FakeTileOrigin origin;

    setUp(() async {
      tmpDir = await Directory.systemTemp.createTemp('tile_pipeline_test_');
      origin = _FakeTileOrigin();
      await origin.start();
    });

    tearDown(() async {
      tileServer.stop();
      await origin.stop();
      if (tmpDir.existsSync()) await tmpDir.delete(recursive: true);
    });

    test('health probe transitions from 404 to 200 after download', () async {
      tileServer = TileServer(port: 19765);
      await tileServer.start(tmpDir.path);

      final client = HttpClient();

      // Before download: health probe should return 404
      var request =
          await client.getUrl(Uri.parse('http://localhost:19765/'));
      var response = await request.close();
      expect(response.statusCode, 404,
          reason: 'Health probe should fail before tiles are downloaded');

      // Download tiles (zoom 0 only = 1 tile, fast)
      final downloader = TileDownloader(concurrency: 1);
      await downloader
          .downloadLayer(
            layerId: 'base',
            sourceUrlTemplate:
                'http://localhost:${origin.port}/{z}/{x}/{y}.png',
            documentsPath: tmpDir.path,
            minZoom: 0,
            maxZoom: 0,
          )
          .drain<void>();

      // After download: health probe should return 200
      request = await client.getUrl(Uri.parse('http://localhost:19765/'));
      response = await request.close();
      expect(response.statusCode, 200,
          reason: 'Health probe should succeed after base tiles downloaded');

      client.close();
    });

    test('downloaded tiles are served correctly', () async {
      // Download a small set of tiles (zoom 0-1 = 5 tiles)
      final downloader = TileDownloader(concurrency: 2);
      final progressUpdates = <TileDownloadProgress>[];
      await downloader
          .downloadLayer(
            layerId: 'base',
            sourceUrlTemplate:
                'http://localhost:${origin.port}/{z}/{x}/{y}.png',
            documentsPath: tmpDir.path,
            minZoom: 0,
            maxZoom: 1,
          )
          .listen(progressUpdates.add)
          .asFuture<void>();

      // Verify download completed
      expect(progressUpdates.last.completedTiles, 5);
      expect(progressUpdates.last.totalTiles, 5);

      // Start tile server
      tileServer = TileServer(port: 19766);
      await tileServer.start(tmpDir.path);

      final client = HttpClient();

      // Fetch each tile through the server and verify it's served
      for (final coord in TileDownloader.enumerateTiles(0, 1)) {
        final url =
            'http://localhost:19766/tiles/base/${coord.z}/${coord.x}/${coord.y}.png';
        final request = await client.getUrl(Uri.parse(url));
        final response = await request.close();
        expect(response.statusCode, 200,
            reason: 'Tile ${coord.z}/${coord.x}/${coord.y} should be served');
        expect(response.headers.contentType.toString(), contains('image/png'));
      }

      client.close();
    });

    test('multiple layers can be downloaded and served', () async {
      final downloader = TileDownloader(concurrency: 2);

      // Download base layer
      await downloader
          .downloadLayer(
            layerId: 'base',
            sourceUrlTemplate:
                'http://localhost:${origin.port}/{z}/{x}/{y}.png',
            documentsPath: tmpDir.path,
            minZoom: 0,
            maxZoom: 0,
          )
          .drain<void>();

      // Download relief layer
      await downloader
          .downloadLayer(
            layerId: 'relief',
            sourceUrlTemplate:
                'http://localhost:${origin.port}/{z}/{x}/{y}.png',
            documentsPath: tmpDir.path,
            minZoom: 0,
            maxZoom: 0,
          )
          .drain<void>();

      tileServer = TileServer(port: 19767);
      await tileServer.start(tmpDir.path);

      final client = HttpClient();

      // Both layers should be available
      var request = await client.getUrl(
          Uri.parse('http://localhost:19767/tiles/base/0/0/0.png'));
      var response = await request.close();
      expect(response.statusCode, 200);

      request = await client.getUrl(
          Uri.parse('http://localhost:19767/tiles/relief/0/0/0.png'));
      response = await request.close();
      expect(response.statusCode, 200);

      // Non-existent layer should 404
      request = await client.getUrl(
          Uri.parse('http://localhost:19767/tiles/clouds/0/0/0.png'));
      response = await request.close();
      expect(response.statusCode, 404);

      client.close();
    });

    test('downloader skips already-downloaded tiles on re-run', () async {
      final downloader = TileDownloader(concurrency: 1);

      // First download
      final firstRun = <TileDownloadProgress>[];
      await downloader
          .downloadLayer(
            layerId: 'base',
            sourceUrlTemplate:
                'http://localhost:${origin.port}/{z}/{x}/{y}.png',
            documentsPath: tmpDir.path,
            minZoom: 0,
            maxZoom: 0,
          )
          .listen(firstRun.add)
          .asFuture<void>();

      expect(firstRun.last.bytesDownloaded, greaterThan(0));

      // Second download of same tiles — should skip (0 new bytes)
      final secondRun = <TileDownloadProgress>[];
      await downloader
          .downloadLayer(
            layerId: 'base',
            sourceUrlTemplate:
                'http://localhost:${origin.port}/{z}/{x}/{y}.png',
            documentsPath: tmpDir.path,
            minZoom: 0,
            maxZoom: 0,
          )
          .listen(secondRun.add)
          .asFuture<void>();

      expect(secondRun.last.bytesDownloaded, 0,
          reason: 'Second run should skip all existing tiles');

      // Tile server should still serve the tiles fine
      tileServer = TileServer(port: 19768);
      await tileServer.start(tmpDir.path);

      final client = HttpClient();
      final request = await client
          .getUrl(Uri.parse('http://localhost:19768/tiles/base/0/0/0.png'));
      final response = await request.close();
      expect(response.statusCode, 200);
      client.close();
    });
  });
}
