import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'position_source.dart';

/// Polls the WhereTheISS.at API every 2 seconds and emits live ISS positions.
///
/// On any error (network failure, timeout, non-2xx response) the last known
/// position is re-emitted with [PositionSourceType.estimated]. If no
/// successful poll has occurred yet the stream stays silent until the first
/// success, rather than emitting a stale or fabricated position.
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
  final _controller = StreamController<OrbitalPosition>.broadcast();
  Timer? _timer;
  OrbitalPosition? _lastKnown;

  @override
  PositionSourceType get type => PositionSourceType.live;

  @override
  Stream<OrbitalPosition> get positionStream => _controller.stream;

  @override
  Future<void> start() async {
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
      final pos = OrbitalPosition(
        latDeg: (data['latitude'] as num).toDouble(),
        lonDeg: (data['longitude'] as num).toDouble(),
        altKm: (data['altitude'] as num).toDouble(),
        timestamp: DateTime.now().toUtc(),
        sourceType: PositionSourceType.live,
      );
      _lastKnown = pos;
      if (!_controller.isClosed) _controller.add(pos);
    } catch (e) {
      debugPrint('ISSLiveSource: poll error: $e');
      _emitEstimated();
    }
  }

  void _emitEstimated() {
    final last = _lastKnown;
    if (last != null && !_controller.isClosed) {
      _controller.add(last.copyWith(
        timestamp: DateTime.now().toUtc(),
        sourceType: PositionSourceType.estimated,
      ));
    }
  }
}
