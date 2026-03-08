import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../position/position_source.dart';

/// Outbound message types — Flutter → CesiumJS via `flutter_message` CustomEvent.
///
/// See TECH_SPEC §8.1 for payload schemas.
enum OutboundMessage {
  updatePosition,
  updateOrientation,
  setTle,
  toggleLayer,
  syncPins,
  setMode,
  requestPassCalc,
  setSkybox;

  /// The `type` string used in the JS `flutter_message` event detail object.
  String get messageName => switch (this) {
        OutboundMessage.updatePosition => 'UPDATE_POSITION',
        OutboundMessage.updateOrientation => 'UPDATE_ORIENTATION',
        OutboundMessage.setTle => 'SET_TLE',
        OutboundMessage.toggleLayer => 'TOGGLE_LAYER',
        OutboundMessage.syncPins => 'SYNC_PINS',
        OutboundMessage.setMode => 'SET_MODE',
        OutboundMessage.requestPassCalc => 'REQUEST_PASS_CALC',
        OutboundMessage.setSkybox => 'SET_SKYBOX',
      };
}

/// Inbound message types — CesiumJS → Flutter via `callHandler`.
///
/// See TECH_SPEC §8.2 for payload schemas.
enum InboundMessage {
  globeReady,
  mapTap,
  passCalcResult,
  frameRate,
  positionUpdate;

  /// The handler name registered with [InAppWebViewController.addJavaScriptHandler].
  String get handlerName => switch (this) {
        InboundMessage.globeReady => 'GLOBE_READY',
        InboundMessage.mapTap => 'MAP_TAP',
        InboundMessage.passCalcResult => 'PASS_CALC_RESULT',
        InboundMessage.frameRate => 'FRAME_RATE',
        InboundMessage.positionUpdate => 'POSITION_UPDATE',
      };
}

/// Owns the [InAppWebViewController] reference and handles all bidirectional
/// communication between Flutter and CesiumJS (TECH_SPEC §8).
///
/// Usage:
/// 1. Create an instance and hold it in widget [State].
/// 2. Call [registerHandlers] from the WebView's `onWebViewCreated` callback
///    so handlers are registered before any page JS executes.
/// 3. Call [send] to dispatch messages to CesiumJS.
/// 4. Call [dispose] when the parent widget is disposed.
class BridgeController {
  InAppWebViewController? _controller;

  final _globeReady = Completer<void>();

  /// Completes when the CesiumJS globe fires `GLOBE_READY`. Await this before
  /// sending any bridge messages to avoid dispatching into an uninitialised
  /// WebView.
  Future<void> get globeReady => _globeReady.future;

  final _mapTaps = StreamController<MapTapEvent>.broadcast();
  final _passCalcResults = StreamController<PassCalcResponse>.broadcast();
  final _propagatedPositions = StreamController<OrbitalPosition>.broadcast();

  /// FPS value reported by CesiumJS via `FRAME_RATE` messages.
  /// AR screen listens to this and forwards to [fpsProvider].
  final fpsNotifier = ValueNotifier<int?>(null);
  
  /// Globe tap events from MAP_TAP messages.
  Stream<MapTapEvent> get mapTaps => _mapTaps.stream;

  /// Pass calculation results from PASS_CALC_RESULT messages.
  Stream<PassCalcResponse> get passCalcResults => _passCalcResults.stream;

  /// Positions propagated by the JS satellite.js SGP4 engine via
  /// `POSITION_UPDATE` messages. [TLESource] (WOE-012) listens to this.
  Stream<OrbitalPosition> get propagatedPositions =>
      _propagatedPositions.stream;

  /// Attaches [controller] and registers all inbound JS handler callbacks.
  void registerHandlers(InAppWebViewController controller) {
    _controller = controller;
    controller.addJavaScriptHandler(
      handlerName: InboundMessage.globeReady.handlerName,
      callback: _onGlobeReady,
    );
    controller.addJavaScriptHandler(
      handlerName: InboundMessage.mapTap.handlerName,
      callback: _onMapTap,
    );
    controller.addJavaScriptHandler(
      handlerName: InboundMessage.passCalcResult.handlerName,
      callback: _onPassCalcResult,
    );
    controller.addJavaScriptHandler(
      handlerName: InboundMessage.frameRate.handlerName,
      callback: _onFrameRate,
    );
    controller.addJavaScriptHandler(
      handlerName: InboundMessage.positionUpdate.handlerName,
      callback: _onPositionUpdate,
    );
  }

  /// Test hook: called by [send] before dispatching to the WebView.
  /// Set to null to deregister. Never set this in production code.
  @visibleForTesting
  static void Function(OutboundMessage type, Map<String, dynamic> payload)?
      onSend;

  /// Dispatches [type] with [payload] to CesiumJS. No-ops if no controller
  /// is currently attached.
  Future<void> send(OutboundMessage type, Map<String, dynamic> payload) async {
    onSend?.call(type, payload);
    await _controller?.evaluateJavascript(
      source: buildDispatchSource(type, payload),
    );
  }

