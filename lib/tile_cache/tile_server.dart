import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

/// Status of the background tile server.
class TileServerStatus {
  final bool running;
  final int port;
  const TileServerStatus({required this.running, required this.port});
}

/// Local HTTP server that serves pre-downloaded raster tiles from the device's
/// documents directory. Runs in a background [Isolate] on port 8765 (default).
///
/// Route: `GET /tiles/{layer}/{z}/{x}/{y}.{ext}` → file at
/// `{documentsPath}/tiles/{layer}/{z}/{x}/{y}.{ext}`.
///
/// Returns 200 with the tile bytes or 404 if the file does not exist.
///
/// Reference: TECH_SPEC §7.3
class TileServer {
  Isolate? _isolate;
  bool _running = false;

  /// The port the server listens on.
  final int port;

  TileServer({this.port = 8765});

  TileServerStatus get status => TileServerStatus(running: _running, port: port);

  /// Starts the tile server in a background isolate.
  ///
  /// [documentsPath] is the absolute path to the app's documents directory
  /// (obtained via `path_provider` on the main isolate).
  Future<void> start(String documentsPath) async {
    if (_running) return;

    final receivePort = ReceivePort();
    _isolate = await Isolate.spawn(
      _isolateEntry,
      _IsolateConfig(
        documentsPath: documentsPath,
        port: port,
        sendPort: receivePort.sendPort,
      ),
    );

    // Wait for the isolate to signal that the server is listening.
    await receivePort.first;
    _running = true;
    debugPrint('TileServer: listening on localhost:$port');
  }

  /// Stops the background isolate and its HTTP server.
  void stop() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _running = false;
  }
}

// ── Isolate entry point ───────────────────────────────────────────────────────

class _IsolateConfig {
  final String documentsPath;
  final int port;
  final SendPort sendPort;
  const _IsolateConfig({
    required this.documentsPath,
    required this.port,
    required this.sendPort,
  });
}

Future<void> _isolateEntry(_IsolateConfig config) async {
  final router = Router()
    ..get('/', (shelf.Request request) {
      // Health probe used by CesiumJS (layers.js) to decide between local
      // tiles and online OSM fallback.  Return 200 only when the root base
      // tile exists on disk so the probe fails before tiles are downloaded.
      final probe = File('${config.documentsPath}/tiles/base/0/0/0.png');
      if (probe.existsSync()) {
        return shelf.Response.ok('ok');
      }
      return shelf.Response.notFound('no tiles');
    })
    ..get(
      '/tiles/<layer>/<z|[0-9]+>/<x|[0-9]+>/<y>',
      (shelf.Request request, String layer, String z, String x, String y) {
        return _serveTile(config.documentsPath, layer, z, x, y);
      },
    );

  final handler = const shelf.Pipeline()
      .addMiddleware(shelf.logRequests(
        logger: (msg, isError) {}, // silent in production
      ))
      .addHandler(router.call);

  await shelf_io.serve(handler, 'localhost', config.port);
  config.sendPort.send(true); // signal ready
}

Future<shelf.Response> _serveTile(
  String documentsPath,
  String layer,
  String z,
  String x,
  String yWithExt,
) async {
  final filePath = '$documentsPath/tiles/$layer/$z/$x/$yWithExt';
  final file = File(filePath);

  if (!await file.exists()) {
    return shelf.Response.notFound('tile not found');
  }

  return shelf.Response.ok(
    file.openRead(),
    headers: {'content-type': _mimeForExt(yWithExt)},
  );
}

String _mimeForExt(String filename) {
  if (filename.endsWith('.webp')) return 'image/webp';
  if (filename.endsWith('.png')) return 'image/png';
  if (filename.endsWith('.jpg') || filename.endsWith('.jpeg')) {
    return 'image/jpeg';
  }
  return 'application/octet-stream';
}
