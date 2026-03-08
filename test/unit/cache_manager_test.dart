import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:what_on_earth/tile_cache/cache_manager.dart';
import 'package:what_on_earth/tile_cache/tile_database.dart';

TileDatabase _createTestDb() => TileDatabase(NativeDatabase.memory());

void main() {
  group('TileCacheManager', () {
    late TileDatabase db;
    late Directory tmpDir;
    late TileCacheManager manager;

    setUp(() async {
      db = _createTestDb();
      tmpDir = await Directory.systemTemp.createTemp('cache_test_');
      manager = TileCacheManager(db: db, documentsPath: tmpDir.path);
    });

    tearDown(() async {
      await db.close();
      if (tmpDir.existsSync()) await tmpDir.delete(recursive: true);
    });

    test('recordDownload and getCacheStatus', () async {
      await manager.recordDownload(
        layerId: 'base', z: 0, x: 0, y: 0, fileSizeBytes: 1000,
      );
      await manager.recordDownload(
        layerId: 'base', z: 1, x: 0, y: 0, fileSizeBytes: 2000,
      );

      final status = await manager.getCacheStatus();
      expect(status.tileCount, 2);
      expect(status.totalSizeBytes, 3000);
    });

    test('enforceMaxSize evicts LRU tiles', () async {
      // Create tile files on disk
      for (var i = 0; i < 5; i++) {
        final file = File('${tmpDir.path}/tiles/base/0/0/$i.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(List.filled(100, 0));
        await manager.recordDownload(
          layerId: 'base', z: 0, x: 0, y: i, fileSizeBytes: 100,
        );
        // Small delay to ensure different timestamps
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }

      // Total size = 500 bytes. Enforce max of 250.
      final evicted = await manager.enforceMaxSize(maxBytes: 250);
      expect(evicted, greaterThanOrEqualTo(3)); // need to evict 3 to get to 200

      final status = await manager.getCacheStatus();
      expect(status.totalSizeBytes, lessThanOrEqualTo(250));
    });

    test('CacheStatus.formattedSize', () {
      expect(
        const CacheStatus(totalSizeBytes: 500, tileCount: 1).formattedSize,
        '500 B',
      );
      expect(
        const CacheStatus(totalSizeBytes: 2048, tileCount: 1).formattedSize,
        '2.0 KB',
      );
      expect(
        const CacheStatus(totalSizeBytes: 5242880, tileCount: 1).formattedSize,
        '5.0 MB',
      );
      expect(
        const CacheStatus(totalSizeBytes: 3221225472, tileCount: 1).formattedSize,
        '3.00 GB',
      );
    });
  });
}
