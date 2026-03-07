import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../globe/bridge.dart';
import '../globe/globe_view.dart';
import '../position/position_controller.dart';
import '../position/position_source.dart';

/// Full-screen globe view driven by [PositionController].
///
/// Position updates are only forwarded to CesiumJS after `GLOBE_READY` is
/// received, ensuring the WebView is fully initialised (TECH_SPEC §8.1).
class ARScreen extends ConsumerStatefulWidget {
  const ARScreen({super.key});

  @override
  ConsumerState<ARScreen> createState() => _ARScreenState();
}

class _ARScreenState extends ConsumerState<ARScreen> {
  final _bridge = BridgeController();

  StreamSubscription<OrbitalPosition>? _positionSub;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _startPosition();
  }

  Future<void> _startPosition() async {
    // Wait for CesiumJS to be ready before sending any positions.
    await _bridge.globeReady;
    if (!mounted) return;

    final notifier = ref.read(positionControllerProvider.notifier);
    _positionSub = notifier.positionStream.listen((pos) {
      _bridge.send(OutboundMessage.updatePosition, pos.toJson());
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _bridge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GlobeView(bridge: _bridge),
    );
  }
}
