import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:what_on_earth/position/position_controller.dart';
import 'package:what_on_earth/position/position_source.dart';

// ── Fake PositionSource ────────────────────────────────────────────────────

class _FakeSource implements PositionSource {
  _FakeSource(this._type);

  final PositionSourceType _type;
  StreamController<OrbitalPosition> _controller =
      StreamController<OrbitalPosition>.broadcast();
  int startCalls = 0;
  int stopCalls = 0;
  bool _stopped = false;

  @override
  PositionSourceType get type => _type;

  @override
  Stream<OrbitalPosition> get positionStream => _controller.stream;

  @override
  Future<void> start() async {
    if (_stopped) {
      _controller = StreamController<OrbitalPosition>.broadcast();
      _stopped = false;
    }
    startCalls++;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    _stopped = true;
    await _controller.close();
  }

  void emit(OrbitalPosition pos) {
    if (!_controller.isClosed) _controller.add(pos);
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

OrbitalPosition _pos(PositionSourceType type) => OrbitalPosition(
      latDeg: 0,
      lonDeg: 0,
      altKm: 420,
      timestamp: DateTime.utc(2024),
      sourceType: type,
    );

const _live = PositionSourceType.live;
const _estimated = PositionSourceType.estimated;

/// Drains all pending microtasks and timer events so fire-and-forget async
/// chains (like the unawaited `_switchTo` inside `_onPosition`) settle.
Future<void> _drain() async {
  // Multiple rounds: each round drains microtasks scheduled by the previous.
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  group('PositionController', () {
    late _FakeSource liveSource;
    late _FakeSource tleSource;
    late ProviderContainer container;

    setUp(() async {
      liveSource = _FakeSource(_live);
      tleSource = _FakeSource(_estimated);

      container = ProviderContainer(
        overrides: [
          livePositionSourceProvider.overrideWithValue(liveSource),
          tlePositionSourceProvider.overrideWithValue(tleSource),
        ],
      );

      // Await build() completion (starts ISSLiveSource).
      await container.read(positionControllerProvider.future);
    });

    tearDown(() => container.dispose());

    test('starts ISSLiveSource on init', () {
      expect(liveSource.startCalls, 1);
      expect(tleSource.startCalls, 0);
    });

    test('initial status has live source type', () {
      final status = container.read(positionControllerProvider).value;
      expect(status?.sourceType, _live);
    });

    test('forwards positions to positionStream', () async {
      final notifier = container.read(positionControllerProvider.notifier);
      final received = <OrbitalPosition>[];
      final sub = notifier.positionStream.listen(received.add);

      liveSource.emit(_pos(_live));
      await _drain();

      expect(received.length, 1);
      expect(received.first.sourceType, _live);
      await sub.cancel();
    });

    test('does not fall back with fewer than 3 consecutive estimated',
        () async {
      liveSource.emit(_pos(_estimated));
      liveSource.emit(_pos(_estimated));
      await _drain();

      expect(tleSource.startCalls, 0);
    });

    test('falls back to TLESource after 3 consecutive estimated positions',
        () async {
      liveSource.emit(_pos(_estimated));
      liveSource.emit(_pos(_estimated));
      liveSource.emit(_pos(_estimated));
      await _drain();

      expect(tleSource.startCalls, 1);
      expect(liveSource.stopCalls, 1);
    });

    test('resets counter on a live position — no fallback', () async {
      liveSource.emit(_pos(_estimated));
      liveSource.emit(_pos(_estimated));
      liveSource.emit(_pos(_live)); // resets
      liveSource.emit(_pos(_estimated));
      liveSource.emit(_pos(_estimated));
      await _drain();

      expect(tleSource.startCalls, 0);
    });

    test('switches back to ISSLiveSource on live position during fallback',
        () async {
      // Trigger fallback.
      liveSource.emit(_pos(_estimated));
      liveSource.emit(_pos(_estimated));
      liveSource.emit(_pos(_estimated));
      await _drain();
      expect(tleSource.startCalls, 1);

      // TLE source emits a live-type position → switch back.
      tleSource.emit(_pos(_live));
      await _drain();

      expect(liveSource.startCalls, 2);
    });

    test('setSourceMode(estimated) switches to TLESource', () async {
      await container
          .read(positionControllerProvider.notifier)
          .setSourceMode(_estimated);

      expect(tleSource.startCalls, 1);
      expect(liveSource.stopCalls, 1);
    });

    test('setSourceMode(live) after TLE switches back to ISSLiveSource',
        () async {
      await container
          .read(positionControllerProvider.notifier)
          .setSourceMode(_estimated);
      await container
          .read(positionControllerProvider.notifier)
          .setSourceMode(_live);

      expect(liveSource.startCalls, 2);
    });

    test('status is updated on each position', () async {
      final ts = DateTime.utc(2024, 6, 1);
      liveSource.emit(OrbitalPosition(
        latDeg: 10,
        lonDeg: 20,
        altKm: 420,
        timestamp: ts,
        sourceType: _live,
      ));
      await _drain();

      final status = container.read(positionControllerProvider).value;
      expect(status?.isLive, isTrue);
      expect(status?.lastFixAt, ts);
    });

    test('setSourceMode(null) restores auto-switching', () async {
      await container
          .read(positionControllerProvider.notifier)
          .setSourceMode(_estimated);
      await container
          .read(positionControllerProvider.notifier)
          .setSourceMode(null);

      expect(liveSource.startCalls, 2);
    });
  });
}
