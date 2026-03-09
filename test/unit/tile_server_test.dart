import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:what_on_earth/tile_cache/tile_server.dart';

void main() {
  group('TileServer', () {
    late Directory tmpDir;
    late TileServer server;

    setUp(() async {
      tmpDir = await Directory.systemTemp.createTemp('tile_server_test_');
    });

    tearDown(() async {
      server.stop();
      if (tmpDir.existsSync()) await tmpDir.delete(recursive: true);
    });

    test('starts and stops', () async {
      server = TileServer(port: 0); // port 0 won't work with shelf_io
      // Use a high ephemeral port to avoid conflicts
      server = TileServer(port: 18765);
      await server.start(tmpDir.path);
      expect(server.status.running, isTrue);
      expect(server.status.port, 18765);

      server.stop();
      expect(server.status.running, isFalse);
    });

    test('health probe returns 404 when no tiles exist', () async {
      server = TileServer(port: 18766);
      await server.start(tmpDir.path);

      final client = HttpClient();
      final request =
          await client.getUrl(Uri.parse('http://localhost:18766/'));
      final response = await request.close();
      expect(response.statusCode, 404);
      client.close();
    });

    test('health probe returns 200 when satellite tiles exist', () async {
      // Create the probe tile (satellite layer, JPEG)
      final tileFile = File('${tmpDir.path}/tiles/satellite/0/0/0.jpg');
      await tileFile.parent.create(recursive: true);
      await tileFile.writeAsBytes([0xFF, 0xD8, 0xFF, 0xE0]); // JPEG magic

      server = TileServer(port: 18767);
      await server.start(tmpDir.path);

      final client = HttpClient();
      final request =
          await client.getUrl(Uri.parse('http://localhost:18767/'));
      final response = await request.close();
      expect(response.statusCode, 200);
      client.close();
    });

    test('serves existing tile with correct content-type', () async {
      final tileBytes = [137, 80, 78, 71, 13, 10, 26, 10]; // PNG header
      final tileFile = File('${tmpDir.path}/tiles/base/2/1/3.png');
      await tileFile.parent.create(recursive: true);
      await tileFile.writeAsBytes(tileBytes);

      server = TileServer(port: 18768);
      await server.start(tmpDir.path);

      final client = HttpClient();
      final request = await client
          .getUrl(Uri.parse('http://localhost:18768/tiles/base/2/1/3.png'));
      final response = await request.close();
      expect(response.statusCode, 200);
      expect(response.headers.contentType.toString(), contains('image/png'));

      final body = await response.fold<List<int>>(
        <int>[],
        (prev, chunk) => prev..addAll(chunk),
      );
      expect(body, tileBytes);
      client.close();
    });

    test('returns 404 for missing tile', () async {
      server = TileServer(port: 18769);
      await server.start(tmpDir.path);

      final client = HttpClient();
      final request = await client.getUrl(
          Uri.parse('http://localhost:18769/tiles/base/0/0/0.png'));
      final response = await request.close();
      expect(response.statusCode, 404);
      client.close();
    });

    test('serves webp tiles with correct mime type', () async {
      final tileFile = File('${tmpDir.path}/tiles/relief/1/0/0.webp');
      await tileFile.parent.create(recursive: true);
      await tileFile.writeAsBytes([82, 73, 70, 70]); // RIFF header

      server = TileServer(port: 18770);
      await server.start(tmpDir.path);

      final client = HttpClient();
      final request = await client.getUrl(
          Uri.parse('http://localhost:18770/tiles/relief/1/0/0.webp'));
      final response = await request.close();
      expect(response.statusCode, 200);
      expect(response.headers.contentType.toString(), contains('image/webp'));
      client.close();
    });

    test('start is idempotent', () async {
      server = TileServer(port: 18771);
      await server.start(tmpDir.path);
      expect(server.status.running, isTrue);

      // Second start should be a no-op
      await server.start(tmpDir.path);
      expect(server.status.running, isTrue);
    });
  });
}
