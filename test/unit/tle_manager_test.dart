import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:what_on_earth/position/tle_manager.dart';

import 'tle_manager_test.mocks.dart';

const _fakeTle = '''ISS (ZARYA)
1 25544U 98067A   24001.00000000  .00000000  00000-0  00000-0 0  9999
2 25544  51.6400 000.0000 0000001   0.0000   0.0000 15.50000000000000''';

@GenerateMocks([Dio])
void main() {
  late MockDio mockDio;
  late Directory tempDir;
  late TleManager manager;

  setUp(() async {
    mockDio = MockDio();
    tempDir = await Directory.systemTemp.createTemp('tle_test_');
    manager = TleManager(dio: mockDio, documentsDir: tempDir);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  // ── Helpers ──────────────────────────────────────────────────────────────

  void whenGetSucceeds([String body = _fakeTle]) {
    when(mockDio.get(any, options: anyNamed('options'))).thenAnswer(
      (_) async => Response(
        data: body,
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ),
    );
  }

  void whenGetThrows() {
    when(mockDio.get(any, options: anyNamed('options'))).thenAnswer(
      (_) async => throw DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.connectionError,
      ),
    );
  }

  // ── fetchAndStore ─────────────────────────────────────────────────────────

  group('fetchAndStore', () {
    test('writes TLE and timestamp files on success', () async {
      whenGetSucceeds();

      await manager.fetchAndStore();

      final tleFile = File('${tempDir.path}/tle/iss_latest.tle');
      final tsFile = File('${tempDir.path}/tle/iss_latest_timestamp.txt');

      expect(await tleFile.exists(), isTrue);
      expect(await tleFile.readAsString(), _fakeTle);
      expect(await tsFile.exists(), isTrue);

      final ts = DateTime.parse(await tsFile.readAsString());
      expect(ts.isUtc, isTrue);
      expect(
        DateTime.now().toUtc().difference(ts).abs(),
        lessThan(const Duration(seconds: 5)),
      );
    });

    test('does not overwrite existing file on network failure', () async {
      // Prime the cache with valid data.
      whenGetSucceeds();
      await manager.fetchAndStore();
      final tleFile = File('${tempDir.path}/tle/iss_latest.tle');
      final original = await tleFile.readAsString();

      // Network fails on the next attempt.
      whenGetThrows();
      await manager.fetchAndStore();

      expect(await tleFile.readAsString(), original);
    });

    test('does not overwrite existing file when response is malformed', () async {
      whenGetSucceeds();
      await manager.fetchAndStore();
      final tleFile = File('${tempDir.path}/tle/iss_latest.tle');
      final original = await tleFile.readAsString();

      // Server returns a single line — not a valid TLE.
      whenGetSucceeds('NOT A VALID TLE');
      await manager.fetchAndStore();

      expect(await tleFile.readAsString(), original);
    });
  });

  // ── loadStored ────────────────────────────────────────────────────────────

  group('loadStored', () {
    test('returns null when no file exists', () async {
      expect(await manager.loadStored(), isNull);
    });

    test('returns TLE string after successful fetch', () async {
      whenGetSucceeds();
      await manager.fetchAndStore();

      expect(await manager.loadStored(), _fakeTle);
    });
  });

  // ── lastFetchTime ─────────────────────────────────────────────────────────

  group('lastFetchTime', () {
    test('returns null when no timestamp file exists', () async {
      expect(await manager.lastFetchTime(), isNull);
    });

    test('returns UTC DateTime after successful fetch', () async {
      whenGetSucceeds();
      await manager.fetchAndStore();

      final t = await manager.lastFetchTime();
      expect(t, isNotNull);
      expect(t!.isUtc, isTrue);
    });
  });
}
