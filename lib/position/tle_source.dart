import 'dart:async';

import 'package:flutter/foundation.dart';

import '../globe/bridge.dart';
import 'position_source.dart';
import 'tle_manager.dart';

/// Drives SGP4 position propagation by sending TLE data to the JS engine via
/// the bridge and re-emitting POSITION_UPDATE messages as [OrbitalPosition]s.
///
/// On [start]:
/// 1. Loads the stored TLE from [TleManager].
/// 2. If available, sends `SET_TLE` to CesiumJS via [BridgeController]; the JS
///    engine begins propagating and sends back `POSITION_UPDATE` messages.
/// 3. Subscribes to [BridgeController.propagatedPositions] and forwards each
///    position (already typed `estimated`) to [positionStream].
/// 4. Subscribes to [TleManager.tleUpdates] so that whenever a fresh TLE is
///    fetched by the refresh daemon, `SET_TLE` is re-sent automatically.
///
/// All emitted positions have [PositionSourceType.estimated].
///
/// Reference: TECH_SPEC §7.1
class TLESource implements PositionSource {
  TLESource({required TleManager manager, required BridgeController bridge})
      : _manager = manager,
        _bridge = bridge;

  final TleManager _manager;
  final BridgeController _bridge;
  final _controller = StreamController<OrbitalPosition>.broadcast();

  StreamSubscription<OrbitalPosition>? _positionSub;
  StreamSubscription<String>? _tleSub;

  @override
  PositionSourceType get type => PositionSourceType.estimated;

  @override
  Stream<OrbitalPosition> get positionStream => _controller.stream;

  @override
  Future<void> start() async {
    final tleText = await _manager.loadStored();
    if (tleText == null) {
      debugPrint('TLESource: no stored TLE — stream will remain silent');
      return;
    }
    await _sendTle(tleText);

    _positionSub = _bridge.propagatedPositions.listen((pos) {
      if (!_controller.isClosed) _controller.add(pos);
    });

    _tleSub = _manager.tleUpdates.listen(_sendTle);
  }

  @override
  Future<void> stop() async {
    await _positionSub?.cancel();
    await _tleSub?.cancel();
    _positionSub = null;
    _tleSub = null;
    await _controller.close();
  }

  /// Parses [tleText] into line1/line2 and sends `SET_TLE` via the bridge.
  Future<void> _sendTle(String tleText) async {
    final lines =
        tleText.trim().split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    final line1 = lines.firstWhere(
      (l) => l.startsWith('1 '),
      orElse: () => '',
    );
    final line2 = lines.firstWhere(
      (l) => l.startsWith('2 '),
      orElse: () => '',
    );
    if (line1.isEmpty || line2.isEmpty) {
      debugPrint('TLESource: could not parse TLE lines from stored text');
      return;
    }
    await _bridge.send(OutboundMessage.setTle, {'line1': line1, 'line2': line2});
  }
}
