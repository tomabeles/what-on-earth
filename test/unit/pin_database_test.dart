import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:what_on_earth/pins/pin_database.dart';

PinDatabase _createTestDb() => PinDatabase(NativeDatabase.memory());

void main() {
  group('PinDatabase', () {
    late PinDatabase db;

    setUp(() {
      db = _createTestDb();
    });

    tearDown(() async {
      await db.close();
    });

    test('database opens and Pins table is created', () async {
      // Inserting should work without error
      await db.insertPin(PinsCompanion.insert(
        id: 'test-1',
        latDeg: 51.5,
        lonDeg: -0.1,
        name: 'London',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final pin = await db.getPinById('test-1');
      expect(pin, isNotNull);
      expect(pin!.name, 'London');
      expect(pin.latDeg, 51.5);
    });

    test('watchAllNonDeleted excludes soft-deleted pins', () async {
      final now = DateTime.now();
      await db.insertPin(PinsCompanion.insert(
        id: 'active-1',
        latDeg: 40.7,
        lonDeg: -74.0,
        name: 'New York',
        createdAt: now,
        updatedAt: now,
      ));
      await db.insertPin(PinsCompanion.insert(
        id: 'deleted-1',
        latDeg: 48.8,
        lonDeg: 2.3,
        name: 'Paris',
        createdAt: now,
        updatedAt: now,
        deletedAt: Value(now),
      ));

      final pins = await db.watchAllNonDeleted().first;
      expect(pins, hasLength(1));
      expect(pins.first.name, 'New York');
    });

    test('softDelete sets deletedAt', () async {
      final now = DateTime.now();
      await db.insertPin(PinsCompanion.insert(
        id: 'del-test',
        latDeg: 35.6,
        lonDeg: 139.7,
        name: 'Tokyo',
        createdAt: now,
        updatedAt: now,
      ));

      await db.softDelete('del-test');

      final pin = await db.getPinById('del-test');
      expect(pin, isNotNull);
      expect(pin!.deletedAt, isNotNull);
    });

    test('updatePin modifies fields', () async {
      final now = DateTime.now();
      await db.insertPin(PinsCompanion.insert(
        id: 'upd-test',
        latDeg: 0.0,
        lonDeg: 0.0,
        name: 'Origin',
        createdAt: now,
        updatedAt: now,
      ));

      await db.updatePin(PinsCompanion(
        id: const Value('upd-test'),
        name: const Value('Updated'),
        updatedAt: Value(DateTime.now()),
      ));

      final pin = await db.getPinById('upd-test');
      expect(pin!.name, 'Updated');
    });
  });
}
