import 'dart:async';

import 'position_source.dart';

/// A [PositionSource] that repeatedly emits a fixed [OrbitalPosition] on a
/// timer. Requires no network access — used for offline dev runs, Simulator
/// testing, and as the backing source for integration tests (WOE-062).
///
/// The default position is ISS orbital altitude over London (51.5°N, −0.1°E,
/// 420 km) so a first device or Simulator run immediately shows a satellite
/// marker on the globe without any configuration.
class StaticPositionSource implements PositionSource {
  StaticPositionSource({
    OrbitalPosition? position,
    this.interval = const Duration(seconds: 5),
  }) : _position = position ??
            OrbitalPosition(
              latDeg: 51.5,
              lonDeg: -0.1,
              altKm: 420.0,
              timestamp: DateTime.now(),
              sourceType: PositionSourceType.static,
            );

  final OrbitalPosition _position;
  final Duration interval;

  final _controller = StreamController<OrbitalPosition>.broadcast();
  Timer? _timer;

  @override
  PositionSourceType get type => PositionSourceType.static;

  @override
  Stream<OrbitalPosition> get positionStream => _controller.stream;

  @override
  Future<void> start() async {
    _emit();
    _timer = Timer.periodic(interval, (_) => _emit());
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    await _controller.close();
  }

  void _emit() {
    if (!_controller.isClosed) {
      // Always stamp sourceType as static regardless of the seed position,
      // and update timestamp to reflect the actual emission time.
      _controller.add(_position.copyWith(
        timestamp: DateTime.now(),
        sourceType: PositionSourceType.static,
      ));
    }
  }
}
