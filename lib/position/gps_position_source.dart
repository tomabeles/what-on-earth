import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'position_source.dart';

/// Default viewing altitude for GPS mode (100 km above ground).
const double _kGpsViewAltKm = 100.0;

/// A [PositionSource] that uses the device's real-time GPS.
///
/// Requests location permission on [start] and streams device coordinates.
/// The reported altitude is fixed at [_kGpsViewAltKm] to give a useful
/// globe viewing height rather than the device's ground-level altitude.
class GpsPositionSource implements PositionSource {
  final _controller = StreamController<OrbitalPosition>.broadcast();
  StreamSubscription<Position>? _gpsSub;

  @override
  PositionSourceType get type => PositionSourceType.gps;

  @override
  Stream<OrbitalPosition> get positionStream => _controller.stream;

  @override
  Future<void> start() async {
    final ok = await _ensurePermission();
    if (!ok) {
      debugPrint('GpsPositionSource: location permission denied');
      return;
    }

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _gpsSub = Geolocator.getPositionStream(locationSettings: settings)
        .listen(_onPosition);
  }

  @override
  Future<void> stop() async {
    await _gpsSub?.cancel();
    _gpsSub = null;
  }

  void _onPosition(Position pos) {
    if (_controller.isClosed) return;
    _controller.add(OrbitalPosition(
      latDeg: pos.latitude,
      lonDeg: pos.longitude,
      altKm: _kGpsViewAltKm,
      timestamp: pos.timestamp,
      sourceType: PositionSourceType.gps,
      velocityKmS: pos.speed / 1000.0,
      bearingDeg: pos.heading,
    ));
  }

  Future<bool> _ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.whileInUse ||
        perm == LocationPermission.always;
  }
}
