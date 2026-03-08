import 'package:flutter_test/flutter_test.dart';
import 'package:what_on_earth/sensors/device_orientation.dart';

void main() {
  group('DeviceOrientation', () {
    test('toJson produces correct keys', () {
      final now = DateTime(2024, 1, 1);
      final o = DeviceOrientation(
        headingDeg: 90.0,
        pitchDeg: 45.0,
        rollDeg: -10.0,
        reliable: true,
        timestamp: now,
      );

      final json = o.toJson();
      expect(json['heading'], 90.0);
      expect(json['pitch'], 45.0);
      expect(json['roll'], -10.0);
      expect(json['reliable'], true);
      expect(json['ts'], now.millisecondsSinceEpoch);
    });

    test('toString includes all fields', () {
      final o = DeviceOrientation(
        headingDeg: 180.0,
        pitchDeg: 0.0,
        rollDeg: 5.5,
        reliable: false,
        timestamp: DateTime.now(),
      );
      expect(o.toString(), contains('hdg=180.0'));
      expect(o.toString(), contains('reliable=false'));
    });
  });
}
