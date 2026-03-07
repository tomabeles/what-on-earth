import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:what_on_earth/position/position_source.dart';
import 'package:what_on_earth/position/static_position_source.dart';

void main() {
  group('StaticPositionSource', () {
    test('emits one event immediately on start()', () {
      fakeAsync((async) {
        final source = StaticPositionSource(
          interval: const Duration(seconds: 5),
        );
        final events = <OrbitalPosition>[];
        source.positionStream.listen(events.add);

        source.start();
        async.flushMicrotasks();

        expect(events, hasLength(1));

        source.stop();
        async.flushMicrotasks();
      });
    });

    test('all emitted events have sourceType static', () {
      fakeAsync((async) {
        final source = StaticPositionSource(
          interval: const Duration(seconds: 1),
        );
        final events = <OrbitalPosition>[];
        source.positionStream.listen(events.add);

        source.start();
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 3));

        expect(events, isNotEmpty);
        for (final e in events) {
          expect(e.sourceType, PositionSourceType.static);
        }

        source.stop();
        async.flushMicrotasks();
      });
    });

    test('sourceType is forced to static even when seed position has a different type', () {
      fakeAsync((async) {
        final seed = OrbitalPosition(
          latDeg: 0,
          lonDeg: 0,
          altKm: 400,
          timestamp: DateTime.utc(2026),
          sourceType: PositionSourceType.live, // intentionally wrong
        );
        final source = StaticPositionSource(position: seed);
        final events = <OrbitalPosition>[];
        source.positionStream.listen(events.add);

        source.start();
        async.flushMicrotasks();

        expect(events.first.sourceType, PositionSourceType.static);

        source.stop();
        async.flushMicrotasks();
      });
    });

    test('timer fires at configured interval', () {
      fakeAsync((async) {
        final source = StaticPositionSource(
          interval: const Duration(seconds: 5),
        );
        final events = <OrbitalPosition>[];
        source.positionStream.listen(events.add);

        source.start();
        async.flushMicrotasks();
        expect(events, hasLength(1)); // immediate emission

        async.elapse(const Duration(seconds: 5));
        expect(events, hasLength(2));

        async.elapse(const Duration(seconds: 5));
        expect(events, hasLength(3));

        source.stop();
        async.flushMicrotasks();
      });
    });

    test('stop() cancels the timer — no further events after stop', () {
      fakeAsync((async) {
        final source = StaticPositionSource(
          interval: const Duration(seconds: 5),
        );
        final events = <OrbitalPosition>[];
        source.positionStream.listen(events.add);

        source.start();
        async.flushMicrotasks();
        expect(events, hasLength(1));

        source.stop();
        async.flushMicrotasks();
        final countAfterStop = events.length;

        async.elapse(const Duration(seconds: 20));
        expect(events.length, countAfterStop);
      });
    });

    test('custom position fields are reflected in emissions', () {
      fakeAsync((async) {
        final seed = OrbitalPosition(
          latDeg: 35.6,
          lonDeg: 139.7,
          altKm: 408.0,
          timestamp: DateTime.utc(2026),
          sourceType: PositionSourceType.static,
        );
        final source = StaticPositionSource(position: seed);
        final events = <OrbitalPosition>[];
        source.positionStream.listen(events.add);

        source.start();
        async.flushMicrotasks();

        expect(events.first.latDeg, 35.6);
        expect(events.first.lonDeg, 139.7);
        expect(events.first.altKm, 408.0);

        source.stop();
        async.flushMicrotasks();
      });
    });

    test('custom interval is respected', () {
      fakeAsync((async) {
        final source = StaticPositionSource(
          interval: const Duration(seconds: 10),
        );
        final events = <OrbitalPosition>[];
        source.positionStream.listen(events.add);

        source.start();
        async.flushMicrotasks();
        expect(events, hasLength(1)); // immediate

        async.elapse(const Duration(seconds: 9));
        expect(events, hasLength(1)); // timer hasn't fired yet

        async.elapse(const Duration(seconds: 1));
        expect(events, hasLength(2)); // now it fires

        source.stop();
        async.flushMicrotasks();
      });
    });
  });
}
