import 'package:flutter_test/flutter_test.dart';
import 'package:what_on_earth/position/position_source.dart';

void main() {
  // A fixed timestamp (UTC) used across tests.
  final ts = DateTime.utc(2026, 3, 2, 12, 0, 0);

  OrbitalPosition makePosition({
    double lat = 51.5,
    double lon = -0.1,
    double alt = 420.0,
    DateTime? timestamp,
    PositionSourceType source = PositionSourceType.live,
  }) =>
      OrbitalPosition(
        latDeg: lat,
        lonDeg: lon,
        altKm: alt,
        timestamp: timestamp ?? ts,
        sourceType: source,
      );

  group('OrbitalPosition.toJson', () {
    test('produces expected map', () {
      final pos = makePosition();
      final json = pos.toJson();

      expect(json['lat'], 51.5);
      expect(json['lon'], -0.1);
      expect(json['altKm'], 420.0);
      expect(json['ts'], ts.millisecondsSinceEpoch);
      expect(json['source'], 'live');
    });

    test('source field matches PositionSourceType.name for all types', () {
      for (final type in PositionSourceType.values) {
        final json = makePosition(source: type).toJson();
        expect(json['source'], type.name);
      }
    });
  });

  group('OrbitalPosition.fromJson', () {
    test('round-trips through toJson', () {
      final original = makePosition(source: PositionSourceType.estimated);
      final roundTripped = OrbitalPosition.fromJson(original.toJson());
      expect(roundTripped, equals(original));
    });

    test('parses all PositionSourceType values', () {
      for (final type in PositionSourceType.values) {
        final json = makePosition(source: type).toJson();
        final parsed = OrbitalPosition.fromJson(json);
        expect(parsed.sourceType, type);
      }
    });

    test('timestamp survives round-trip as UTC milliseconds', () {
      final original = makePosition();
      final parsed = OrbitalPosition.fromJson(original.toJson());
      expect(parsed.timestamp.isUtc, isTrue);
      expect(
        parsed.timestamp.millisecondsSinceEpoch,
        ts.millisecondsSinceEpoch,
      );
    });

    test('accepts num types for numeric fields', () {
      final json = <String, dynamic>{
        'lat': 51,   // int, not double
        'lon': -0,
        'altKm': 420,
        'ts': ts.millisecondsSinceEpoch,
        'source': 'static',
      };
      final pos = OrbitalPosition.fromJson(json);
      expect(pos.latDeg, 51.0);
      expect(pos.altKm, 420.0);
      expect(pos.sourceType, PositionSourceType.static);
    });
  });

  group('OrbitalPosition equality', () {
    test('two instances with same values are equal', () {
      final a = makePosition();
      final b = makePosition();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('differs when latDeg differs', () {
      expect(makePosition(lat: 1.0), isNot(equals(makePosition(lat: 2.0))));
    });

    test('differs when lonDeg differs', () {
      expect(makePosition(lon: 1.0), isNot(equals(makePosition(lon: 2.0))));
    });

    test('differs when altKm differs', () {
      expect(makePosition(alt: 400.0), isNot(equals(makePosition(alt: 410.0))));
    });

    test('differs when timestamp differs', () {
      final a = makePosition(timestamp: DateTime.utc(2026, 1, 1));
      final b = makePosition(timestamp: DateTime.utc(2026, 1, 2));
      expect(a, isNot(equals(b)));
    });

    test('differs when sourceType differs', () {
      expect(
        makePosition(source: PositionSourceType.live),
        isNot(equals(makePosition(source: PositionSourceType.estimated))),
      );
    });

    test('identical instance equals itself', () {
      final pos = makePosition();
      expect(pos, equals(pos));
    });
  });

  group('OrbitalPosition.copyWith', () {
    test('returns equal instance when no fields overridden', () {
      final pos = makePosition();
      expect(pos.copyWith(), equals(pos));
    });

    test('overrides only specified fields', () {
      final pos = makePosition();
      final updated = pos.copyWith(altKm: 500.0, sourceType: PositionSourceType.estimated);
      expect(updated.latDeg, pos.latDeg);
      expect(updated.lonDeg, pos.lonDeg);
      expect(updated.altKm, 500.0);
      expect(updated.sourceType, PositionSourceType.estimated);
      expect(updated.timestamp, pos.timestamp);
    });
  });
}
