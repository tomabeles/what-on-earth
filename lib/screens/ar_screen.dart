import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../globe/bridge.dart';
import '../globe/globe_view.dart';
import '../position/position_controller.dart';
import '../position/position_source.dart';
import '../sensors/device_orientation.dart' as sensor;
import '../sensors/sensor_fusion_provider.dart';
import '../shared/hud_command_panel.dart';
import '../shared/layer_control_panel.dart';
import '../shared/telemetry_hud.dart';

/// Full-screen AR view with CesiumJS globe, telemetry HUD, and UI chrome.
///
/// Position updates are only forwarded to CesiumJS after `GLOBE_READY` is
/// received, ensuring the WebView is fully initialised (TECH_SPEC §8.1).
///
/// Layers: camera → WebView → TelemetryHud → UI chrome (status bar, controls,
/// NAV FAB).
class ARScreen extends ConsumerStatefulWidget {
  const ARScreen({super.key});

  @override
  ConsumerState<ARScreen> createState() => _ARScreenState();
}

class _ARScreenState extends ConsumerState<ARScreen> {
  final _bridge = BridgeController();

  StreamSubscription<OrbitalPosition>? _positionSub;
  StreamSubscription<sensor.DeviceOrientation>? _orientationSub;
  OrbitalPosition? _lastPosition;
  sensor.DeviceOrientation? _lastOrientation;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _startPosition();
    _startOrientation();
    _listenLayerToggles();
    _bridge.fpsNotifier.addListener(_onFpsChanged);
  }

  void _onFpsChanged() {
    ref.read(fpsProvider.notifier).set(_bridge.fpsNotifier.value);
  }

  Future<void> _startPosition() async {
    await _bridge.globeReady;
    if (!mounted) return;

    final notifier = ref.read(positionControllerProvider.notifier);
    _positionSub = notifier.positionStream.listen((pos) {
      _bridge.send(OutboundMessage.updatePosition, pos.toJson());
      _lastPosition = pos;
      _updateHud();
    });
  }

  Future<void> _startOrientation() async {
    await _bridge.globeReady;
    if (!mounted) return;

    final engine = ref.read(sensorFusionEngineProvider);
    if (!engine.isRunning) {
      await engine.start();
    }
    _orientationSub = engine.orientationStream.listen((orientation) {
      _bridge.send(OutboundMessage.updateOrientation, orientation.toJson());
      _lastOrientation = orientation;
      _updateHud();
    });
  }

  void _updateHud() {
    final pos = _lastPosition;
    final ori = _lastOrientation;
    ref.read(hudDataProvider.notifier).update(HudData(
      latDeg: pos?.latDeg,
      lonDeg: pos?.lonDeg,
      altKm: pos?.altKm,
      headingDeg: ori?.headingDeg,
      pitchDeg: ori?.pitchDeg,
      rollDeg: ori?.rollDeg,
      velocityKmS: pos?.velocityKmS,
      bearingDeg: pos?.bearingDeg,
      sourceType: pos?.sourceType,
      ageSeconds: pos != null
          ? DateTime.now().difference(pos.timestamp).inSeconds
          : null,
    ));
  }

  /// Forward layer visibility changes to CesiumJS.
  void _listenLayerToggles() {
    ref.listenManual(layerVisibilityProvider, (prev, next) {
      for (final key in next.keys) {
        final was = prev?[key] ?? true;
        final now = next[key] ?? true;
        if (was == now) continue;

        if (key == 'stars') {
          _bridge.setSkybox(now);
        } else {
          _bridge.toggleLayer(key, now);
        }
      }
    });
  }

  @override
  void dispose() {
    _bridge.fpsNotifier.removeListener(_onFpsChanged);
    _positionSub?.cancel();
    _orientationSub?.cancel();
    WakelockPlus.disable();
    _bridge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Layer 1+2: Globe WebView (camera + CesiumJS)
          GlobeView(bridge: _bridge),
          // Layer 3: Telemetry HUD
          const Positioned.fill(child: TelemetryHud()),
          // Layer 4: UI Chrome
          // HUD command panel (CTRL>, SET> buttons + modal overlays)
          const Positioned.fill(child: HudCommandPanel()),
        ],
      ),
    );
  }
}
