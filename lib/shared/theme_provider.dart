import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme.dart';

const _prefKey = 'hud_hue';

/// Provides the active [AppTheme], generated from a persisted HUD hue.
final themeProvider = NotifierProvider<ThemeNotifier, AppTheme>(
  ThemeNotifier.new,
);

class ThemeNotifier extends Notifier<AppTheme> {
  double _hue = kDefaultHudHue;

  /// Current hue value (0–360).
  double get hue => _hue;

  @override
  AppTheme build() {
    _loadSaved();
    return _themeFromHue(kDefaultHudHue);
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted) return;
    final saved = prefs.getDouble(_prefKey);
    if (saved != null) {
      _hue = saved;
      state = _themeFromHue(saved);
    }
  }

  Future<void> setHue(double hue) async {
    _hue = hue;
    state = _themeFromHue(hue);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefKey, hue);
  }

  static AppTheme _themeFromHue(double hue) {
    return AppTheme(
      id: 'custom_${hue.round()}',
      displayName: 'Custom',
      tokens: AppTokens.fromHue(hue),
    );
  }
}
