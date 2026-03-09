import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:what_on_earth/shared/theme.dart';
import 'package:what_on_earth/shared/theme_provider.dart';

void main() {
  group('ThemeNotifier (hue-based)', () {
    test('default hue is 120 (fighter-jet green)', () {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final theme = container.read(themeProvider);
      expect(theme.id, 'custom_120');
      expect(container.read(themeProvider.notifier).hue, 120.0);
    });

    test('setHue updates state', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(themeProvider.notifier).setHue(240.0);
      expect(container.read(themeProvider.notifier).hue, 240.0);
      expect(container.read(themeProvider).id, 'custom_240');
    });

    test('setHue persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(themeProvider.notifier).setHue(60.0);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('hud_hue'), 60.0);
    });

    test('loads persisted hue on build', () async {
      SharedPreferences.setMockInitialValues({'hud_hue': 300.0});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Initial synchronous state is default hue
      expect(container.read(themeProvider.notifier).hue, kDefaultHudHue);

      // Pump microtask queue so _loadSaved() completes
      await Future<void>.delayed(Duration.zero);
      expect(container.read(themeProvider.notifier).hue, 300.0);
    });

    test('generated tokens have correct hudPrimary for hue', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final tokens = container.read(themeProvider).tokens;
      // Default hue 120 should produce a green-ish hudPrimary
      expect(tokens.hudPrimary.g, greaterThan(tokens.hudPrimary.r));
    });
  });
}
