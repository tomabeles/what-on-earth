import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefKey = 'hud_visible';

/// Riverpod provider controlling Telemetry HUD visibility.
///
/// Default: `true` (ON). Persisted in SharedPreferences under `hud_visible`.
final hudVisibilityProvider =
    NotifierProvider<HudVisibilityNotifier, bool>(
  HudVisibilityNotifier.new,
);

class HudVisibilityNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadSaved();
    return true; // Default ON
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

  Future<void> setVisible(bool visible) async {
    state = visible;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, state);
  }
}
