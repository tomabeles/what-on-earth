import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:what_on_earth/tile_cache/tile_database.dart';

TileDatabase _createTestDb() => TileDatabase(NativeDatabase.memory());

void main() {
  group('TileDatabase', () {
    late TileDatabase db;

    setUp(() {
      db = _createTestDb();
    });

    tearDown(() async {
      await db.close();
    });

    test('database opens and TileMetadata table is created', () async {
      await db.recordDownload(
        tileKey: 'base/3/4/2',
        layerId: 'base',
        zoomLevel: 3,
        tileX: 4,
        tileY: 2,
        fileSizeBytes: 8192,
      );

      final count = await db.tileCount();
      expect(count, 1);
    });

    test('totalSizeBytes sums file sizes', () async {
      await db.recordDownload(
        tileKey: 'base/0/0/0',
        layerId: 'base',
        zoomLevel: 0,
        tileX: 0,
        tileY: 0,
        fileSizeBytes: 1000,
      );
      await db.recordDownload(
        tileKey: 'base/1/0/0',
        layerId: 'base',
        zoomLevel: 1,
        tileX: 0,
        tileY: 0,
        fileSizeBytes: 2000,
      );

      final total = await db.totalSizeBytes();
      expect(total, 3000);
    });

    test('recordAccess updates lastAccessedAt', () async {
      await db.recordDownload(
        tileKey: 'base/0/0/0',
        layerId: 'base',
        zoomLevel: 0,
        tileX: 0,
        tileY: 0,
        fileSizeBytes: 500,
      );

      // Wait a moment so timestamps differ
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await db.recordAccess('base/0/0/0');

      final lru = await db.lruTiles(10);
      expect(lru, hasLength(1));
      // lastAccessedAt should be more recent than downloadedAt
      expect(
        lru.first.lastAccessedAt.millisecondsSinceEpoch,
        greaterThanOrEqualTo(lru.first.downloadedAt.millisecondsSinceEpoch),
      );
    });

    test('lruTiles returns least recently accessed first', () async {
      await db.recordDownload(
        tileKey: 'base/0/0/0',
        layerId: 'base',
        zoomLevel: 0,
        tileX: 0,
        tileY: 0,
        fileSizeBytes: 500,
      );
      // Manually set lastAccessedAt via recordAccess on this tile
      await db.recordAccess('base/0/0/0');

      await db.recordDownload(
        tileKey: 'base/1/0/0',
        layerId: 'base',
        zoomLevel: 1,
        tileX: 0,
        tileY: 0,
        fileSizeBytes: 500,
      );
      // This tile was just downloaded so its lastAccessedAt is "now"

      final lru = await db.lruTiles(10);
      expect(lru, hasLength(2));
      // The first tile in LRU order has the earlier lastAccessedAt
      expect(
        lru.first.lastAccessedAt.millisecondsSinceEpoch,
        lessThanOrEqualTo(lru.last.lastAccessedAt.millisecondsSinceEpoch),
      );
    });

    test('deleteTile removes metadata', () async {
      await db.recordDownload(
        tileKey: 'base/0/0/0',
        layerId: 'base',
        zoomLevel: 0,
        tileX: 0,
        tileY: 0,
        fileSizeBytes: 500,
      );

      await db.deleteTile('base/0/0/0');

      final count = await db.tileCount();
      expect(count, 0);
    });

    test('recordDownload upserts on conflict', () async {
      await db.recordDownload(
        tileKey: 'base/0/0/0',
        layerId: 'base',
        zoomLevel: 0,
        tileX: 0,
        tileY: 0,
        fileSizeBytes: 500,
      );

      // Re-download with different size
      await db.recordDownload(
        tileKey: 'base/0/0/0',
        layerId: 'base',
        zoomLevel: 0,
        tileX: 0,
        tileY: 0,
        fileSizeBytes: 1000,
      );

      final count = await db.tileCount();
      expect(count, 1);
      final total = await db.totalSizeBytes();
      expect(total, 1000);
    });
  });
}
