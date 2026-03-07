import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../globe/bridge.dart';
import '../globe/globe_view.dart';
import '../position/position_controller.dart';
import '../position/position_source.dart';

/// Full-screen AR view: live camera feed beneath the transparent CesiumJS
/// globe, with the camera driven by [PositionController].
///
/// Position updates are only forwarded to CesiumJS after `GLOBE_READY` is
/// received, ensuring the WebView is fully initialised (TECH_SPEC §8.1).
///
/// On Simulator (no camera hardware) or when permission is denied the camera
/// layer degrades to a black fallback — the globe still renders above it.
class ARScreen extends ConsumerStatefulWidget {
  const ARScreen({super.key});

  @override
  ConsumerState<ARScreen> createState() => _ARScreenState();
}

class _ARScreenState extends ConsumerState<ARScreen> {
  final _bridge = BridgeController();

  CameraController? _camera;
  StreamSubscription<OrbitalPosition>? _positionSub;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _startPosition();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      if (mounted) setState(() => _permissionDenied = true);
      return;
    }
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return; // Simulator — no camera hardware
      final controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() => _camera = controller);
    } catch (_) {
      // Simulator or initialisation failure — fall through to black background.
    }
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
    _camera?.dispose();
    _bridge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildCameraLayer(),
          GlobeView(bridge: _bridge),
        ],
      ),
    );
  }

  Widget _buildCameraLayer() {
    if (_camera != null && _camera!.value.isInitialized) {
      return CameraPreview(_camera!);
    }
    return ColoredBox(
      color: Colors.black,
      child: _permissionDenied
          ? const Center(
              child: Text(
                'Camera access required for AR view.\n'
                'Enable it in Settings → What On Earth.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            )
          : const SizedBox.expand(),
    );
  }
}
