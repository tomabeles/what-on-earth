import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'pin_database.dart';

const _uuid = Uuid();

/// Domain-level API for pin CRUD operations (TECH_SPEC §7.4, §9.3).
///
/// Wraps [PinDatabase] and maps between drift row types and domain queries.
class PinRepository {
  final PinDatabase _db;

  PinRepository(this._db);

  /// Watch all non-deleted pins, ordered by most recently updated.
  Stream<List<Pin>> watchAllPins() => _db.watchAllNonDeleted();

  /// Get a single pin by ID, or null.
  Future<Pin?> getPinById(String id) => _db.getPinById(id);

  /// Create a new pin with a generated UUID.
  Future<Pin> createPin({
    required String name,
    required double latDeg,
    required double lonDeg,
    int iconId = 0,
    String? note,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    final companion = PinsCompanion.insert(
      id: id,
      latDeg: latDeg,
      lonDeg: lonDeg,
      name: name,
      createdAt: now,
      updatedAt: now,
      iconId: Value(iconId),
      note: Value(note),
    );
    await _db.insertPin(companion);
    return (await _db.getPinById(id))!;
  }

  /// Update an existing pin. Sets `updatedAt` to now.
  Future<void> updatePin(Pin pin) {
    return _db.updatePin(PinsCompanion(
      id: Value(pin.id),
      name: Value(pin.name),
      latDeg: Value(pin.latDeg),
      lonDeg: Value(pin.lonDeg),
      iconId: Value(pin.iconId),
      note: Value(pin.note),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Soft-delete a pin by ID.
  Future<void> deletePin(String id) => _db.softDelete(id);
}
