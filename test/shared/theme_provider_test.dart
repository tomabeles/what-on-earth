import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:what_on_earth/shared/theme.dart';
import 'package:what_on_earth/shared/theme_provider.dart';

void main() {
  group('ThemeNotifier', () {
    test('default theme is night', () {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final theme = container.read(themeProvider);
      expect(theme.id, 'night');
    });

    test('setTheme updates state to dark', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(themeProvider.notifier).setTheme('dark');
      expect(container.read(themeProvider).id, 'dark');
    });

    test('setTheme updates state to starwars', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(themeProvider.notifier).setTheme('starwars');
      expect(container.read(themeProvider).id, 'starwars');
    });

    test('setTheme updates state to startrek', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(themeProvider.notifier).setTheme('startrek');
      expect(container.read(themeProvider).id, 'startrek');
    });

    test('setTheme with unknown id falls back to night', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(themeProvider.notifier).setTheme('nonexistent');
      expect(container.read(themeProvider).id, 'night');
    });

    test('setTheme persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(themeProvider.notifier).setTheme('dark');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('ui_theme_id'), 'dark');
    });

    test('loads persisted theme on build', () async {
      SharedPreferences.setMockInitialValues({'ui_theme_id': 'starwars'});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Initial synchronous state is night (default)
      expect(container.read(themeProvider).id, 'night');

      // Pump microtask queue so _loadSaved() completes
      await Future<void>.delayed(Duration.zero);
      expect(container.read(themeProvider).id, 'starwars');
    });

    test('loads persisted theme and returns correct tokens', () async {
      SharedPreferences.setMockInitialValues({'ui_theme_id': 'startrek'});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Force provider to initialize
      container.read(themeProvider);

      // Pump microtask queue so _loadSaved() completes
      await Future<void>.delayed(Duration.zero);

      final theme = container.read(themeProvider);
      expect(theme.id, 'startrek');
      expect(theme.tokens.hudPrimary, AppThemes.starTrek.tokens.hudPrimary);
    });

    test('ignores invalid persisted theme id', () async {
      SharedPreferences.setMockInitialValues({'ui_theme_id': 'bogus'});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Force provider to initialize
      container.read(themeProvider);

      // Pump microtask queue so _loadSaved() completes
      await Future<void>.delayed(Duration.zero);

      // AppThemeRegistry.find('bogus') returns night
      expect(container.read(themeProvider).id, 'night');
    });
  });
}
