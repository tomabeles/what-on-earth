import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'bridge.dart';

/// Full-screen WebView that hosts the CesiumJS transparent globe.
///
/// Starts a shelf HTTP server on port 8080 that serves the pre-built
/// CesiumJS bundle from `assets/globe/`. URL paths are rooted at `/` so
/// that the Vite-built `index.html` (which uses `base: '/'`) resolves
/// all asset references without path-prefix mangling.
///
/// Pass a [bridge] to inject an external [BridgeController] (e.g. from
/// [ARScreen] or a test). When omitted, [GlobeView] creates and owns its own.
class GlobeView extends StatefulWidget {
  const GlobeView({super.key, this.bridge});

  final BridgeController? bridge;

  @override
  State<GlobeView> createState() => _GlobeViewState();
}

class _GlobeViewState extends State<GlobeView> {
  HttpServer? _server;
  late final BridgeController _bridge;
  late final bool _ownsBridge;

  @override
  void initState() {
    super.initState();
    _ownsBridge = widget.bridge == null;
    _bridge = widget.bridge ?? BridgeController();
    _startServer();
  }

  Future<void> _startServer() async {
    final handler = const shelf.Pipeline().addHandler(_serveGlobeAsset);
    _server = await shelf_io.serve(handler, 'localhost', 8080);
  }

  @override
  void dispose() {
    if (_ownsBridge) _bridge.dispose();
    _server?.close(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      key: const Key('globe_view'),
      initialUrlRequest: URLRequest(
        url: WebUri('http://localhost:8080/index.html'),
      ),
      initialSettings: InAppWebViewSettings(
        // flutter_inappwebview#99: useHybridComposition: false required for
        // reliable alpha compositing on Android (TextureView vs SurfaceView).
        useHybridComposition: false,
        transparentBackground: true,
        javaScriptEnabled: true,
      ),
      onWebViewCreated: (controller) {
        // Register all inbound JS handlers before the page loads.
        _bridge.registerHandlers(controller);
      },
      onConsoleMessage: (controller, consoleMessage) {
        debugPrint('WebView console [${consoleMessage.messageLevel}]: '
            '${consoleMessage.message}');
      },
      onReceivedError: (controller, request, error) {
        debugPrint('WebView error: ${request.url} → ${error.description}');
      },
      onReceivedHttpError: (controller, request, response) {
        debugPrint('WebView HTTP ${response.statusCode}: ${request.url}');
      },
      onLoadStop: (controller, url) async {
        if (Platform.isAndroid) {
          // WOE-005: Belt-and-suspenders transparency fix for Android WebView.
          // transparentBackground: true + useHybridComposition: false usually
          // suffices, but clearing the body background handles any residual
          // white flash on first paint.
          // If a white flash still persists, add a MethodChannel call to
          // WebView.setBackgroundColor(Color.TRANSPARENT) in native Android code.
          await controller.callAsyncJavaScript(
            functionBody: "document.body.style.background = 'transparent';",
          );
        }
      },
    );
  }
}

/// Shelf request handler that serves files from `assets/globe/` as the
/// virtual root directory, matching the Vite bundle layout (`base: '/'`).
Future<shelf.Response> _serveGlobeAsset(shelf.Request request) async {
  var path = request.requestedUri.path;
  if (path == '/') path = '/index.html';
  // Cesium.js hardcodes "Assets/" (capital A) but vite-plugin-cesium outputs
  // to lowercase "assets/". Flutter's asset bundle is case-sensitive on Android.
  if (path.startsWith('/Assets/')) {
    path = '/assets/${path.substring(8)}';
  }
  final assetKey = 'assets/globe$path';
  try {
    final data = await rootBundle.load(assetKey);
    debugPrint('shelf 200: $assetKey (${data.lengthInBytes} bytes)');
    return shelf.Response.ok(
      data.buffer.asUint8List(),
      headers: {
        'content-type': _mimeType(path),
        'access-control-allow-origin': '*',
      },
    );
  } catch (e) {
    debugPrint('shelf 404: $assetKey — $e');
    return shelf.Response.notFound('$assetKey not found');
  }
}

String _mimeType(String path) {
  if (path.endsWith('.html')) return 'text/html; charset=utf-8';
  if (path.endsWith('.js')) return 'application/javascript';
  if (path.endsWith('.css')) return 'text/css';
  if (path.endsWith('.json')) return 'application/json';
  if (path.endsWith('.wasm')) return 'application/wasm';
  if (path.endsWith('.png')) return 'image/png';
  if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return 'image/jpeg';
  if (path.endsWith('.svg')) return 'image/svg+xml';
  if (path.endsWith('.ktx2')) return 'image/ktx2';
  return 'application/octet-stream';
}
