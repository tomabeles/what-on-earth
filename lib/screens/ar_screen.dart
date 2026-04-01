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
import '../sensors/sensor_fusion.dart' show OrientationMode;
import '../sensors/sensor_fusion_provider.dart';
import '../shared/camera_overlay_provider.dart';
import '../shared/horizon_debug_overlay.dart';
import '../shared/orientation_lock_provider.dart';
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
  ProviderSubscription<OrientationLock>? _orientationLockSub;

  // Touch steering state
  bool _isTouchSteering = false;
  bool _isReturning = false; // smooth return animation in progress
  double _touchHeadingDeg = 0;
  double _touchPitchDeg = 0;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _startPosition();
    _startOrientation();
    _startHorizonDetector();
    _listenLayerToggles();
    _listenOrientationLock();
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

      // Trigger rebuild so the camera preview appears in the stack
      if (mounted) setState(() {});
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
      _lastOrientation = orientation;
      if (_isTouchSteering) return;

      if (_isReturning) {
        // Ease back: move 15% of remaining distance each tick (~50Hz)
        const decay = 0.85;
        final targetH = orientation.headingDeg;
        final targetP = orientation.pitchDeg;

        // Shortest-path heading delta (handles 0/360 wrap)
        var dh = targetH - _touchHeadingDeg;
        if (dh > 180) dh -= 360;
        if (dh < -180) dh += 360;
        final dp = targetP - _touchPitchDeg;

        _touchHeadingDeg += dh * (1 - decay);
        _touchHeadingDeg = (_touchHeadingDeg % 360 + 360) % 360;
        _touchPitchDeg += dp * (1 - decay);

        // Close enough — finish returning
        if (dh.abs() < 0.5 && dp.abs() < 0.5) {
          _isReturning = false;
        }

        final blended = sensor.DeviceOrientation(
          headingDeg: _touchHeadingDeg,
          pitchDeg: _touchPitchDeg,
          rollDeg: orientation.rollDeg,
          reliable: orientation.reliable,
          timestamp: orientation.timestamp,
        );
        _bridge.send(OutboundMessage.updateOrientation, blended.toJson());
        _updateHud();
      } else {
        _bridge.send(OutboundMessage.updateOrientation, orientation.toJson());
        _updateHud();
      }
    });
  }

  void _updateHud() {
    final pos = _lastPosition;
    final ori = _lastOrientation;

    final overriding = _isTouchSteering || _isReturning;
    final headingDeg = overriding ? _touchHeadingDeg : ori?.headingDeg;
    final pitchDeg = overriding ? _touchPitchDeg : ori?.pitchDeg;

    ref.read(hudDataProvider.notifier).update(HudData(
      latDeg: pos?.latDeg,
      lonDeg: pos?.lonDeg,
      altKm: pos?.altKm,
      headingDeg: headingDeg,
      pitchDeg: pitchDeg,
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

  // ── Touch steering ──────────────────────────────────────────────────────

  void _onPanStart(DragStartDetails details) {
    final ori = _lastOrientation;
    if (ori == null) return;
    _isTouchSteering = true;
    if (_isReturning) {
      // Interrupt return — continue from current animated position
      _isReturning = false;
    } else {
      _touchHeadingDeg = ori.headingDeg;
      _touchPitchDeg = ori.pitchDeg;
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isTouchSteering) return;

    const sensitivity = 0.3; // degrees per pixel
    _touchHeadingDeg -= details.delta.dx * sensitivity;
    _touchHeadingDeg = (_touchHeadingDeg % 360 + 360) % 360;
    _touchPitchDeg =
        (_touchPitchDeg - details.delta.dy * sensitivity).clamp(0.0, 180.0);

    final override = sensor.DeviceOrientation(
      headingDeg: _touchHeadingDeg,
      pitchDeg: _touchPitchDeg,
      rollDeg: _lastOrientation?.rollDeg ?? 0,
      reliable: true,
      timestamp: DateTime.now(),
    );
    _bridge.send(OutboundMessage.updateOrientation, override.toJson());
    _updateHud();
  }

  void _onPanEnd(DragEndDetails details) {
    _isTouchSteering = false;
    _isReturning = true; // smooth ease-back driven by orientation stream
  }

  void _onPanCancel() {
    _isTouchSteering = false;
    _isReturning = true;
  }

  /// Forward orientation lock changes to the sensor fusion engine.
  void _listenOrientationLock() {
    final engine = ref.read(sensorFusionEngineProvider);
    // Set initial mode
    final lock = ref.read(orientationLockProvider);
    engine.setOrientationMode(lock == OrientationLock.portrait
        ? OrientationMode.portrait
        : OrientationMode.landscape);
    // Listen for changes
    _orientationLockSub =
        ref.listenManual(orientationLockProvider, (_, next) {
      engine.setOrientationMode(next == OrientationLock.portrait
          ? OrientationMode.portrait
          : OrientationMode.landscape);
    });
  }

  /// Forward layer visibility changes to CesiumJS.
  void _listenLayerToggles() {
    ref.listenManual(layerVisibilityProvider, (prev, next) {
      // On first callback (prev == null) or SharedPreferences load, sync all
      // layers so CesiumJS matches Flutter state regardless of JS defaults.
      final syncAll = prev == null;
      for (final key in next.keys) {
        final was = prev?[key] ?? true;
        final now = next[key] ?? true;
        if (!syncAll && was == now) continue;

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
    _orientationLockSub?.close();
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
    final showCameraOverlay = ref.watch(cameraOverlayProvider);
    // Watch orientation lock so changes from SET menu apply immediately.
    // The provider's _apply() handles SystemChrome.setPreferredOrientations.
    ref.watch(orientationLockProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Layer 1: Globe WebView (CesiumJS)
          GlobeView(bridge: _bridge),
          // Layer 2: Camera preview at 25% opacity (toggled via SET menu)
          if (showCameraOverlay &&
              _cameraController != null &&
              _cameraController!.value.isInitialized)
            Positioned.fill(
              child: Opacity(
                opacity: 0.25,
                child: CameraPreview(_cameraController!),
              ),
            ),
          // Layer 3: Horizon detection debug overlay (shown with camera)
          if (showCameraOverlay && _horizonDetector != null)
            Positioned.fill(
              child: HorizonDebugOverlay(
                debugNotifier: _horizonDetector!.debugNotifier,
              ),
            ),
          // Layer 4: Touch steering gesture detector.
          // Must be opaque to absorb touches from the WebView platform view
          // below. Command panel buttons sit above this and still receive taps.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              onPanCancel: _onPanCancel,
              child: const SizedBox.expand(),
            ),
          ),
          // Layer 5: Telemetry HUD (paints only, no hit testing)
          const Positioned.fill(
            child: IgnorePointer(child: TelemetryHud()),
          ),
          // Layer 6: UI Chrome (buttons sit on top of everything)
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
