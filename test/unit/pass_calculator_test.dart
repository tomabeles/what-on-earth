import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:what_on_earth/globe/bridge.dart';
import 'package:what_on_earth/pins/pass_calculator.dart';

/// Stands in for the WebView bridge: captures outgoing REQUEST_PASS_CALC
/// calls and lets tests inject PASS_CALC_RESULT responses.
class _FakeBridge extends BridgeController {
  final results = StreamController<PassCalcResponse>.broadcast(sync: true);
  final requests = <({String requestId, double lat, double lon})>[];

  @override
  Stream<PassCalcResponse> get passCalcResults => results.stream;

  @override
  Future<void> requestPassCalc(String requestId, double lat, double lon) async {
    requests.add((requestId: requestId, lat: lat, lon: lon));
  }
}

PassCalcResponse _passAt(String requestId, {int startMs = 1700000000000}) =>
    PassCalcResponse(
      requestId: requestId,
      passStartUtc: DateTime.fromMillisecondsSinceEpoch(startMs),
      maxElevationDeg: 45.0,
      passDurationSeconds: 300,
    );

void main() {
  group('PassCalculator', () {
    late _FakeBridge bridge;
    late PassCalculator calculator;

    setUp(() {
      bridge = _FakeBridge();
      calculator = PassCalculator(bridge);
    });

    tearDown(() async {
      await bridge.results.close();
    });

    test('forwards lat/lon and resolves with the matching result', () async {
      final future = calculator.calculateNextPass(51.5, -0.1);

      final request = bridge.requests.single;
      expect(request.lat, 51.5);
      expect(request.lon, -0.1);

      bridge.results.add(_passAt(request.requestId));

      final result = await future;
      expect(result, isNotNull);
      expect(result!.requestId, request.requestId);
      expect(result.hasPass, isTrue);
    });

    test('ignores results for unknown requestIds', () async {
      final future = calculator.calculateNextPass(0, 0);
      final requestId = bridge.requests.single.requestId;

      bridge.results.add(_passAt('some-other-request'));
      bridge.results.add(_passAt(requestId));

      final result = await future;
      expect(result!.requestId, requestId);
    });

    test('correlates concurrent requests answered out of order', () async {
      final futureA = calculator.calculateNextPass(10, 10);
      final futureB = calculator.calculateNextPass(20, 20);

      expect(bridge.requests, hasLength(2));
      final idA = bridge.requests[0].requestId;
      final idB = bridge.requests[1].requestId;
      expect(idA, isNot(idB));

      bridge.results.add(_passAt(idB, startMs: 2000));
      bridge.results.add(_passAt(idA, startMs: 1000));

      final a = await futureA;
      final b = await futureB;
      expect(a!.requestId, idA);
      expect(a.passStartUtc!.millisecondsSinceEpoch, 1000);
      expect(b!.requestId, idB);
      expect(b.passStartUtc!.millisecondsSinceEpoch, 2000);
    });

    test('returns null when no result arrives within 10 seconds', () {
      fakeAsync((async) {
        PassCalcResponse? result = _passAt('sentinel');
        var completed = false;
        calculator.calculateNextPass(0, 0).then((r) {
          result = r;
          completed = true;
        });

        async.elapse(const Duration(seconds: 9));
        expect(completed, isFalse);

        async.elapse(const Duration(seconds: 2));
        expect(completed, isTrue);
        expect(result, isNull);
      });
    });

    test('late result after timeout is dropped without throwing', () {
      fakeAsync((async) {
        var completed = false;
        calculator.calculateNextPass(0, 0).then((_) => completed = true);
        final requestId = bridge.requests.single.requestId;

        async.elapse(const Duration(seconds: 11));
        expect(completed, isTrue);

        // Timed out — the pending entry must be cleaned up, so a late
        // response is dropped instead of completing a removed completer.
        bridge.results.add(_passAt(requestId));
        async.flushMicrotasks();
      });
    });

    test('dispose errors out in-flight requests', () async {
      final future = calculator.calculateNextPass(0, 0);
      calculator.dispose();
      await expectLater(future, throwsStateError);
    });
  });

  group('PassCalcResponse', () {
    test('fromJson parses successful result', () {
      final json = {
        'requestId': 'abc-123',
        'passStartUtc': 1700000000000,
        'maxElevationDeg': 45.5,
        'passDurationSeconds': 300,
      };
      final r = PassCalcResponse.fromJson(json);
      expect(r.requestId, 'abc-123');
      expect(r.hasPass, isTrue);
      expect(r.passStartUtc, isNotNull);
      expect(r.maxElevationDeg, 45.5);
      expect(r.passDurationSeconds, 300);
      expect(r.error, isNull);
    });

    test('fromJson parses error result', () {
      final json = {
        'requestId': 'def-456',
        'error': 'no_pass_found',
      };
      final r = PassCalcResponse.fromJson(json);
      expect(r.requestId, 'def-456');
      expect(r.hasPass, isFalse);
      expect(r.error, 'no_pass_found');
    });
  });

  group('MapTapEvent', () {
    test('stores lat/lon', () {
      const e = MapTapEvent(lat: 51.5, lon: -0.1);
      expect(e.lat, 51.5);
      expect(e.lon, -0.1);
    });
  });
}
