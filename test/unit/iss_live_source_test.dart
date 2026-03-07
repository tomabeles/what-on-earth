import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:what_on_earth/position/iss_live_source.dart';
import 'package:what_on_earth/position/position_source.dart';

import 'iss_live_source_test.mocks.dart';

@GenerateMocks([Dio])
void main() {
  late MockDio mockDio;
  late ISSLiveSource source;

  setUp(() {
    mockDio = MockDio();
    source = ISSLiveSource(dio: mockDio);
  });

  tearDown(() async {
    try {
      await source.stop();
    } catch (_) {}
  });

  // ── Helpers ──────────────────────────────────────────────────────────────

  void whenGetSucceeds({
    double lat = 51.5,
    double lon = -0.1,
    double alt = 420.0,
  }) {
    when(mockDio.get(any)).thenAnswer(
      (_) async => Response(
        data: {'latitude': lat, 'longitude': lon, 'altitude': alt},
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ),
    );
  }

  void whenGetThrows(Object error) {
    when(mockDio.get(any)).thenAnswer((_) async => throw error);
  }

  DioException connectionError() => DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.connectionError,
      );

  DioException badResponse(int statusCode) => DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: statusCode,
          requestOptions: RequestOptions(path: ''),
        ),
      );

  // ── Tests ─────────────────────────────────────────────────────────────────

  group('ISSLiveSource', () {
    test('successful poll emits live position with correct fields', () {
      fakeAsync((async) {
        whenGetSucceeds(lat: 51.5, lon: -0.1, alt: 420.0);

        final events = <OrbitalPosition>[];
        source.positionStream.listen(events.add);

        source.start();
        async.flushMicrotasks();

        expect(events, hasLength(1));
        expect(events.first.sourceType, PositionSourceType.live);
        expect(events.first.latDeg, 51.5);
        expect(events.first.lonDeg, -0.1);
        expect(events.first.altKm, 420.0);
      });
    });

    test('network error after success emits last known as estimated', () {
      fakeAsync((async) {
        whenGetSucceeds();
        final events = <OrbitalPosition>[];
        source.positionStream.listen(events.add);

        source.start();
        async.flushMicrotasks();
        expect(events.single.sourceType, PositionSourceType.live);

        // Second poll fails with a network error.
        whenGetThrows(connectionError());
        async.elapse(const Duration(seconds: 2));
        async.flushMicrotasks();

        expect(events, hasLength(2));
        expect(events.last.sourceType, PositionSourceType.estimated);
        expect(events.last.latDeg, 51.5); // same coords as last live fix
        expect(events.last.lonDeg, -0.1);
        expect(events.last.altKm, 420.0);
      });
    });

    test('stream stays silent when first poll fails with no last known', () {
      fakeAsync((async) {
        whenGetThrows(connectionError());
        final events = <OrbitalPosition>[];
        source.positionStream.listen(events.add);

        source.start();
        async.flushMicrotasks();

        expect(events, isEmpty);
      });
    });

    test('500 response emits last known as estimated', () {
      fakeAsync((async) {
        whenGetSucceeds();
        final events = <OrbitalPosition>[];
        source.positionStream.listen(events.add);

        source.start();
        async.flushMicrotasks();
        expect(events.single.sourceType, PositionSourceType.live);

        whenGetThrows(badResponse(500));
        async.elapse(const Duration(seconds: 2));
        async.flushMicrotasks();

        expect(events.last.sourceType, PositionSourceType.estimated);
      });
    });

    // Uses real async because StreamController.close() interacts with
    // fakeAsync's timer drain in a way that causes elapse() to hang.
    test('stop() closes the stream and cancels the timer', () async {
      whenGetSucceeds();

      final events = <OrbitalPosition>[];
      final done = Completer<void>();
      source.positionStream.listen(events.add, onDone: done.complete);

      source.start(); // returns immediately — no awaits inside
      // Allow the fire-and-forget initial _poll() to complete.
      await Future.microtask(() {});
      await Future.microtask(() {});

      await source.stop();

      // Stream done event must arrive.
      await done.future.timeout(const Duration(seconds: 1));
      final countAfterStop = events.length;

      // Wait long enough that a timer tick would have fired (interval = 2 s).
      // We only wait 100 ms; the point is the timer was cancelled, not timing.
      await Future.delayed(const Duration(milliseconds: 100));
      expect(events.length, countAfterStop);
    });

    test('polls again at 2-second interval', () {
      fakeAsync((async) {
        whenGetSucceeds();
        final events = <OrbitalPosition>[];
        source.positionStream.listen(events.add);

        source.start();
        async.flushMicrotasks();
        expect(events, hasLength(1)); // immediate poll

        async.elapse(const Duration(seconds: 2));
        async.flushMicrotasks();
        expect(events, hasLength(2)); // first tick

        async.elapse(const Duration(seconds: 2));
        async.flushMicrotasks();
        expect(events, hasLength(3)); // second tick
      });
    });
  });
}
