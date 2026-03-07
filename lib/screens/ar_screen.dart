import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../globe/bridge.dart';
import '../globe/globe_view.dart';
import '../position/position_source.dart';
import '../position/static_position_source.dart';

/// Full-screen AR view: live camera feed beneath the transparent CesiumJS
/// globe, with a satellite marker driven by [StaticPositionSource].
///
/// On Simulator (no camera hardware) or when permission is denied the camera
/// layer degrades to a black fallback — the globe still renders above it.
class ARScreen extends StatefulWidget {
  const ARScreen({super.key});

  @override
  State<ARScreen> createState() => _ARScreenState();
}

class _ARScreenState extends State<ARScreen> {
  final _bridge = BridgeController();
  final _positionSource = StaticPositionSource();

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
    await _positionSource.start();
    _positionSub = _positionSource.positionStream.listen((pos) {
      _bridge.send(OutboundMessage.updatePosition, pos.toJson());
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _positionSource.stop();
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
