import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../globe/bridge.dart';
import '../globe/globe_view.dart';
import '../position/position_controller.dart';
import '../position/position_source.dart';
import '../shared/controls_button.dart';
import '../shared/layer_control_panel.dart';
import '../shared/nav_speed_dial.dart';
import '../shared/status_bar.dart';
import '../shared/telemetry_hud.dart';
import 'map_screen.dart';
import 'pin_list_screen.dart';
import 'settings_screen.dart';

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

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _startPosition();
    _listenCameraToggle();
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
    });
  }

  /// WOE-077: Listen to camera toggle in layer visibility provider and
  /// control camera preview + skybox accordingly.
  void _listenCameraToggle() {
    ref.listenManual(layerVisibilityProvider, (prev, next) {
      final wasCameraOn = prev?['camera'] ?? true;
      final isCameraOn = next['camera'] ?? true;
      if (wasCameraOn == isCameraOn) return;

      if (!isCameraOn) {
        // Camera OFF: show skybox
        _bridge.setSkybox(true);
      } else {
        // Camera ON: hide skybox (transparent for AR compositing)
        _bridge.setSkybox(false);
      }
    });
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  @override
  void dispose() {
    _bridge.fpsNotifier.removeListener(_onFpsChanged);
    _positionSub?.cancel();
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
          // Status bar (top center)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 12,
            right: 12,
            child: Center(child: StatusBar(lastTileSync: null)),
          ),
          // Controls button (bottom left)
          Positioned(
            left: 16,
            bottom: 16,
            child: ControlsButton(),
          ),
          // NAV FAB (bottom right) — no active destination on AR view
          Positioned(
            right: 16,
            bottom: 16,
            child: NavSpeedDial(
              onMapTap: () => _navigateTo(const MapScreen()),
              onPinsTap: () => _navigateTo(const PinListScreen()),
              onSettingsTap: () => _navigateTo(const SettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
