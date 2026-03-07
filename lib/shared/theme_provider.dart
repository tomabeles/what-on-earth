import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme.dart';

const _prefKey = 'ui_theme_id';

/// Provides the active [AppTheme], persisted in SharedPreferences.
final themeProvider = NotifierProvider<ThemeNotifier, AppTheme>(
  ThemeNotifier.new,
);

class ThemeNotifier extends Notifier<AppTheme> {
  @override
  AppTheme build() {
    // Synchronously return the default; _loadSaved() will update once prefs are
    // ready. This avoids making the provider async (which would complicate
    // MaterialApp.theme, which needs a synchronous ThemeData).
    _loadSaved();
    return AppThemes.night;
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted) return;
    final id = prefs.getString(_prefKey);
    if (id != null) {
      state = AppThemeRegistry.find(id);
    }
  }

  Future<void> setTheme(String id) async {
    final theme = AppThemeRegistry.find(id);
    state = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, theme.id);
  }
}
