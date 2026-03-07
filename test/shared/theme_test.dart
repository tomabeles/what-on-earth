import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:what_on_earth/shared/theme.dart';

void main() {
  group('AppThemeRegistry', () {
    test('contains exactly 4 themes', () {
      expect(AppThemeRegistry.themes.length, 4);
    });

    test('find returns matching theme by id', () {
      expect(AppThemeRegistry.find('night').id, 'night');
      expect(AppThemeRegistry.find('dark').id, 'dark');
      expect(AppThemeRegistry.find('starwars').id, 'starwars');
      expect(AppThemeRegistry.find('startrek').id, 'startrek');
    });

    test('find returns night theme for unknown id', () {
      final theme = AppThemeRegistry.find('nonexistent');
      expect(theme.id, 'night');
      expect(theme.displayName, 'Night');
    });

    test('all theme ids are unique', () {
      final ids = AppThemeRegistry.themes.map((t) => t.id).toSet();
      expect(ids.length, AppThemeRegistry.themes.length);
    });

    test('all theme display names are non-empty', () {
      for (final theme in AppThemeRegistry.themes) {
        expect(theme.displayName.isNotEmpty, isTrue,
            reason: '${theme.id} has empty displayName');
      }
    });
  });

  group('AppTokens', () {
    test('lerp at t=0 returns start tokens', () {
      final start = AppThemes.night.tokens;
      final end = AppThemes.dark.tokens;
      final result = start.lerp(end, 0.0);

      expect(result.surfacePrimary, start.surfacePrimary);
      expect(result.hudPrimary, start.hudPrimary);
      expect(result.hudFontSize, start.hudFontSize);
      expect(result.hudFontFamily, start.hudFontFamily);
    });

    test('lerp at t=1 returns end tokens', () {
      final start = AppThemes.night.tokens;
      final end = AppThemes.dark.tokens;
      final result = start.lerp(end, 1.0);

      expect(result.surfacePrimary, end.surfacePrimary);
      expect(result.hudPrimary, end.hudPrimary);
      expect(result.hudFontSize, end.hudFontSize);
      expect(result.hudFontFamily, end.hudFontFamily);
    });

    test('lerp at t=0.5 interpolates colors', () {
      final start = AppThemes.night.tokens;
      final end = AppThemes.dark.tokens;
      final result = start.lerp(end, 0.5);

      // Interpolated color should differ from both start and end
      // (unless they happen to be the same)
      expect(result.hudPrimary,
          Color.lerp(start.hudPrimary, end.hudPrimary, 0.5));
    });

    test('lerp with null returns this', () {
      final tokens = AppThemes.night.tokens;
      final result = tokens.lerp(null, 0.5);
      expect(result.hudPrimary, tokens.hudPrimary);
    });

    test('copyWith with no arguments returns identical tokens', () {
      final original = AppThemes.night.tokens;
      final copy = original.copyWith();

      expect(copy.surfacePrimary, original.surfacePrimary);
      expect(copy.hudPrimary, original.hudPrimary);
      expect(copy.hudFontFamily, original.hudFontFamily);
      expect(copy.hudFontSize, original.hudFontSize);
      expect(copy.borderPrimary, original.borderPrimary);
    });

    test('copyWith overrides specified fields only', () {
      final original = AppThemes.night.tokens;
      final modified = original.copyWith(
        hudPrimary: const Color(0xFFFF0000),
        hudFontSize: 14.0,
      );

      expect(modified.hudPrimary, const Color(0xFFFF0000));
      expect(modified.hudFontSize, 14.0);
      // Other fields unchanged
      expect(modified.surfacePrimary, original.surfacePrimary);
      expect(modified.hudSecondary, original.hudSecondary);
      expect(modified.hudFontFamily, original.hudFontFamily);
    });
  });

  group('Named themes', () {
    test('night theme has correct accent color', () {
      expect(AppThemes.night.tokens.hudPrimary, const Color(0xFF4DD9FF));
    });

    test('dark theme has white HUD', () {
      expect(AppThemes.dark.tokens.hudPrimary, const Color(0xFFFFFFFF));
    });

    test('starWars theme has gold HUD', () {
      expect(AppThemes.starWars.tokens.hudPrimary, const Color(0xFFFFD700));
    });

    test('starTrek theme has orange HUD', () {
      expect(AppThemes.starTrek.tokens.hudPrimary, const Color(0xFFFF9900));
    });

    test('all themes use JetBrainsMono', () {
      for (final theme in AppThemeRegistry.themes) {
        expect(theme.tokens.hudFontFamily, 'JetBrainsMono',
            reason: '${theme.id} does not use JetBrainsMono');
      }
    });

    test('all themes use hudFontSize 11', () {
      for (final theme in AppThemeRegistry.themes) {
        expect(theme.tokens.hudFontSize, 11.0,
            reason: '${theme.id} does not use hudFontSize 11');
      }
    });

    test('surfaceOverlay has 70% opacity (0xB3 alpha)', () {
      for (final theme in AppThemeRegistry.themes) {
        final alpha = theme.tokens.surfaceOverlay.a;
        // 0xB3 / 0xFF = 179/255 ≈ 0.702
        expect(alpha, closeTo(0.702, 0.01),
            reason: '${theme.id} surfaceOverlay alpha is not ~70%');
      }
    });
  });

  group('buildThemeData', () {
    test('produces ThemeData with AppTokens extension', () {
      final themeData = buildThemeData(AppThemes.night);

      expect(themeData.brightness, Brightness.dark);
      expect(themeData.extension<AppTokens>(), isNotNull);
      expect(themeData.extension<AppTokens>()!.hudPrimary,
          AppThemes.night.tokens.hudPrimary);
    });

    test('scaffoldBackgroundColor matches surfacePrimary', () {
      final themeData = buildThemeData(AppThemes.starWars);
      expect(themeData.scaffoldBackgroundColor,
          AppThemes.starWars.tokens.surfacePrimary);
    });
  });
}
