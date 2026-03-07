import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'pin_database.g.dart';

/// Drift table definition for user-created pins (TECH_SPEC §9.3).
class Pins extends Table {
  TextColumn get id => text()();
  RealColumn get latDeg => real()();
  RealColumn get lonDeg => real()();
  TextColumn get name => text().withLength(max: 100)();
  TextColumn get note => text().nullable()();
  IntColumn get iconId => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Pins])
class PinDatabase extends _$PinDatabase {
  PinDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'pins');
  }

  // ── DAO-style queries ─────────────────────────────────────────────────────

  /// Watch all non-deleted pins, ordered by most recently updated.
  Stream<List<Pin>> watchAllNonDeleted() {
    return (select(pins)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm.desc(t.updatedAt),
          ]))
        .watch();
  }

  /// Get a single pin by ID, or null.
  Future<Pin?> getPinById(String pinId) {
    return (select(pins)..where((t) => t.id.equals(pinId)))
        .getSingleOrNull();
  }

  /// Insert a new pin row.
  Future<void> insertPin(PinsCompanion entry) {
    return into(pins).insert(entry);
  }

  /// Update an existing pin row.
  Future<void> updatePin(PinsCompanion entry) {
    return (update(pins)..where((t) => t.id.equals(entry.id.value)))
        .write(entry);
  }

  /// Soft-delete: sets `deletedAt` to now.
  Future<void> softDelete(String pinId) {
    return (update(pins)..where((t) => t.id.equals(pinId))).write(
      PinsCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
