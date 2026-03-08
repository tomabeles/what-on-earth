import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:what_on_earth/pins/pin_database.dart';
import 'package:what_on_earth/pins/pin_repository.dart';

PinDatabase _createTestDb() => PinDatabase(NativeDatabase.memory());

void main() {
  group('PinRepository', () {
    late PinDatabase db;
    late PinRepository repo;

    setUp(() {
      db = _createTestDb();
      repo = PinRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('createPin generates UUID and returns pin', () async {
      final pin = await repo.createPin(
        name: 'London',
        latDeg: 51.5,
        lonDeg: -0.1,
      );

      expect(pin.id, isNotEmpty);
      expect(pin.name, 'London');
      expect(pin.latDeg, 51.5);
      expect(pin.lonDeg, -0.1);
      expect(pin.iconId, 0);
      expect(pin.deletedAt, isNull);
    });

    test('watchAllPins sees created pin', () async {
      await repo.createPin(name: 'Tokyo', latDeg: 35.6, lonDeg: 139.7);

      final pins = await repo.watchAllPins().first;
      expect(pins, hasLength(1));
      expect(pins.first.name, 'Tokyo');
    });

    test('getPinById returns correct pin', () async {
      final created = await repo.createPin(
        name: 'Paris',
        latDeg: 48.8,
        lonDeg: 2.3,
      );

      final found = await repo.getPinById(created.id);
      expect(found, isNotNull);
      expect(found!.name, 'Paris');
    });

    test('getPinById returns null for unknown id', () async {
      final found = await repo.getPinById('nonexistent');
      expect(found, isNull);
    });

    test('updatePin changes fields and sets updatedAt', () async {
      final created = await repo.createPin(
        name: 'Original',
        latDeg: 0.0,
        lonDeg: 0.0,
      );

      final updated = Pin(
        id: created.id,
        name: 'Updated',
        latDeg: created.latDeg,
        lonDeg: created.lonDeg,
        iconId: created.iconId,
        note: 'a note',
        createdAt: created.createdAt,
        updatedAt: created.updatedAt,
        deletedAt: null,
      );
      await repo.updatePin(updated);

      final found = await repo.getPinById(created.id);
      expect(found!.name, 'Updated');
      expect(found.note, 'a note');
      expect(
        found.updatedAt.millisecondsSinceEpoch,
        greaterThanOrEqualTo(created.updatedAt.millisecondsSinceEpoch),
      );
    });

    test('deletePin soft-deletes and hides from watchAllPins', () async {
      final pin = await repo.createPin(
        name: 'Deleted',
        latDeg: 10.0,
        lonDeg: 20.0,
      );

      await repo.deletePin(pin.id);

      final pins = await repo.watchAllPins().first;
      expect(pins, isEmpty);

      // But the pin still exists in the database
      final found = await repo.getPinById(pin.id);
      expect(found, isNotNull);
      expect(found!.deletedAt, isNotNull);
    });

    test('createPin with optional fields', () async {
      final pin = await repo.createPin(
        name: 'Noted',
        latDeg: 1.0,
        lonDeg: 2.0,
        iconId: 5,
        note: 'test note',
      );

      expect(pin.iconId, 5);
      expect(pin.note, 'test note');
    });
  });
}