  /// Builds the JavaScript source string that dispatches a `flutter_message`
  /// CustomEvent to CesiumJS.
  ///
  /// Exposed as a static method so unit tests can verify JSON serialization
  /// without requiring a live WebView controller.
  static String buildDispatchSource(
    OutboundMessage type,
    Map<String, dynamic> payload,
  ) {
    final detail = jsonEncode({'type': type.messageName, 'payload': payload});
    return "window.dispatchEvent(new CustomEvent('flutter_message', { detail: $detail }));";
  }

  /// Toggles the CesiumJS star skybox on or off.
  Future<void> setSkybox(bool enabled) =>
      send(OutboundMessage.setSkybox, {'enabled': enabled});

  /// Toggle a map layer's visibility.
  Future<void> toggleLayer(String layerId, bool visible) =>
      send(OutboundMessage.toggleLayer, {
        'layerId': layerId,
        'visible': visible,
      });

  /// Sync all pins to CesiumJS for rendering.
  Future<void> syncPins(List<Map<String, dynamic>> pins) =>
      send(OutboundMessage.syncPins, {'pins': pins});

  /// Request a pass calculation for a given location.
  Future<void> requestPassCalc(String requestId, double lat, double lon) =>
      send(OutboundMessage.requestPassCalc, {
        'requestId': requestId,
        'lat': lat,
        'lon': lon,
      });

  /// Releases the controller reference and closes streams.
  /// Call from the parent widget's dispose.
  void dispose() {
    _controller = null;
    _mapTaps.close();
    _passCalcResults.close();
    _propagatedPositions.close();
    fpsNotifier.dispose();
  }

  // ── Inbound handlers ──────────────────────────────────────────────────────

  void _onGlobeReady(List<dynamic> args) {
    debugPrint('BridgeController: GLOBE_READY received');
    if (!_globeReady.isCompleted) _globeReady.complete();
  }

  void _onMapTap(List<dynamic> args) {
    final raw = args.firstOrNull;
    if (raw == null) return;
    try {
      final map = Map<String, dynamic>.from(raw as Map);
      final event = MapTapEvent(
        lat: (map['lat'] as num).toDouble(),
        lon: (map['lon'] as num).toDouble(),
      );
      if (!_mapTaps.isClosed) _mapTaps.add(event);
    } catch (e) {
      debugPrint('BridgeController: MAP_TAP parse error: $e');
    }
  }

  void _onPassCalcResult(List<dynamic> args) {
    final raw = args.firstOrNull;
    if (raw == null) return;
    try {
      final map = Map<String, dynamic>.from(raw as Map);
      final response = PassCalcResponse.fromJson(map);
      if (!_passCalcResults.isClosed) _passCalcResults.add(response);
    } catch (e) {
      debugPrint('BridgeController: PASS_CALC_RESULT parse error: $e');
    }
  }

  void _onFrameRate(List<dynamic> args) {
    final raw = args.firstOrNull;
    debugPrint('BridgeController: FRAME_RATE received: $raw');
    if (raw is int) {
      fpsNotifier.value = raw;
    } else if (raw is Map) {
      fpsNotifier.value = (raw['fps'] as num?)?.toInt();
    }
  }

  void _onPositionUpdate(List<dynamic> args) {
    final raw = args.firstOrNull;
    if (raw == null) return;
    try {
      final pos = OrbitalPosition.fromJson(Map<String, dynamic>.from(raw as Map));
      if (!_propagatedPositions.isClosed) _propagatedPositions.add(pos);
    } catch (e) {
      debugPrint('BridgeController: POSITION_UPDATE parse error: $e');
    }
  }
}

// ── Bridge event models ───────────────────────────────────────────────────

/// A tap on the CesiumJS globe surface.
class MapTapEvent {
  final double lat;
  final double lon;
  const MapTapEvent({required this.lat, required this.lon});
}

/// Result of a pass calculation from satellite.js.
class PassCalcResponse {
  final String requestId;
  final DateTime? passStartUtc;
  final double? maxElevationDeg;
  final int? passDurationSeconds;
  final String? error;

  const PassCalcResponse({
    required this.requestId,
    this.passStartUtc,
    this.maxElevationDeg,
    this.passDurationSeconds,
    this.error,
  });

  bool get hasPass => error == null && passStartUtc != null;

  factory PassCalcResponse.fromJson(Map<String, dynamic> json) {
    return PassCalcResponse(
      requestId: json['requestId'] as String,
      passStartUtc: json['passStartUtc'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['passStartUtc'] as int)
          : null,
      maxElevationDeg: (json['maxElevationDeg'] as num?)?.toDouble(),
      passDurationSeconds: json['passDurationSeconds'] as int?,
      error: json['error'] as String?,
    );
  }
}
