import 'package:flutter_test/flutter_test.dart';
import 'package:what_on_earth/onboarding/calibration_step.dart';
import 'package:what_on_earth/sensors/sensor_fusion.dart';

void main() {
  group('computeHardIron', () {
    test('returns zero vector for empty samples', () {
      expect(computeHardIron([]), [0.0, 0.0, 0.0]);
    });

    test('computes midpoint of min/max per axis', () {
      final samples = [
        RawSensorSample(x: -10, y: -20, z: -30, timestamp: DateTime.now()),
        RawSensorSample(x: 10, y: 20, z: 30, timestamp: DateTime.now()),
        RawSensorSample(x: 5, y: 0, z: -5, timestamp: DateTime.now()),
      ];

      final bias = computeHardIron(samples);
      expect(bias[0], 0.0); // (-10+10)/2
      expect(bias[1], 0.0); // (-20+20)/2
      expect(bias[2], 0.0); // (-30+30)/2
    });

    test('computes correct bias for offset data', () {
      // Simulate a sensor with hard-iron offset of [10, -5, 3]
      // The samples are centered around the offset
      final samples = [
        RawSensorSample(x: -40, y: -55, z: -47, timestamp: DateTime.now()),
        RawSensorSample(x: 60, y: 45, z: 53, timestamp: DateTime.now()),
      ];

      final bias = computeHardIron(samples);
      expect(bias[0], 10.0); // (-40+60)/2
      expect(bias[1], -5.0); // (-55+45)/2
      expect(bias[2], 3.0); // (-47+53)/2
    });

    test('handles single sample', () {
      final samples = [
        RawSensorSample(x: 5, y: 10, z: 15, timestamp: DateTime.now()),
      ];

      final bias = computeHardIron(samples);
      expect(bias[0], 5.0);
      expect(bias[1], 10.0);
      expect(bias[2], 15.0);
    });
  });

  group('computeConfidence', () {
    test('returns 0 for fewer than 10 samples', () {
      final samples = List.generate(
        5,
        (i) => RawSensorSample(
          x: i.toDouble(),
          y: i.toDouble(),
          z: i.toDouble(),
          timestamp: DateTime.now(),
        ),
      );
      expect(computeConfidence(samples), 0.0);
    });

    test('returns low confidence for narrow spread', () {
      // All samples clustered — user didn't move
      final samples = List.generate(
        50,
        (i) => RawSensorSample(
          x: 25.0 + (i % 3) * 0.1,
          y: 10.0 + (i % 3) * 0.1,
          z: -5.0 + (i % 3) * 0.1,
          timestamp: DateTime.now(),
        ),
      );
      final conf = computeConfidence(samples);
      expect(conf, lessThan(0.3));
    });

    test('returns high confidence for well-spread samples', () {
      // Simulate good figure-8 coverage: ~60 µT spread on each axis
      final samples = <RawSensorSample>[];
      for (var i = 0; i < 150; i++) {
        final t = i / 150.0 * 3.14159 * 4;
        samples.add(RawSensorSample(
          x: 30.0 * (t.isNaN ? 0 : (i % 2 == 0 ? 1 : -1).toDouble()),
          y: 30.0 * (i % 3 == 0 ? 1 : -1).toDouble(),
          z: 30.0 * (i % 5 < 3 ? 1 : -1).toDouble(),
          timestamp: DateTime.now(),
        ));
      }
      final conf = computeConfidence(samples);
      expect(conf, greaterThan(0.7));
    });

    test('confidence increases with sample count', () {
      final baseSamples = <RawSensorSample>[];
      for (var i = 0; i < 200; i++) {
        baseSamples.add(RawSensorSample(
          x: 30.0 * (i % 2 == 0 ? 1 : -1).toDouble(),
          y: 30.0 * (i % 3 == 0 ? 1 : -1).toDouble(),
          z: 30.0 * (i % 5 < 3 ? 1 : -1).toDouble(),
          timestamp: DateTime.now(),
        ));
      }

      final conf50 = computeConfidence(baseSamples.sublist(0, 50));
      final conf150 = computeConfidence(baseSamples.sublist(0, 150));
      expect(conf150, greaterThanOrEqualTo(conf50));
    });
  });
}
