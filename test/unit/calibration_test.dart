import 'package:flutter_test/flutter_test.dart';
import 'package:what_on_earth/sensors/calibration.dart';
import 'package:what_on_earth/sensors/sensor_fusion.dart';

void main() {
  group('CalibrationParams', () {
    test('toJson/fromJson round-trip', () {
      final params = CalibrationParams(
        hardIron: [10.0, -5.0, 3.0],
        softIron: [
          [1.0, 0.0, 0.0],
          [0.0, 1.0, 0.0],
          [0.0, 0.0, 1.0],
        ],
        calibratedAt: DateTime(2024, 6, 15, 12, 0),
        confidence: 0.85,
      );

      final json = params.toJson();
      final restored = CalibrationParams.fromJson(json);

      expect(restored.hardIron, params.hardIron);
      expect(restored.softIron, params.softIron);
      expect(restored.calibratedAt, params.calibratedAt);
      expect(restored.confidence, params.confidence);
    });

    test('identity factory has zero offsets', () {
      final id = CalibrationParams.identity();
      expect(id.hardIron, [0.0, 0.0, 0.0]);
      expect(id.confidence, 0.0);
    });
  });

  group('applyHardIronCorrection', () {
    test('subtracts hard-iron offset from raw sample', () {
      final raw = RawSensorSample(
        x: 25.0,
        y: -10.0,
        z: 40.0,
        timestamp: DateTime.now(),
      );
      final hardIron = [5.0, -3.0, 10.0];
      final corrected = applyHardIronCorrection(raw, hardIron);

      expect(corrected.x, 20.0); // 25 - 5
      expect(corrected.y, -7.0); // -10 - (-3)
      expect(corrected.z, 30.0); // 40 - 10
    });

    test('zero offset produces identical readings', () {
      final raw = RawSensorSample(
        x: 15.0,
        y: 20.0,
        z: -5.0,
        timestamp: DateTime.now(),
      );
      final corrected = applyHardIronCorrection(raw, [0.0, 0.0, 0.0]);

      expect(corrected.x, raw.x);
      expect(corrected.y, raw.y);
      expect(corrected.z, raw.z);
    });
  });
}
