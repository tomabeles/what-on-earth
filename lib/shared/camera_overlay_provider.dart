import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefKey = 'camera_overlay_visible';

/// Riverpod provider controlling camera overlay visibility.
///
/// Default: `false` (OFF). Persisted in SharedPreferences.
final cameraOverlayProvider =
    NotifierProvider<CameraOverlayNotifier, bool>(
  CameraOverlayNotifier.new,
);

class CameraOverlayNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadSaved();
    return false; // Default OFF
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted) return;
    final saved = prefs.getBool(_prefKey);
    if (saved != null) state = saved;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, state);
  }
}
