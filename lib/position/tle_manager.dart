import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// Manages the on-disk ISS TLE cache.
///
/// Files are stored under `{documentsDir}/tle/`:
/// - `iss_latest.tle`           — raw 3-line TLE text from CelesTrak
/// - `iss_latest_timestamp.txt` — ISO 8601 UTC time of the last successful fetch
///
/// Inject [dio] and [documentsDir] for testability. Use [TleManager.create]
/// in production.
///
/// Reference: TECH_SPEC §4.2, §7.1
class TleManager {
  TleManager({required Dio dio, required Directory documentsDir})
      : _dio = dio,
        _documentsDir = documentsDir;

  final _tleUpdates = StreamController<String>.broadcast();

  /// Emits the raw TLE text each time [fetchAndStore] writes a new file
  /// successfully. [TLESource] listens to this to re-send SET_TLE to the
  /// WebView without polling.
  Stream<String> get tleUpdates => _tleUpdates.stream;

  /// Creates a production-ready instance with a 10-second request timeout.
  factory TleManager.create(Directory documentsDir) => TleManager(
        dio: Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        ),
        documentsDir: documentsDir,
      );

  static const _tleUrl =
      'https://celestrak.org/NORAD/elements/gp.php?CATNR=25544&FORMAT=TLE';

  final Dio _dio;
  final Directory _documentsDir;

  File get _tleFile =>
      File(p.join(_documentsDir.path, 'tle', 'iss_latest.tle'));

  File get _timestampFile =>
      File(p.join(_documentsDir.path, 'tle', 'iss_latest_timestamp.txt'));

  /// Downloads the current ISS TLE from CelesTrak and writes it to disk.
  ///
  /// On any failure the existing file is left untouched and the error is
  /// logged — the stored TLE is never replaced with corrupt/partial data.
  Future<void> fetchAndStore() async {
    try {
      final response = await _dio.get(
        _tleUrl,
        options: Options(responseType: ResponseType.plain),
      );
      final tleText = response.data as String;

      // Sanity-check: a TLE must have at least 2 lines (name + line 1 + line 2
      // or just line 1 + line 2 in 2-line format).
      final lines =
          tleText.trim().split('\n').where((l) => l.trim().isNotEmpty).toList();
      if (lines.length < 2) {
        throw const FormatException('TLE response has fewer than 2 lines');
      }

      await _tleFile.parent.create(recursive: true);
      await _tleFile.writeAsString(tleText);
      await _timestampFile
          .writeAsString(DateTime.now().toUtc().toIso8601String());
      if (!_tleUpdates.isClosed) _tleUpdates.add(tleText);
    } catch (e) {
      debugPrint('TleManager.fetchAndStore: error — $e (existing file kept)');
    }
  }

  /// Returns the stored TLE string, or null if no file exists yet.
  Future<String?> loadStored() async {
    try {
      if (!await _tleFile.exists()) return null;
      return await _tleFile.readAsString();
    } catch (_) {
      return null;
    }
  }

  /// Returns the UTC time of the last successful fetch, or null if unknown.
  Future<DateTime?> lastFetchTime() async {
    try {
      if (!await _timestampFile.exists()) return null;
      final text = await _timestampFile.readAsString();
      return DateTime.parse(text.trim());
    } catch (_) {
      return null;
    }
  }
}
