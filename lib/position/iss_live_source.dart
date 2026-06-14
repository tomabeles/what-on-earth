import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'position_source.dart';

/// Polls the WhereTheISS.at API every 2 seconds and emits live ISS positions.
///
/// On any error (network failure, timeout, non-2xx response) nothing is
/// emitted — the source simply stays silent. Detecting that silence and
/// falling back to another source is the [PositionController]'s job (via a
/// staleness watchdog + circuit breaker); this source never fabricates or
/// re-emits stale positions.
///
/// Inject [Dio] for testability. Use [ISSLiveSource.create()] in production
/// to get a pre-configured instance with 5-second timeouts.
///
/// Reference: TECH_SPEC §4.1, §7.1
class ISSLiveSource implements PositionSource {
  ISSLiveSource({required Dio dio}) : _dio = dio;

  /// Creates a production-ready instance with 5-second connect/receive
  /// timeouts as specified in TECH_SPEC §4.1.
  factory ISSLiveSource.create() => ISSLiveSource(
        dio: Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
          ),
        ),
      );

  static const _url = 'https://api.wheretheiss.at/v1/satellites/25544';

  final Dio _dio;
  StreamController<OrbitalPosition> _controller =
      StreamController<OrbitalPosition>.broadcast();
  Timer? _timer;
  OrbitalPosition? _lastKnown;

  @override
  PositionSourceType get type => PositionSourceType.live;

  @override
  Stream<OrbitalPosition> get positionStream => _controller.stream;

  @override
  Future<void> start() async {
    // Revive the stream if this instance was previously stopped, so the
    // controller can restart it (e.g. a circuit-breaker recovery probe).
    if (_controller.isClosed) {
      _controller = StreamController<OrbitalPosition>.broadcast();
    }
    _poll(); // immediate first update, fire-and-forget
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _poll());
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    await _controller.close();
  }

  Future<void> _poll() async {
    try {
      final response = await _dio.get(_url);
      final data = response.data as Map<String, dynamic>;
      // API returns velocity in km/h; convert to km/s for HUD display.
      final velocityKmH = (data['velocity'] as num?)?.toDouble();
      final newLat = (data['latitude'] as num).toDouble();
      final newLon = (data['longitude'] as num).toDouble();

      // Compute bearing from previous position.
      double? bearing;
      if (_lastKnown != null) {
        final prev = _lastKnown!;
        if (prev.latDeg != newLat || prev.lonDeg != newLon) {
          bearing = OrbitalPosition.computeBearing(
            prev,
            OrbitalPosition(
              latDeg: newLat,
              lonDeg: newLon,
              altKm: 0,
              timestamp: DateTime.now().toUtc(),
              sourceType: PositionSourceType.live,
            ),
          );
        } else {
          bearing = prev.bearingDeg;
        }
      }

      final pos = OrbitalPosition(
        latDeg: newLat,
        lonDeg: newLon,
        altKm: (data['altitude'] as num).toDouble(),
        timestamp: DateTime.now().toUtc(),
        sourceType: PositionSourceType.live,
        velocityKmS: velocityKmH != null ? velocityKmH / 3600 : null,
        bearingDeg: bearing,
      );
      _lastKnown = pos;
      if (!_controller.isClosed) _controller.add(pos);
    } catch (e) {
      // Stay silent on failure; the controller's watchdog handles fallback.
      debugPrint('ISSLiveSource: poll error: $e');
    }
  }
}
