import 'package:flutter_test/flutter_test.dart';
import 'package:what_on_earth/globe/bridge.dart';

void main() {
  group('PassCalcResponse', () {
    test('fromJson parses successful result', () {
      final json = {
        'requestId': 'abc-123',
        'passStartUtc': 1700000000000,
        'maxElevationDeg': 45.5,
        'passDurationSeconds': 300,
      };
      final r = PassCalcResponse.fromJson(json);
      expect(r.requestId, 'abc-123');
      expect(r.hasPass, isTrue);
      expect(r.passStartUtc, isNotNull);
      expect(r.maxElevationDeg, 45.5);
      expect(r.passDurationSeconds, 300);
      expect(r.error, isNull);
    });

    test('fromJson parses error result', () {
      final json = {
        'requestId': 'def-456',
        'error': 'no_pass_found',
      };
      final r = PassCalcResponse.fromJson(json);
      expect(r.requestId, 'def-456');
      expect(r.hasPass, isFalse);
      expect(r.error, 'no_pass_found');
    });
  });

  group('MapTapEvent', () {
    test('stores lat/lon', () {
      const e = MapTapEvent(lat: 51.5, lon: -0.1);
      expect(e.lat, 51.5);
      expect(e.lon, -0.1);
    });
  });
}
