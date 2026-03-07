import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:what_on_earth/globe/bridge.dart';
import 'package:what_on_earth/position/position_source.dart';
import 'package:what_on_earth/position/tle_manager.dart';
import 'package:what_on_earth/position/tle_source.dart';

import 'tle_source_test.mocks.dart';

const _tleLine0 = 'ISS (ZARYA)';
const _tleLine1 =
    '1 25544U 98067A   24001.00000000  .00000000  00000-0  00000-0 0  9999';
const _tleLine2 =
    '2 25544  51.6400 000.0000 0000001   0.0000   0.0000 15.50000000000000';
const _fakeTle = '$_tleLine0\n$_tleLine1\n$_tleLine2';

@GenerateMocks([TleManager])
void main() {
  late MockTleManager mockManager;
  late BridgeController bridge;
  late StreamController<String> tleUpdatesController;

  // Captures every (type, payload) pair dispatched through bridge.send.
  final List<(OutboundMessage, Map<String, dynamic>)> sent = [];

  setUp(() {
    sent.clear();
    mockManager = MockTleManager();
    tleUpdatesController = StreamController<String>.broadcast();

    when(mockManager.tleUpdates).thenAnswer((_) => tleUpdatesController.stream);

    bridge = BridgeController();
    BridgeController.onSend = (type, payload) => sent.add((type, payload));
  });

  tearDown(() async {
    BridgeController.onSend = null;
    bridge.dispose();
    await tleUpdatesController.close();
  });

  group('TLESource', () {
    test('type is estimated', () {
      final source = TLESource(manager: mockManager, bridge: bridge);
      expect(source.type, PositionSourceType.estimated);
    });

    test('sends SET_TLE with correct lines on start', () async {
      when(mockManager.loadStored()).thenAnswer((_) async => _fakeTle);

      final source = TLESource(manager: mockManager, bridge: bridge);
      await source.start();

      expect(sent.length, 1);
      final (type, payload) = sent.first;
      expect(type, OutboundMessage.setTle);
      expect(payload['line1'], _tleLine1);
      expect(payload['line2'], _tleLine2);

      await source.stop();
    });

    test('does not send SET_TLE when no TLE is stored', () async {
      when(mockManager.loadStored()).thenAnswer((_) async => null);

      final source = TLESource(manager: mockManager, bridge: bridge);
      await source.start();

      expect(sent, isEmpty);

      await source.stop();
    });

    test('re-sends SET_TLE when tleUpdates emits a new TLE', () async {
      when(mockManager.loadStored()).thenAnswer((_) async => _fakeTle);

      const updatedTle =
          'ISS (ZARYA)\n1 25544U 98067A   24002.00000000  .00000000  00000-0  00000-0 0  9998\n2 25544  51.6400 010.0000 0000001   0.0000   0.0000 15.50000000000001';

      final source = TLESource(manager: mockManager, bridge: bridge);
      await source.start();
      expect(sent.length, 1);

      tleUpdatesController.add(updatedTle);
      // Let microtasks/events flush.
      await Future<void>.delayed(Duration.zero);

      expect(sent.length, 2);
      final (type, payload) = sent[1];
      expect(type, OutboundMessage.setTle);
      expect(payload['line1'], startsWith('1 25544'));
      expect(payload['line2'], startsWith('2 25544'));

      await source.stop();
    });

    test('stream stays silent after start with no TLE', () async {
      when(mockManager.loadStored()).thenAnswer((_) async => null);

      final source = TLESource(manager: mockManager, bridge: bridge);
      await source.start();

      final positions = <OrbitalPosition>[];
      final sub = source.positionStream.listen(positions.add);

      await Future<void>.delayed(Duration.zero);
      expect(positions, isEmpty);

      await sub.cancel();
      await source.stop();
    });

    test('stop cancels subscriptions and closes stream', () async {
      when(mockManager.loadStored()).thenAnswer((_) async => _fakeTle);

      final source = TLESource(manager: mockManager, bridge: bridge);
      await source.start();
      await source.stop();

      // After stop, tleUpdates emission should not trigger another send.
      final countBefore = sent.length;
      tleUpdatesController.add(_fakeTle);
      await Future<void>.delayed(Duration.zero);
      expect(sent.length, countBefore);
    });
  });
}
