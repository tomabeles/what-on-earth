import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../globe/bridge.dart';
import '../globe/globe_view.dart';
import '../onboarding/onboarding_banner.dart';
import '../onboarding/onboarding_flow.dart';
import '../position/position_controller.dart';
import '../position/position_source.dart';
import '../sensors/device_orientation.dart' as sensor;
import '../sensors/horizon_detector.dart';
import '../sensors/lvlh_frame.dart';
import '../sensors/orientation_corrections.dart';
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
  StreamSubscription<HorizonCorrection>? _horizonSub;
  OrbitalPosition? _lastPosition;
  sensor.DeviceOrientation? _lastOrientation;

  CameraController? _cameraController;
  HorizonDetectorEngine? _horizonDetector;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _startPosition();
    _startOrientation();
    _startHorizonDetector();
    _listenLayerToggles();
    _bridge.fpsNotifier.addListener(_onFpsChanged);
    _bridge.reticleLabelNotifier.addListener(_onReticleLabelChanged);
  }

  void _onFpsChanged() {
    ref.read(fpsProvider.notifier).set(_bridge.fpsNotifier.value);
  }

  void _onReticleLabelChanged() {
    _updateHud();
  }

  Future<void> _startPosition() async {
    await _bridge.globeReady;
    if (!mounted) return;

    final engine = ref.read(sensorFusionEngineProvider);
    final notifier = ref.read(positionControllerProvider.notifier);
    _positionSub = notifier.positionStream.listen((pos) {
      _bridge.send(OutboundMessage.updatePosition, pos.toJson());
      _lastPosition = pos;

      // Compute LVLH frame and feed to sensor fusion engine
      final lvlh = computeLvlhFrame(pos);
      engine.updateLvlhFrame(lvlh);

      _updateHud();
    });
  }

  Future<void> _startHorizonDetector() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      // Prefer the back camera for horizon detection
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.low, // Low res is fine for edge detection
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();
      if (!mounted) {
        await _cameraController?.dispose();
        _cameraController = null;
        return;
      }

      _horizonDetector = HorizonDetectorEngine();
      final engine = ref.read(sensorFusionEngineProvider);

      _horizonSub = _horizonDetector!.correctionStream.listen((correction) {
        engine.updateHorizonCorrection(correction);
      });

      _horizonDetector!.start(_cameraController!);
    } catch (e) {
      debugPrint('Horizon detector init failed: $e');
    }
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
      reticleLabel: _bridge.reticleLabelNotifier.value,
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
    _bridge.reticleLabelNotifier.removeListener(_onReticleLabelChanged);
    _positionSub?.cancel();
    _orientationSub?.cancel();
    _horizonSub?.cancel();
    if (_cameraController != null && _horizonDetector != null) {
      _horizonDetector!.stop(_cameraController!);
    }
    _horizonDetector?.dispose();
    _cameraController?.dispose();
    WakelockPlus.disable();
    _bridge.dispose();
    super.dispose();
  }

  void _openOnboarding() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const OnboardingFlow()),
    );
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
          // Layer 5: Onboarding banner (auto-hides when complete)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: OnboardingBanner(onTap: _openOnboarding),
          ),
        ],
      ),
    );
  }
}
