import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'tile_database.g.dart';

/// Drift table definition for tile cache metadata (TECH_SPEC §9.4).
///
/// Stored in a separate database (`tile_metadata.db`) from the pin database.
class TileMetadataTable extends Table {
  /// Composite key: `"{layer}/{z}/{x}/{y}"`.
  TextColumn get tileKey => text()();
  TextColumn get layerId => text()();
  IntColumn get zoomLevel => integer()();
  IntColumn get tileX => integer()();
  IntColumn get tileY => integer()();
  IntColumn get fileSizeBytes => integer()();
  DateTimeColumn get downloadedAt => dateTime()();
  DateTimeColumn get lastAccessedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {tileKey};
}

@DriftDatabase(tables: [TileMetadataTable])
class TileDatabase extends _$TileDatabase {
  TileDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'tile_metadata');
  }

  // ── Queries ───────────────────────────────────────────────────────────────

  /// Record that a tile was downloaded (insert or replace).
  Future<void> recordDownload({
    required String tileKey,
    required String layerId,
    required int zoomLevel,
    required int tileX,
    required int tileY,
    required int fileSizeBytes,
  }) {
    final now = DateTime.now();
    return into(tileMetadataTable).insertOnConflictUpdate(
      TileMetadataTableCompanion.insert(
        tileKey: tileKey,
        layerId: layerId,
        zoomLevel: zoomLevel,
        tileX: tileX,
        tileY: tileY,
        fileSizeBytes: fileSizeBytes,
        downloadedAt: now,
        lastAccessedAt: now,
      ),
    );
  }

  /// Update the last-accessed timestamp when a tile is served.
  Future<void> recordAccess(String key) {
    return (update(tileMetadataTable)
          ..where((t) => t.tileKey.equals(key)))
        .write(
      TileMetadataTableCompanion(
        lastAccessedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Total cache size in bytes.
  Future<int> totalSizeBytes() async {
    final query = selectOnly(tileMetadataTable)
      ..addColumns([tileMetadataTable.fileSizeBytes.sum()]);
    final result = await query.getSingle();
    return result.read(tileMetadataTable.fileSizeBytes.sum()) ?? 0;
  }

  /// Total number of cached tiles.
  Future<int> tileCount() async {
    final query = selectOnly(tileMetadataTable)
      ..addColumns([tileMetadataTable.tileKey.count()]);
    final result = await query.getSingle();
    return result.read(tileMetadataTable.tileKey.count()) ?? 0;
  }

  /// Get LRU tiles (least recently accessed first), limited to [limit] rows.
  Future<List<TileMetadataTableData>> lruTiles(int limit) {
    return (select(tileMetadataTable)
          ..orderBy([
            (t) => OrderingTerm.asc(t.lastAccessedAt),
          ])
          ..limit(limit))
        .get();
  }

  /// Delete a tile metadata row by key.
  Future<void> deleteTile(String key) {
    return (delete(tileMetadataTable)
          ..where((t) => t.tileKey.equals(key)))
        .go();
  }
}
