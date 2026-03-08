import 'dart:io';

import 'package:flutter/foundation.dart';

import 'tile_database.dart';

/// Cache status snapshot for UI display.
class CacheStatus {
  final int totalSizeBytes;
  final int tileCount;

  const CacheStatus({
    required this.totalSizeBytes,
    required this.tileCount,
  });

  /// Human-readable cache size.
  String get formattedSize {
    if (totalSizeBytes < 1024) return '$totalSizeBytes B';
    if (totalSizeBytes < 1024 * 1024) {
      return '${(totalSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (totalSizeBytes < 1024 * 1024 * 1024) {
      return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(totalSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

/// Manages tile cache metadata and enforces a maximum cache size via
/// LRU eviction (TECH_SPEC §7.3, §9.4).
class TileCacheManager {
  final TileDatabase _db;
  final String _documentsPath;

  /// Default max cache size: 3 GB.
  static const int defaultMaxBytes = 3 * 1024 * 1024 * 1024;

  TileCacheManager({
    required TileDatabase db,
    required String documentsPath,
  })  : _db = db,
        _documentsPath = documentsPath;

  /// Record that a tile was downloaded.
  Future<void> recordDownload({
    required String layerId,
    required int z,
    required int x,
    required int y,
    required int fileSizeBytes,
  }) {
    final key = '$layerId/$z/$x/$y';
    return _db.recordDownload(
      tileKey: key,
      layerId: layerId,
      zoomLevel: z,
      tileX: x,
      tileY: y,
      fileSizeBytes: fileSizeBytes,
    );
  }

  /// Update last-accessed timestamp when a tile is served.
  Future<void> recordAccess(String tileKey) => _db.recordAccess(tileKey);

  /// Get current cache status.
  Future<CacheStatus> getCacheStatus() async {
    final size = await _db.totalSizeBytes();
    final count = await _db.tileCount();
    return CacheStatus(totalSizeBytes: size, tileCount: count);
  }

  /// Evict least-recently-used tiles until total size is under [maxBytes].
  Future<int> enforceMaxSize({int maxBytes = defaultMaxBytes}) async {
    var totalSize = await _db.totalSizeBytes();
    var evicted = 0;

    while (totalSize > maxBytes) {
      final lru = await _db.lruTiles(20);
      if (lru.isEmpty) break;

      for (final tile in lru) {
        if (totalSize <= maxBytes) break;

        // Delete the file from disk
        final filePath =
            '$_documentsPath/tiles/${tile.layerId}/${tile.zoomLevel}/${tile.tileX}/${tile.tileY}.png';
        try {
          final file = File(filePath);
          if (await file.exists()) await file.delete();
        } catch (e) {
          debugPrint('TileCacheManager: failed to delete $filePath: $e');
        }

        // Delete the metadata row
        await _db.deleteTile(tile.tileKey);
        totalSize -= tile.fileSizeBytes;
        evicted++;
      }
    }

    return evicted;
  }
}
