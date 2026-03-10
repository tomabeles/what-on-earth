import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:what_on_earth/position/position_source.dart';
import 'package:what_on_earth/sensors/lvlh_frame.dart';
import 'package:what_on_earth/sensors/orientation_corrections.dart';

void main() {
  group('computeLvlhFrame', () {
    test('produces unit vectors', () {
      final pos = OrbitalPosition(
        latDeg: 0,
        lonDeg: 0,
        altKm: 408, // ISS altitude
        timestamp: DateTime.utc(2025),
        sourceType: PositionSourceType.live,
        bearingDeg: 45,
      );

      final frame = computeLvlhFrame(pos);

      // Nadir should be a unit vector
      final nMag = _mag(frame.nadirEcef);
      expect(nMag, closeTo(1.0, 1e-10));

      // Velocity should be a unit vector
      final vMag = _mag(frame.velocityEcef);
      expect(vMag, closeTo(1.0, 1e-10));

      // Cross-track should be a unit vector
      final hMag = _mag(frame.crossTrackEcef);
      expect(hMag, closeTo(1.0, 1e-10));
    });

    test('frame vectors are orthogonal', () {
      final pos = OrbitalPosition(
        latDeg: 51.6, // ISS inclination
        lonDeg: -73.0,
        altKm: 408,
        timestamp: DateTime.utc(2025),
        sourceType: PositionSourceType.live,
        bearingDeg: 30,
      );

      final frame = computeLvlhFrame(pos);

      // Dot products should be ~0
      final nv = _dot(frame.nadirEcef, frame.velocityEcef);
      final nh = _dot(frame.nadirEcef, frame.crossTrackEcef);
      final vh = _dot(frame.velocityEcef, frame.crossTrackEcef);

      expect(nv.abs(), lessThan(1e-10));
      expect(nh.abs(), lessThan(1e-10));
      expect(vh.abs(), lessThan(1e-10));
    });

    test('nadir points toward Earth center', () {
      final pos = OrbitalPosition(
        latDeg: 0,
        lonDeg: 0,
        altKm: 408,
        timestamp: DateTime.utc(2025),
        sourceType: PositionSourceType.live,
      );

      final frame = computeLvlhFrame(pos);

      // At (0,0), ECEF position is along +X axis.
      // Nadir (toward center) should be along -X.
      expect(frame.nadirEcef.$1, lessThan(0));
      expect(frame.nadirEcef.$2.abs(), lessThan(1e-10));
      expect(frame.nadirEcef.$3.abs(), lessThan(1e-10));
    });

    test('isOrbital flag based on altitude', () {
      final lowAlt = computeLvlhFrame(OrbitalPosition(
        latDeg: 0, lonDeg: 0, altKm: 10,
        timestamp: DateTime.utc(2025),
        sourceType: PositionSourceType.static,
      ));
      expect(lowAlt.isOrbital, isFalse);

      final highAlt = computeLvlhFrame(OrbitalPosition(
        latDeg: 0, lonDeg: 0, altKm: 408,
        timestamp: DateTime.utc(2025),
        sourceType: PositionSourceType.live,
      ));
      expect(highAlt.isOrbital, isTrue);
    });

    test('default velocity is East when no bearing', () {
      final pos = OrbitalPosition(
        latDeg: 0,
        lonDeg: 0,
        altKm: 408,
        timestamp: DateTime.utc(2025),
        sourceType: PositionSourceType.live,
        // No bearingDeg
      );

      final frame = computeLvlhFrame(pos);

      // At (0,0), East is the +Y ECEF direction
      expect(frame.velocityEcef.$2, closeTo(1.0, 1e-10));
    });

    test('reference pitch/roll are zero (nadir-pointing)', () {
      final frame = computeLvlhFrame(OrbitalPosition(
        latDeg: 30, lonDeg: 60, altKm: 408,
        timestamp: DateTime.utc(2025),
        sourceType: PositionSourceType.live,
        bearingDeg: 90,
      ));

      expect(frame.referencePitchDeg, equals(0.0));
      expect(frame.referenceRollDeg, equals(0.0));
    });
  });

  group('LvlhFrame', () {
    test('isFresh checks timestamp', () {
      final fresh = LvlhFrame(
        nadirEcef: (-1, 0, 0),
        velocityEcef: (0, 1, 0),
        crossTrackEcef: (0, 0, 1),
        referencePitchDeg: 0,
        referenceRollDeg: 0,
        altKm: 408,
        timestamp: DateTime.now(),
      );
      expect(fresh.isFresh(), isTrue);

      final stale = LvlhFrame(
        nadirEcef: (-1, 0, 0),
        velocityEcef: (0, 1, 0),
        crossTrackEcef: (0, 0, 1),
        referencePitchDeg: 0,
        referenceRollDeg: 0,
        altKm: 408,
        timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      expect(stale.isFresh(), isFalse);
    });
  });
}

double _mag((double, double, double) v) =>
    math.sqrt(v.$1 * v.$1 + v.$2 * v.$2 + v.$3 * v.$3);

double _dot((double, double, double) a, (double, double, double) b) =>
    a.$1 * b.$1 + a.$2 * b.$2 + a.$3 * b.$3;
