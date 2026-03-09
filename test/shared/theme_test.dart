import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:what_on_earth/shared/theme.dart';

void main() {
  group('AppTokens', () {
    test('lerp at t=0 returns start tokens', () {
      final start = AppTokens.fromHue(120);
      final end = AppTokens.fromHue(240);
      final result = start.lerp(end, 0.0);

      expect(result.surfacePrimary, start.surfacePrimary);
      expect(result.hudPrimary, start.hudPrimary);
      expect(result.hudFontSize, start.hudFontSize);
      expect(result.hudFontFamily, start.hudFontFamily);
    });

    test('lerp at t=1 returns end tokens', () {
      final start = AppTokens.fromHue(120);
      final end = AppTokens.fromHue(240);
      final result = start.lerp(end, 1.0);

      expect(result.surfacePrimary, end.surfacePrimary);
      expect(result.hudPrimary, end.hudPrimary);
      expect(result.hudFontSize, end.hudFontSize);
      expect(result.hudFontFamily, end.hudFontFamily);
    });

    test('lerp at t=0.5 interpolates colors', () {
      final start = AppTokens.fromHue(120);
      final end = AppTokens.fromHue(240);
      final result = start.lerp(end, 0.5);

      expect(result.hudPrimary,
          Color.lerp(start.hudPrimary, end.hudPrimary, 0.5));
    });

    test('lerp with null returns this', () {
      final tokens = AppTokens.fromHue(120);
      final result = tokens.lerp(null, 0.5);
      expect(result.hudPrimary, tokens.hudPrimary);
    });

    test('copyWith with no arguments returns identical tokens', () {
      final original = AppTokens.fromHue(120);
      final copy = original.copyWith();

      expect(copy.surfacePrimary, original.surfacePrimary);
      expect(copy.hudPrimary, original.hudPrimary);
      expect(copy.hudFontFamily, original.hudFontFamily);
      expect(copy.hudFontSize, original.hudFontSize);
      expect(copy.borderPrimary, original.borderPrimary);
    });

    test('copyWith overrides specified fields only', () {
      final original = AppTokens.fromHue(120);
      final modified = original.copyWith(
        hudPrimary: const Color(0xFFFF0000),
        hudFontSize: 14.0,
      );

      expect(modified.hudPrimary, const Color(0xFFFF0000));
      expect(modified.hudFontSize, 14.0);
      expect(modified.surfacePrimary, original.surfacePrimary);
      expect(modified.hudSecondary, original.hudSecondary);
      expect(modified.hudFontFamily, original.hudFontFamily);
    });
  });

  group('AppTokens.fromHue', () {
    test('generates green-ish primary for hue 120', () {
      final tokens = AppTokens.fromHue(120);
      expect(tokens.hudPrimary.g, greaterThan(tokens.hudPrimary.r));
    });

    test('generates blue-ish primary for hue 240', () {
      final tokens = AppTokens.fromHue(240);
      expect(tokens.hudPrimary.b, greaterThan(tokens.hudPrimary.r));
    });

    test('generates red-ish primary for hue 0', () {
      final tokens = AppTokens.fromHue(0);
      expect(tokens.hudPrimary.r, greaterThan(tokens.hudPrimary.b));
    });

    test('all tokens use JetBrainsMono', () {
      final tokens = AppTokens.fromHue(120);
      expect(tokens.hudFontFamily, 'JetBrainsMono');
    });

    test('all tokens use hudFontSize 11', () {
      final tokens = AppTokens.fromHue(120);
      expect(tokens.hudFontSize, 11.0);
    });

    test('warning and danger colors are fixed regardless of hue', () {
      final t1 = AppTokens.fromHue(0);
      final t2 = AppTokens.fromHue(180);
      expect(t1.hudWarning, t2.hudWarning);
      expect(t1.hudDanger, t2.hudDanger);
    });
  });

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
