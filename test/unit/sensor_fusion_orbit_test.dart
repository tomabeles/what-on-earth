import 'package:flutter_test/flutter_test.dart';
import 'package:what_on_earth/sensors/orientation_corrections.dart';
import 'package:what_on_earth/sensors/sensor_fusion.dart';

void main() {
  // Shared sensor samples for tests
  final now = DateTime.utc(2025, 6, 1);
  const dt = 0.02; // 50 Hz

  final accel = RawSensorSample(x: 0, y: 0, z: 9.81, timestamp: now);
  final mag = RawSensorSample(x: 20, y: 0, z: 40, timestamp: now);
  final gyro = RawSensorSample(x: 0, y: 0, z: 0, timestamp: now);
  final prev = DeviceOrientation(
    headingDeg: 90,
    pitchDeg: 10,
    rollDeg: 5,
    reliable: true,
    timestamp: now.subtract(const Duration(milliseconds: 20)),
  );

  group('applyFilter with HorizonCorrection', () {
    test('uses horizon correction for pitch/roll reference when provided', () {
      final horizonCorrection = HorizonCorrection(
        pitchDeg: 25.0,
        rollDeg: -10.0,
        confidence: 0.8,
        timestamp: now,
        normalizedRadius: 0.3,
      );

      final withHorizon = applyFilter(
        prev: prev,
        accel: accel,
        mag: mag,
        gyro: gyro,
        dt: dt,
        timestamp: now,
        horizonCorrection: horizonCorrection,
      );

      final withoutHorizon = applyFilter(
        prev: prev,
        accel: accel,
        mag: mag,
        gyro: gyro,
        dt: dt,
        timestamp: now,
      );

      // With horizon correction, pitch should be pulled toward 25°
      // Without it, pitch is pulled toward accel-derived reference
      expect(
          withHorizon.pitchDeg, isNot(closeTo(withoutHorizon.pitchDeg, 0.01)));
    });

    test('ignores stale horizon correction', () {
      final staleCorrection = HorizonCorrection(
        pitchDeg: 45.0,
        rollDeg: -30.0,
        confidence: 0.9,
        timestamp: now.subtract(const Duration(seconds: 5)),
        normalizedRadius: 0.3,
      );

      final withStale = applyFilter(
        prev: prev,
        accel: accel,
        mag: mag,
        gyro: gyro,
        dt: dt,
        timestamp: now,
        horizonCorrection: staleCorrection,
      );

      final withoutCorrection = applyFilter(
        prev: prev,
        accel: accel,
        mag: mag,
        gyro: gyro,
        dt: dt,
        timestamp: now,
      );

      // Stale correction should be ignored — same as no correction
      expect(withStale.pitchDeg, closeTo(withoutCorrection.pitchDeg, 0.01));
    });

    test('ignores low-confidence horizon correction', () {
      final lowConfidence = HorizonCorrection(
        pitchDeg: 45.0,
        rollDeg: -30.0,
        confidence: 0.1, // Below kMinHorizonConfidence (0.3)
        timestamp: now,
        normalizedRadius: 0.3,
      );

      final withLow = applyFilter(
        prev: prev,
        accel: accel,
        mag: mag,
        gyro: gyro,
        dt: dt,
        timestamp: now,
        horizonCorrection: lowConfidence,
      );

      final withoutCorrection = applyFilter(
        prev: prev,
        accel: accel,
        mag: mag,
        gyro: gyro,
        dt: dt,
        timestamp: now,
      );

      expect(withLow.pitchDeg, closeTo(withoutCorrection.pitchDeg, 0.01));
    });
  });

  group('applyFilter with LvlhFrame', () {
    test('LVLH does not override accelerometer pitch/roll reference', () {
      final lvlh = LvlhFrame(
        nadirEcef: (-1, 0, 0),
        velocityEcef: (0, 1, 0),
        crossTrackEcef: (0, 0, 1),
        referencePitchDeg: 0,
        referenceRollDeg: 0,
        altKm: 408,
        timestamp: now,
      );

      final withLvlh = applyFilter(
        prev: prev,
        accel: accel,
        mag: mag,
        gyro: gyro,
        dt: dt,
        timestamp: now,
        lvlhFrame: lvlh,
      );

      final withoutLvlh = applyFilter(
        prev: prev,
        accel: accel,
        mag: mag,
        gyro: gyro,
        dt: dt,
        timestamp: now,
      );

      // LVLH does not override pitch/roll — both use accelerometer
      expect(withLvlh.pitchDeg, closeTo(withoutLvlh.pitchDeg, 0.01));
      expect(withLvlh.rollDeg, closeTo(withoutLvlh.rollDeg, 0.01));
    });
  });

  group('applyFilter priority', () {
    test('horizon correction takes priority over LVLH', () {
      final horizonCorrection = HorizonCorrection(
        pitchDeg: 20.0,
        rollDeg: -15.0,
        confidence: 0.8,
        timestamp: now,
        normalizedRadius: 0.3,
      );

      final lvlh = LvlhFrame(
        nadirEcef: (-1, 0, 0),
        velocityEcef: (0, 1, 0),
        crossTrackEcef: (0, 0, 1),
        referencePitchDeg: 0,
        referenceRollDeg: 0,
        altKm: 408,
        timestamp: now,
      );

      final withBoth = applyFilter(
        prev: prev,
        accel: accel,
        mag: mag,
        gyro: gyro,
        dt: dt,
        timestamp: now,
        horizonCorrection: horizonCorrection,
        lvlhFrame: lvlh,
      );

      final horizonOnly = applyFilter(
        prev: prev,
        accel: accel,
        mag: mag,
        gyro: gyro,
        dt: dt,
        timestamp: now,
        horizonCorrection: horizonCorrection,
      );

      // When both available, horizon should win — same result as horizon only
      expect(withBoth.pitchDeg, closeTo(horizonOnly.pitchDeg, 0.01));
      expect(withBoth.rollDeg, closeTo(horizonOnly.rollDeg, 0.01));
    });
  });

  group('orbit mode alpha', () {
    test('higher alpha trusts gyro more', () {
      // With high alpha and stationary gyro, output should stay closer to prev
      final highAlpha = applyFilter(
        prev: prev,
        accel: accel,
        mag: mag,
        gyro: gyro,
        dt: dt,
        timestamp: now,
        alpha: kOrbitGyroOnlyAlpha,
      );

      final normalAlpha = applyFilter(
        prev: prev,
        accel: accel,
        mag: mag,
        gyro: gyro,
        dt: dt,
        timestamp: now,
        alpha: kFilterAlpha,
      );

      // High alpha should keep pitch closer to prev.pitchDeg (10°)
      final highDelta = (highAlpha.pitchDeg - prev.pitchDeg).abs();
      final normalDelta = (normalAlpha.pitchDeg - prev.pitchDeg).abs();
      expect(highDelta, lessThanOrEqualTo(normalDelta));
    });
  });

  group('backward compatibility', () {
    test('applyFilter works without optional params', () {
      final result = applyFilter(
        prev: null,
        accel: accel,
        mag: mag,
        gyro: gyro,
        dt: 0,
        timestamp: now,
      );

      expect(result.headingDeg, isA<double>());
      expect(result.pitchDeg, isA<double>());
      expect(result.rollDeg, isA<double>());
      expect(result.reliable, isTrue);
    });

    test('consecutive filter steps work with no corrections', () {
      var orientation = applyFilter(
        prev: null,
        accel: accel,
        mag: mag,
        gyro: gyro,
        dt: 0,
        timestamp: now,
      );

      for (var i = 0; i < 10; i++) {
        orientation = applyFilter(
          prev: orientation,
          accel: accel,
          mag: mag,
          gyro: gyro,
          dt: dt,
          timestamp: now.add(Duration(milliseconds: 20 * (i + 1))),
        );
      }

      expect(orientation.headingDeg, isA<double>());
      expect(orientation.headingDeg.isNaN, isFalse);
    });
  });

  group('orientation mode in filter', () {
    test('portrait mode uses gyro.x for pitch integration', () {
      // Start with flat device
      final start = applyFilter(
        prev: null,
        accel: accel,
        mag: mag,
        gyro: gyro,
        dt: 0,
        timestamp: now,
        mode: OrientationMode.portrait,
      );

      // Apply pitch rotation via gyro.x in portrait
      final tilted = applyFilter(
        prev: start,
        accel: accel,
        mag: mag,
        gyro: RawSensorSample(x: 1.0, y: 0, z: 0, timestamp: now),
        dt: 0.02,
        timestamp: now.add(const Duration(milliseconds: 20)),
        mode: OrientationMode.portrait,
      );

      // Pitch should have changed (gyro.x drives pitch in portrait)
      expect((tilted.pitchDeg - start.pitchDeg).abs(), greaterThan(0.5));
    });

    test('landscape mode uses gyro.y for pitch integration', () {
      // Start at pitch ~90° (upright in landscape: gravity along +X)
      final uprightAccel =
          RawSensorSample(x: 9.81, y: 0, z: 0, timestamp: now);

      final start = applyFilter(
        prev: null,
        accel: uprightAccel,
        mag: mag,
        gyro: gyro,
        dt: 0,
        timestamp: now,
        mode: OrientationMode.landscape,
      );

      // Apply pitch rotation via gyro.y in landscape
      final tilted = applyFilter(
        prev: start,
        accel: uprightAccel,
        mag: mag,
        gyro: RawSensorSample(x: 0, y: 1.0, z: 0, timestamp: now),
        dt: 0.02,
        timestamp: now.add(const Duration(milliseconds: 20)),
        mode: OrientationMode.landscape,
      );

      // Pitch should have changed (gyro.y drives pitch in landscape)
      expect((tilted.pitchDeg - start.pitchDeg).abs(), greaterThan(0.5));
    });

    test('portrait mode uses gyro.z for roll integration', () {
      // Start with upright phone in portrait
      final uprightAccel =
          RawSensorSample(x: 0, y: 9.81, z: 0, timestamp: now);

      final start = applyFilter(
        prev: null,
        accel: uprightAccel,
        mag: mag,
        gyro: gyro,
        dt: 0,
        timestamp: now,
        mode: OrientationMode.portrait,
      );

      // Apply roll rotation via gyro.z in portrait
      final rolled = applyFilter(
        prev: start,
        accel: uprightAccel,
        mag: mag,
        gyro: RawSensorSample(x: 0, y: 0, z: 1.0, timestamp: now),
        dt: 0.02,
        timestamp: now.add(const Duration(milliseconds: 20)),
        mode: OrientationMode.portrait,
      );

      // Roll should have changed
      expect((rolled.rollDeg - start.rollDeg).abs(), greaterThan(0.5));
    });
  });
}
