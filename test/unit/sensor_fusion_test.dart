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
  group('accelPitch', () {
    test('phone flat screen up gives ~0° pitch (nadir)', () {
      // Gravity along +Z (device face up, flat)
      final accel = _sample(0, 0, 9.81);
      expect(accelPitch(accel), closeTo(0.0, 1.0));
    });

    test('phone upright gives ~90° pitch (horizon)', () {
      // Gravity along +Y (device upright in portrait)
      final accel = _sample(0, 9.81, 0);
      expect(accelPitch(accel), closeTo(90.0, 1.0));
    });

    test('phone at 45° gives ~45° pitch', () {
      // Gravity split between Y and Z
      final g = 9.81 / math.sqrt(2);
      final accel = _sample(0, g, g);
      expect(accelPitch(accel), closeTo(45.0, 2.0));
    });

    test('phone screen down gives ~180° pitch (zenith)', () {
      // Gravity along -Z (device face down)
      final accel = _sample(0, 0, -9.81);
      expect(accelPitch(accel), closeTo(180.0, 1.0));
    });

    test('pitch is independent of orientation mode (portrait)', () {
      // Phone upright, gravity along +Y
      final accel = _sample(0, 9.81, 0);
      expect(accelPitch(accel), closeTo(90.0, 1.0));
    });

    test('pitch is independent of orientation mode (landscape upright)', () {
      // Phone upright in landscape, gravity along +X
      final accel = _sample(9.81, 0, 0);
      expect(accelPitch(accel), closeTo(90.0, 1.0));
    });
  });

  group('accelRoll', () {
    test('portrait: level phone gives ~0° roll', () {
      // Phone upright, gravity along +Y (no sideways tilt)
      final accel = _sample(0, 9.81, 0);
      expect(accelRoll(accel, OrientationMode.portrait), closeTo(0.0, 1.0));
    });

    test('portrait: phone tilted right gives positive roll', () {
      // Right side drops: gravity component along +X
      final ax = 9.81 * math.sin(30 * math.pi / 180);
      final ay = 9.81 * math.cos(30 * math.pi / 180);
      final accel = _sample(ax, ay, 0);
      expect(accelRoll(accel, OrientationMode.portrait), closeTo(30.0, 2.0));
    });

    test('portrait: phone tilted left gives negative roll', () {
      // Left side drops: gravity component along -X
      final ax = -9.81 * math.sin(30 * math.pi / 180);
      final ay = 9.81 * math.cos(30 * math.pi / 180);
      final accel = _sample(ax, ay, 0);
      expect(accelRoll(accel, OrientationMode.portrait), closeTo(-30.0, 2.0));
    });

    test('landscape: level phone gives ~0° roll', () {
      // Phone upright in landscape, gravity along +X (no sideways tilt)
      final accel = _sample(9.81, 0, 0);
      expect(accelRoll(accel, OrientationMode.landscape), closeTo(0.0, 1.0));
    });

    test('landscape: phone tilted right gives positive roll', () {
      // Right side (Y direction in landscape) drops
      final ay = 9.81 * math.sin(30 * math.pi / 180);
      final ax = 9.81 * math.cos(30 * math.pi / 180);
      final accel = _sample(ax, ay, 0);
      expect(accelRoll(accel, OrientationMode.landscape), closeTo(30.0, 2.0));
    });
  });

  group('tiltCompensatedHeading (legacy)', () {
    test('north-pointing device gives ~0° heading', () {
      final mag = _sample(25.0, 0.0, -45.0);
      final heading = tiltCompensatedHeading(mag, 0.0, 0.0);
      expect(heading * 180 / math.pi, closeTo(0.0, 5.0));
    });

    test('east-pointing device gives ~90° heading', () {
      final mag = _sample(0.0, -25.0, -45.0);
      final heading = tiltCompensatedHeading(mag, 0.0, 0.0);
      expect(heading * 180 / math.pi, closeTo(90.0, 5.0));
    });

    test('south-pointing device gives ~180° heading', () {
      final mag = _sample(-25.0, 0.0, -45.0);
      final heading = tiltCompensatedHeading(mag, 0.0, 0.0);
      expect(heading * 180 / math.pi, closeTo(180.0, 5.0));
    });
  });

  group('vectorHeading', () {
    test('flat phone with north along +X gives ~0° (fallback)', () {
      // Flat phone: camera points down → fallback to tilt-compensated.
      // mag +X = north → heading 0°.
      final accel = _sample(0, 0, 9.81);
      final mag = _sample(25.0, 0.0, -45.0);
      expect(vectorHeading(accel, mag), closeTo(0.0, 5.0));
    });

    test('flat phone with east field gives ~90° (fallback)', () {
      final accel = _sample(0, 0, 9.81);
      final mag = _sample(0.0, -25.0, -45.0);
      expect(vectorHeading(accel, mag), closeTo(90.0, 5.0));
    });

    test('flat phone with south field gives ~180° (fallback)', () {
      final accel = _sample(0, 0, 9.81);
      final mag = _sample(-25.0, 0.0, -45.0);
      expect(vectorHeading(accel, mag), closeTo(180.0, 5.0));
    });

    test('upright portrait phone facing north gives ~0°', () {
      // Gravity along +Y. Camera (-Z) faces north.
      // Body: +X = east, +Y = up, +Z = south.
      // Mag: Bx=0(east), By=-45(down), Bz=-25(north along -Z).
      final accel = _sample(0, 9.81, 0);
      final mag = _sample(0, -45.0, -25.0);
      expect(vectorHeading(accel, mag), closeTo(0.0, 5.0));
    });

    test('upright portrait phone facing east gives ~90°', () {
      // Camera (-Z) faces east.
      // Body: +X = south, +Y = up, +Z = west.
      // Mag: Bx=-25(south), By=-45(down), Bz=0(west has no field).
      final accel = _sample(0, 9.81, 0);
      final mag = _sample(-25.0, -45.0, 0);
      expect(vectorHeading(accel, mag), closeTo(90.0, 5.0));
    });

    test('upright landscape LEFT phone facing north gives ~0°', () {
      // Gravity along +X. Camera (-Z) faces north.
      // Body: +X = up, +Y = south, +Z = east... wait
      // Let me derive: for right-handed body (X up, camera -Z = north):
      //   +Z = south, so +Y = Z × X = south × up.
      //   south × up = east? Let's see: (0,-1,0)×(0,0,1) in world = (−1,0,0)
      //   Hmm, let me just use: mag_body_x = B·(up) = −45,
      //   need to figure out Y and Z world directions.
      //
      // For landscape LEFT upright facing north:
      //   +X = up, −Z = north (camera), +Z = south
      //   Right-handed: Y = Z × X → south × up
      //   In world: south=(−1,0,0), up=(0,0,1)
      //   Y = (−1,0,0)×(0,0,1) = (0·1−0·0, 0·(−1)−0·1, 0·0−0·0)...
      //   Actually just compute: south × up = (−1,0,0)×(0,0,1) = (0,1,0) = east
      //   So +Y = east. Then:
      //   Bx = B·up = −45, By = B·east = 0, Bz = B·south = −25
      final accel = _sample(9.81, 0, 0);
      final mag = _sample(-45.0, 0, -25.0);
      expect(vectorHeading(accel, mag), closeTo(0.0, 5.0));
    });

    test('no singularity at pitch 90° — heading is stable', () {
      // Phone upright portrait. Small noise in az should NOT flip heading.
      final accel1 = _sample(0, 9.81, 0.01);
      final accel2 = _sample(0, 9.81, -0.01);
      final mag = _sample(0, -45.0, -25.0);

      final h1 = vectorHeading(accel1, mag);
      final h2 = vectorHeading(accel2, mag);

      var delta = (h1 - h2).abs();
      if (delta > 180) delta = 360 - delta;
      expect(delta, lessThan(2.0));
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

      // Flat device pointing north: heading ~0, pitch ~0 (nadir), roll ~0
      expect(result.headingDeg, closeTo(0.0, 5.0));
      expect(result.pitchDeg, closeTo(0.0, 1.0));
      expect(result.reliable, isTrue);
    });

    test('upright portrait device gives ~90° pitch', () {
      // Gravity along +Y → pitch should be 90° (horizon)
      final accel = _sample(0, 9.81, 0);
      final mag = _sample(25.0, 0.0, -45.0);
      final gyro = _sample(0, 0, 0);

      final result = applyFilter(
        prev: null,
        accel: accel,
        mag: mag,
        gyro: gyro,
        dt: 0.0,
        timestamp: _ts(),
        mode: OrientationMode.portrait,
      );

      expect(result.pitchDeg, closeTo(90.0, 2.0));
    });

    test('screen-down device gives ~180° pitch (zenith)', () {
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

      expect(result.pitchDeg, closeTo(180.0, 2.0));
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

    test('gyro rotation changes heading (portrait upright)', () {
      // Phone upright in portrait: gravity along +Y.
      // Yaw = rotation around Y axis → gyro.y projects onto gravity.
      final accel = _sample(0, 9.81, 0);
      final mag = _sample(25.0, 0.0, -45.0);

      var prev = applyFilter(
        prev: null,
        accel: accel,
        mag: mag,
        gyro: _sample(0, 0, 0),
        dt: 0.0,
        timestamp: _ts(0),
        mode: OrientationMode.portrait,
      );

      final initialHeading = prev.headingDeg;

      for (var i = 1; i <= 25; i++) {
        prev = applyFilter(
          prev: prev,
          accel: accel,
          mag: mag,
          gyro: _sample(0, 1.0, 0), // gyro.y = yaw rate when Y is up
          dt: 0.02,
          timestamp: _ts(i * 20),
          mode: OrientationMode.portrait,
        );
      }

      expect((prev.headingDeg - initialHeading).abs(), greaterThan(5.0));
    });

    test('gyro rotation changes heading (landscape upright)', () {
      // Phone upright in landscape: gravity along +X.
      // Yaw = rotation around X axis → gyro.x projects onto gravity.
      final accel = _sample(9.81, 0, 0);
      final mag = _sample(25.0, 0.0, -45.0);

      var prev = applyFilter(
        prev: null,
        accel: accel,
        mag: mag,
        gyro: _sample(0, 0, 0),
        dt: 0.0,
        timestamp: _ts(0),
        mode: OrientationMode.landscape,
      );

      final initialHeading = prev.headingDeg;

      for (var i = 1; i <= 25; i++) {
        prev = applyFilter(
          prev: prev,
          accel: accel,
          mag: mag,
          gyro: _sample(1.0, 0, 0), // gyro.x = yaw rate when X is up
          dt: 0.02,
          timestamp: _ts(i * 20),
          mode: OrientationMode.landscape,
        );
      }

      expect((prev.headingDeg - initialHeading).abs(), greaterThan(5.0));
    });

    test('gyro rotation changes heading (flat phone uses gyro.z)', () {
      // Phone flat: gravity along +Z. Yaw projects onto gyro.z.
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

      for (var i = 1; i <= 25; i++) {
        prev = applyFilter(
          prev: prev,
          accel: accel,
          mag: mag,
          gyro: _sample(0, 0, 1.0), // gyro.z = yaw rate when Z is up
          dt: 0.02,
          timestamp: _ts(i * 20),
        );
      }

      expect((prev.headingDeg - initialHeading).abs(), greaterThan(5.0));
    });

    test('heading wraps around 0/360 correctly', () {
      final accel = _sample(0, 0, 9.81);
      // Magnetic field producing heading near 350°
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

      expect(result.headingDeg, greaterThanOrEqualTo(0.0));
      expect(result.headingDeg, lessThan(360.0));
    });

    test('pitch clamped to 0..180', () {
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

      expect(result.pitchDeg, greaterThanOrEqualTo(0.0));
      expect(result.pitchDeg, lessThanOrEqualTo(180.0));
    });

    test('roll wraps to -180..+180', () {
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

    test('adaptive alpha suppresses centripetal acceleration', () {
      // Phone upright in landscape (pitch 90°), rotating.
      // Centripetal acceleration adds ~5 m/s² to az, corrupting the reference.
      final uprightAccel = _sample(9.81, 0, 0);
      final corruptedAccel = _sample(9.81, 0, 5.0); // centripetal along Z
      final mag = _sample(25.0, 0.0, -45.0);
      final gyro = _sample(0, 0, 0);

      final start = applyFilter(
        prev: null,
        accel: uprightAccel,
        mag: mag,
        gyro: gyro,
        dt: 0.0,
        timestamp: _ts(0),
        mode: OrientationMode.landscape,
      );
      expect(start.pitchDeg, closeTo(90.0, 1.0));

      // With corrupted accel, the reference pitch would be ~63° (not 90°).
      // Without adaptive alpha, the filter would pull pitch toward 63°.
      // With adaptive alpha, the deviation from 1g triggers higher alpha,
      // so pitch should stay much closer to 90°.
      var current = start;
      for (var i = 1; i <= 50; i++) {
        current = applyFilter(
          prev: current,
          accel: corruptedAccel,
          mag: mag,
          gyro: gyro,
          dt: 0.02,
          timestamp: _ts(i * 20),
          mode: OrientationMode.landscape,
        );
      }

      // After 1 second of corrupted accel, pitch should still be near 90°
      // (not dragged down to ~63° as it would be without adaptive alpha)
      expect(current.pitchDeg, greaterThan(85.0));
    });

    test('filter converges after many steps with consistent input', () {
      // Start from an arbitrary previous orientation
      final prev = OrientationSample(
        headingDeg: 45.0,
        pitchDeg: 100.0,
        rollDeg: -10.0,
        reliable: true,
        timestamp: _ts(0),
      );

      // Consistent sensor input: flat device pointing north
      final accel = _sample(0, 0, 9.81);
      final mag = _sample(25.0, 0.0, -45.0);
      final gyro = _sample(0, 0, 0);

      var current = prev;
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

      // After 500 steps (10s) with alpha=0.98, should converge to reference:
      // heading ~0, pitch ~0 (nadir), roll ~0
      expect(current.headingDeg, closeTo(0.0, 5.0));
      expect(current.pitchDeg, closeTo(0.0, 2.0));
      expect(current.rollDeg, closeTo(0.0, 2.0));
    });

    test('custom alpha=0 uses only accel/mag reference', () {
      final prev = OrientationSample(
        headingDeg: 90.0,
        pitchDeg: 120.0,
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
        alpha: 0.0,
      );

      // Should be purely the accel/mag reference
      expect(result.headingDeg, closeTo(0.0, 5.0));
      expect(result.pitchDeg, closeTo(0.0, 1.0));
    });

    test('portrait and landscape produce same pitch for same physical tilt',
        () {
      // Phone at 45° tilt — gravity split between two axes
      // Portrait upright at 45°: gravity between Y and Z
      final g = 9.81 / math.sqrt(2);
      final accelPortrait = _sample(0, g, g);
      // Landscape upright at 45°: gravity between X and Z
      final accelLandscape = _sample(g, 0, g);

      final mag = _sample(25.0, 0.0, -45.0);
      final gyro = _sample(0, 0, 0);

      final portrait = applyFilter(
        prev: null,
        accel: accelPortrait,
        mag: mag,
        gyro: gyro,
        dt: 0.0,
        timestamp: _ts(),
        mode: OrientationMode.portrait,
      );

      final landscape = applyFilter(
        prev: null,
        accel: accelLandscape,
        mag: mag,
        gyro: gyro,
        dt: 0.0,
        timestamp: _ts(),
        mode: OrientationMode.landscape,
      );

      // Both should read ~45° pitch
      expect(portrait.pitchDeg, closeTo(45.0, 2.0));
      expect(landscape.pitchDeg, closeTo(45.0, 2.0));
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

    test('default orientation mode is landscape', () {
      final engine = SensorFusionEngine();
      expect(engine.orientationMode, OrientationMode.landscape);
    });

    test('setOrientationMode changes mode', () {
      final engine = SensorFusionEngine();
      engine.setOrientationMode(OrientationMode.portrait);
      expect(engine.orientationMode, OrientationMode.portrait);
    });
  });
}
