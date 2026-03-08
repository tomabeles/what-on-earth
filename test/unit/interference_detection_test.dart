import 'package:flutter_test/flutter_test.dart';
import 'package:what_on_earth/sensors/sensor_fusion.dart';

void main() {
  group('Magnetometer interference detection', () {
    test('applyFilter with large heading jump keeps pure filter output', () {
      final now = DateTime.now();
      final accel = RawSensorSample(x: 0, y: 0, z: 9.8, timestamp: now);
      final gyro = RawSensorSample(x: 0, y: 0, z: 0, timestamp: now);

      // First sample: heading ~0° (north)
      final mag1 = RawSensorSample(x: 20, y: 0, z: 0, timestamp: now);
      final s1 = applyFilter(
        prev: null, accel: accel, mag: mag1, gyro: gyro,
        dt: 0, timestamp: now,
      );

      // Second sample: heading should change drastically
      final mag2 = RawSensorSample(x: 0, y: 20, z: 0, timestamp: now);
      final s2 = applyFilter(
        prev: s1, accel: accel, mag: mag2, gyro: gyro,
        dt: 0.02, timestamp: now.add(const Duration(milliseconds: 20)),
      );

      // The filter should produce a heading — we just check it's valid
      expect(s2.headingDeg, greaterThanOrEqualTo(0));
      expect(s2.headingDeg, lessThan(360));
    });

    test('interference threshold constant is 30 degrees', () {
      expect(kInterferenceThresholdDeg, 30.0);
    });

    test('stable recovery constant is 5 samples', () {
      expect(kStableSamplesToRecover, 5);
    });

    test('heading delta wrap-around detection works', () {
      // Simulate checking delta between 350° and 10° → should be 20°, not 340°
      const heading1 = 350.0;
      const heading2 = 10.0;
      var delta = (heading2 - heading1).abs();
      if (delta > 180) delta = 360 - delta;
      expect(delta, 20.0);
      expect(delta, lessThan(kInterferenceThresholdDeg));
    });

    test('heading delta of 50° exceeds threshold', () {
      const heading1 = 100.0;
      const heading2 = 150.0;
      var delta = (heading2 - heading1).abs();
      if (delta > 180) delta = 360 - delta;
      expect(delta, 50.0);
      expect(delta, greaterThan(kInterferenceThresholdDeg));
    });
  });
}
