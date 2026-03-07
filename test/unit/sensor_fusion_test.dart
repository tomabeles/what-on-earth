import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:what_on_earth/sensors/sensor_fusion.dart';

/// Helper to create a RawSensorSample at a given time.
RawSensorSample _sample(double x, double y, double z, [int ms = 0]) {
  return RawSensorSample(
    x: x,
    y: y,
    z: z,
    timestamp: DateTime.utc(2026, 1, 1).add(Duration(milliseconds: ms)),
  );
}

DateTime _ts([int ms = 0]) =>
    DateTime.utc(2026, 1, 1).add(Duration(milliseconds: ms));

void main() {
  group('accelPitchRoll', () {
    test('device flat on table gives ~0 pitch and ~0 roll', () {
      // Gravity along +Z (device face up, flat)
      final accel = _sample(0, 0, 9.81);
      final (pitch, roll) = accelPitchRoll(accel);

      expect(pitch * 180 / math.pi, closeTo(0.0, 1.0));
      expect(roll * 180 / math.pi, closeTo(0.0, 1.0));
    });

    test('device tilted 90 degrees forward gives ~-90 pitch', () {
      // Gravity along +X (screen facing ground, top edge pointing up)
      final accel = _sample(9.81, 0, 0);
      final (pitch, _) = accelPitchRoll(accel);

      expect(pitch * 180 / math.pi, closeTo(-90.0, 1.0));
    });

    test('device tilted 90 degrees right gives ~90 roll', () {
      // Gravity along +Y (right edge down)
      final accel = _sample(0, 9.81, 0);
      final (pitch, roll) = accelPitchRoll(accel);

      expect(pitch * 180 / math.pi, closeTo(0.0, 1.0));
      expect(roll * 180 / math.pi, closeTo(90.0, 1.0));
    });
  });

  group('tiltCompensatedHeading', () {
    test('north-pointing device gives ~0 heading', () {
      // Flat device, magnetic field pointing along +X (north)
      final mag = _sample(25.0, 0.0, -45.0);
      final heading = tiltCompensatedHeading(mag, 0.0, 0.0);

      expect(heading * 180 / math.pi, closeTo(0.0, 5.0));
    });

    test('east-pointing device gives ~90 heading', () {
      // Flat device, magnetic field pointing along -Y (east)
      final mag = _sample(0.0, -25.0, -45.0);
      final heading = tiltCompensatedHeading(mag, 0.0, 0.0);

      expect(heading * 180 / math.pi, closeTo(90.0, 5.0));
    });

    test('south-pointing device gives ~180 heading', () {
      // Flat device, magnetic field pointing along -X (south)
      final mag = _sample(-25.0, 0.0, -45.0);
      final heading = tiltCompensatedHeading(mag, 0.0, 0.0);

      expect(heading * 180 / math.pi, closeTo(180.0, 5.0));
    });
  });

  group('applyFilter', () {
    test('first sample uses accel/mag reference directly', () {
      final accel = _sample(0, 0, 9.81);
      final mag = _sample(25.0, 0.0, -45.0);
      final gyro = _sample(0, 0, 0);

      final result = applyFilter(
        prev: null,
        accel: accel,
        mag: mag,
        gyro: gyro,
        dt: 0.0,
        timestamp: _ts(),
      );

      // Flat device pointing north: heading ~0, pitch ~0, roll ~0
      expect(result.headingDeg, closeTo(0.0, 5.0));
      expect(result.pitchDeg, closeTo(0.0, 1.0));
      expect(result.rollDeg, closeTo(0.0, 1.0));
      expect(result.reliable, isTrue);
    });

    test('with zero gyro and stable accel/mag, output stays stable', () {
      final accel = _sample(0, 0, 9.81);
      final mag = _sample(25.0, 0.0, -45.0);
      final gyro = _sample(0, 0, 0);

      var prev = applyFilter(
        prev: null,
        accel: accel,
        mag: mag,
        gyro: gyro,
        dt: 0.0,
        timestamp: _ts(0),
      );

      // Run 10 filter steps with stable inputs
      for (var i = 1; i <= 10; i++) {
        prev = applyFilter(
          prev: prev,
          accel: accel,
          mag: mag,
          gyro: gyro,
          dt: 0.02, // 50 Hz
          timestamp: _ts(i * 20),
        );
      }

      expect(prev.headingDeg, closeTo(0.0, 5.0));
      expect(prev.pitchDeg, closeTo(0.0, 1.0));
      expect(prev.rollDeg, closeTo(0.0, 1.0));
    });

    test('gyro rotation changes heading', () {
      final accel = _sample(0, 0, 9.81);
      final mag = _sample(25.0, 0.0, -45.0);

      var prev = applyFilter(
        prev: null,
        accel: accel,
        mag: mag,
        gyro: _sample(0, 0, 0),
        dt: 0.0,
        timestamp: _ts(0),
      );

      final initialHeading = prev.headingDeg;

      // Apply a constant yaw rate of 1 rad/s for 0.5 seconds (25 steps at 50Hz)
      for (var i = 1; i <= 25; i++) {
        prev = applyFilter(
          prev: prev,
          accel: accel,
          mag: mag, // mag still says north — filter will blend
          gyro: _sample(0, 0, 1.0), // 1 rad/s yaw
          dt: 0.02,
          timestamp: _ts(i * 20),
        );
      }

      // Heading should have changed from the gyro integration
      // Exact value depends on blending, but it should be different
      expect((prev.headingDeg - initialHeading).abs(), greaterThan(5.0));
    });

    test('heading wraps around 0/360 correctly', () {
      final accel = _sample(0, 0, 9.81);
      // Magnetic field pointing mostly along -X with slight +Y = heading near 350
      final mag = _sample(-25.0, 4.4, -45.0);
      final gyro = _sample(0, 0, 0);

      final result = applyFilter(
        prev: null,
        accel: accel,
        mag: mag,
        gyro: gyro,
        dt: 0.0,
        timestamp: _ts(),
      );

      // Heading should be between 0 and 360
      expect(result.headingDeg, greaterThanOrEqualTo(0.0));
      expect(result.headingDeg, lessThan(360.0));
    });

    test('pitch clamped to -90..+90', () {
      // Extreme accelerometer values
      final accel = _sample(-20, 0, 0); // extreme forward tilt
      final mag = _sample(25.0, 0.0, -45.0);
      final gyro = _sample(0, 0, 0);

      final result = applyFilter(
        prev: null,
        accel: accel,
        mag: mag,
        gyro: gyro,
        dt: 0.0,
        timestamp: _ts(),
      );

      expect(result.pitchDeg, greaterThanOrEqualTo(-90.0));
      expect(result.pitchDeg, lessThanOrEqualTo(90.0));
    });

    test('roll wraps to -180..+180', () {
      // Device upside down: gravity along -Z
      final accel = _sample(0, 0, -9.81);
      final mag = _sample(25.0, 0.0, 45.0);
      final gyro = _sample(0, 0, 0);

      final result = applyFilter(
        prev: null,
        accel: accel,
        mag: mag,
        gyro: gyro,
        dt: 0.0,
        timestamp: _ts(),
      );

      expect(result.rollDeg, greaterThanOrEqualTo(-180.0));
      expect(result.rollDeg, lessThanOrEqualTo(180.0));
    });

    test('filter converges after many steps with consistent input', () {
      // Start from an arbitrary previous orientation
      final prev = OrientationSample(
        headingDeg: 45.0,
        pitchDeg: 20.0,
        rollDeg: -10.0,
        reliable: true,
        timestamp: _ts(0),
      );

      // Consistent sensor input saying: flat, pointing north
      final accel = _sample(0, 0, 9.81);
      final mag = _sample(25.0, 0.0, -45.0);
      final gyro = _sample(0, 0, 0); // no rotation

      var current = prev;
      // Run many steps — with zero gyro, the (1-alpha) term should gradually
      // pull the output toward the accel/mag reference (heading~0, pitch~0, roll~0)
      for (var i = 1; i <= 500; i++) {
        current = applyFilter(
          prev: current,
          accel: accel,
          mag: mag,
          gyro: gyro,
          dt: 0.02,
          timestamp: _ts(i * 20),
        );
      }

      // After 500 steps (10 seconds) with alpha=0.98, the filter should have
      // converged close to the reference: heading~0, pitch~0, roll~0
      expect(current.headingDeg, closeTo(0.0, 5.0));
      expect(current.pitchDeg, closeTo(0.0, 2.0));
      expect(current.rollDeg, closeTo(0.0, 2.0));
    });

    test('custom alpha=0 uses only accel/mag reference', () {
      final prev = OrientationSample(
        headingDeg: 90.0,
        pitchDeg: 45.0,
        rollDeg: 30.0,
        reliable: true,
        timestamp: _ts(0),
      );

      final accel = _sample(0, 0, 9.81);
      final mag = _sample(25.0, 0.0, -45.0);
      final gyro = _sample(0, 0, 0);

      final result = applyFilter(
        prev: prev,
        accel: accel,
        mag: mag,
        gyro: gyro,
        dt: 0.02,
        timestamp: _ts(20),
        alpha: 0.0, // ignore gyro entirely
      );

      // Should be purely the accel/mag reference
      expect(result.headingDeg, closeTo(0.0, 5.0));
      expect(result.pitchDeg, closeTo(0.0, 1.0));
      expect(result.rollDeg, closeTo(0.0, 1.0));
    });
  });

  group('SensorFusionEngine', () {
    test('starts in stopped state', () {
      final engine = SensorFusionEngine();
      expect(engine.isRunning, isFalse);
    });

    test('dispose can be called on a fresh engine', () async {
      final engine = SensorFusionEngine();
      await engine.dispose();
      expect(engine.isRunning, isFalse);
    });
  });
}
