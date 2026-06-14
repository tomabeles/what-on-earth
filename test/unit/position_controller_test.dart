import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:what_on_earth/position/enabled_sources_provider.dart';
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
    if (_stopped || _controller.isClosed) {
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

const _live = PositionSourceType.live;
const _estimated = PositionSourceType.estimated;
const _static = PositionSourceType.static;

OrbitalPosition _pos(PositionSourceType type) => OrbitalPosition(
      latDeg: 10,
      lonDeg: 20,
      altKm: 420,
      timestamp: DateTime.utc(2024),
      sourceType: type,
    );

/// Drains pending microtasks so fire-and-forget async chains settle.
Future<void> _drain() async {
  for (var i = 0; i < 6; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PositionController', () {
    late _FakeSource liveSource;
    late _FakeSource tleSource;
    late _FakeSource staticSource;
    late _FakeSource gpsSource;
    late ProviderContainer container;
    late DateTime now;

    PositionController notifier() =>
        container.read(positionControllerProvider.notifier);

    /// Advances the injected clock and runs one watchdog tick.
    Future<void> advance(Duration d) async {
      now = now.add(d);
      notifier().tick();
      await _drain();
    }

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      now = DateTime.utc(2024, 1, 1);
      positionNow = () => now;

      liveSource = _FakeSource(_live);
      tleSource = _FakeSource(_estimated);
      staticSource = _FakeSource(_static);
      gpsSource = _FakeSource(PositionSourceType.gps);

      container = ProviderContainer(
        overrides: [
          livePositionSourceProvider.overrideWithValue(liveSource),
          tlePositionSourceProvider.overrideWithValue(tleSource),
          staticPositionSourceProvider.overrideWithValue(staticSource),
          gpsPositionSourceProvider.overrideWithValue(gpsSource),
        ],
      );

      await container.read(positionControllerProvider.future);
      await _drain();
    });

    tearDown(() {
      container.dispose();
      positionNow = DateTime.now;
    });

    test('starts the highest-priority (live) source on init', () {
      expect(liveSource.startCalls, 1);
      expect(tleSource.startCalls, 0);
      expect(staticSource.startCalls, 0);
    });

    test('initial status has live source type', () {
      final status = container.read(positionControllerProvider).value;
      expect(status?.sourceType, _live);
    });

    test('forwards positions and updates status', () async {
      final received = <OrbitalPosition>[];
      final sub = notifier().positionStream.listen(received.add);

      liveSource.emit(_pos(_live));
      await _drain();

      expect(received.single.sourceType, _live);
      final status = container.read(positionControllerProvider).value;
      expect(status?.isLive, isTrue);
      await sub.cancel();
    });

    test(
        'cold start with no live data falls through to TLE then manual '
        '(regression: blank HUD)', () async {
      final received = <OrbitalPosition>[];
      final sub = notifier().positionStream.listen(received.add);

      // Live never emits. After its 8s stale window, demote to TLE.
      await advance(const Duration(seconds: 9));
      expect(tleSource.startCalls, 1);
      expect(liveSource.stopCalls, 1);

      // TLE also silent (no cached TLE). After its window, demote to manual.
      await advance(const Duration(seconds: 9));
      expect(staticSource.startCalls, 1);

      // Manual produces a fix → the unified stream finally has coordinates.
      staticSource.emit(_pos(_static));
      await _drain();
      expect(received.last.sourceType, _static);
      expect(received.last.latDeg, 10);
      await sub.cancel();
    });

    test('circuit breaker re-probes live and promotes back on recovery',
        () async {
      final received = <OrbitalPosition>[];
      final sub = notifier().positionStream.listen(received.add);

      // Live silent → demote to TLE; live breaker opens (cooldown 30s).
      await advance(const Duration(seconds: 9));
      expect(tleSource.startCalls, 1);
      final liveStartsAfterDemote = liveSource.startCalls;

      // Keep TLE healthy and step to just before the cooldown — no probe yet.
      now = DateTime.utc(2024, 1, 1).add(const Duration(seconds: 30));
      tleSource.emit(_pos(_estimated));
      await _drain();
      notifier().tick();
      await _drain();
      expect(liveSource.startCalls, liveStartsAfterDemote); // no probe

      // Past the cooldown: a recovery probe starts live again.
      now = DateTime.utc(2024, 1, 1).add(const Duration(seconds: 40));
      tleSource.emit(_pos(_estimated)); // keep TLE fresh so it isn't demoted
      await _drain();
      notifier().tick();
      await _drain();
      expect(liveSource.startCalls, liveStartsAfterDemote + 1); // probe started

      // The probe yields a live fix → promote back to live, stop TLE.
      liveSource.emit(_pos(_live));
      await _drain();
      expect(received.last.sourceType, _live);
      expect(tleSource.stopCalls, greaterThanOrEqualTo(1));
      await sub.cancel();
    });

    test('setSourceMode pins a source and overrides the chain', () async {
      await notifier().setSourceMode(_static);
      expect(staticSource.startCalls, 1);
      expect(liveSource.stopCalls, 1);

      // While pinned, live staleness does not demote.
      staticSource.emit(_pos(_static));
      await _drain();
      await advance(const Duration(seconds: 30));
      final status = container.read(positionControllerProvider).value;
      expect(status?.sourceType, _static);
    });

    test('setSourceMode(null) restores automatic fallback from the top',
        () async {
      await notifier().setSourceMode(_static);
      await notifier().setSourceMode(null);
      expect(liveSource.startCalls, 2); // re-activated live at the top
    });

    test('disabling the active source demotes to the next enabled source',
        () async {
      container.read(enabledSourcesProvider.notifier).toggle(_live);
      await _drain();

      expect(tleSource.startCalls, 1);
      expect(liveSource.stopCalls, 1);
    });
  });
}
