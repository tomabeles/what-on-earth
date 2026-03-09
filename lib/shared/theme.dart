import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Default HUD hue — classic fighter-jet phosphor green.
const double kDefaultHudHue = 120.0;

// ---------------------------------------------------------------------------
// AppTokens — ThemeExtension carrying all design tokens (UI_SPEC §2)
// ---------------------------------------------------------------------------

@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  // --- Surfaces (non-AR screens) ---
  final Color surfacePrimary;
  final Color surfaceSecondary;
  final Color surfaceOverlay;

  // --- HUD (AR overlay layer) ---
  final Color hudPrimary;
  final Color hudSecondary;
  final Color hudWarning;
  final Color hudDanger;
  final Color hudBackground;

  // --- Interactive elements ---
  final Color fabBackground;
  final Color fabIcon;

  // --- Status indicators ---
  final Color statusLive;
  final Color statusEstimated;
  final Color statusOffline;

  // --- Typography ---
  final String hudFontFamily;
  final double hudFontSize;

  // --- Borders / dividers ---
  final Color borderPrimary;

  const AppTokens({
    required this.surfacePrimary,
    required this.surfaceSecondary,
    required this.surfaceOverlay,
    required this.hudPrimary,
    required this.hudSecondary,
    required this.hudWarning,
    required this.hudDanger,
    required this.hudBackground,
    required this.fabBackground,
    required this.fabIcon,
    required this.statusLive,
    required this.statusEstimated,
    required this.statusOffline,
    required this.hudFontFamily,
    required this.hudFontSize,
    required this.borderPrimary,
  });

  @override
  AppTokens copyWith({
    Color? surfacePrimary,
    Color? surfaceSecondary,
    Color? surfaceOverlay,
    Color? hudPrimary,
    Color? hudSecondary,
    Color? hudWarning,
    Color? hudDanger,
    Color? hudBackground,
    Color? fabBackground,
    Color? fabIcon,
    Color? statusLive,
    Color? statusEstimated,
    Color? statusOffline,
    String? hudFontFamily,
    double? hudFontSize,
    Color? borderPrimary,
  }) {
    return AppTokens(
      surfacePrimary: surfacePrimary ?? this.surfacePrimary,
      surfaceSecondary: surfaceSecondary ?? this.surfaceSecondary,
      surfaceOverlay: surfaceOverlay ?? this.surfaceOverlay,
      hudPrimary: hudPrimary ?? this.hudPrimary,
      hudSecondary: hudSecondary ?? this.hudSecondary,
      hudWarning: hudWarning ?? this.hudWarning,
      hudDanger: hudDanger ?? this.hudDanger,
      hudBackground: hudBackground ?? this.hudBackground,
      fabBackground: fabBackground ?? this.fabBackground,
      fabIcon: fabIcon ?? this.fabIcon,
      statusLive: statusLive ?? this.statusLive,
      statusEstimated: statusEstimated ?? this.statusEstimated,
      statusOffline: statusOffline ?? this.statusOffline,
      hudFontFamily: hudFontFamily ?? this.hudFontFamily,
      hudFontSize: hudFontSize ?? this.hudFontSize,
      borderPrimary: borderPrimary ?? this.borderPrimary,
    );
  }

  /// Generates a full token set from a single HUD hue (0–360).
  factory AppTokens.fromHue(double hue) {
    final primary = HSVColor.fromAHSV(1.0, hue % 360, 0.9, 1.0).toColor();
    final secondary = HSVColor.fromAHSV(1.0, hue % 360, 0.35, 0.65).toColor();
    final surface = HSVColor.fromAHSV(1.0, hue % 360, 0.4, 0.06).toColor();
    final surfaceSec =
        HSVColor.fromAHSV(1.0, hue % 360, 0.25, 0.10).toColor();
    final border = HSVColor.fromAHSV(1.0, hue % 360, 0.35, 0.18).toColor();

    return AppTokens(
      surfacePrimary: surface,
      surfaceSecondary: surfaceSec,
      surfaceOverlay: surface.withValues(alpha: 0.7),
      hudPrimary: primary,
      hudSecondary: secondary,
      hudWarning: const Color(0xFFFFB340),
      hudDanger: const Color(0xFFFF3B30),
      hudBackground: const Color(0x99000000),
      fabBackground: primary,
      fabIcon: surface,
      statusLive: const Color(0xFF34C759),
      statusEstimated: const Color(0xFFFFB340),
      statusOffline: const Color(0xFF8E8E93),
      hudFontFamily: 'JetBrainsMono',
      hudFontSize: 11.0,
      borderPrimary: border,
    );
  }

  @override
  AppTokens lerp(AppTokens? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      surfacePrimary: Color.lerp(surfacePrimary, other.surfacePrimary, t)!,
      surfaceSecondary:
          Color.lerp(surfaceSecondary, other.surfaceSecondary, t)!,
      surfaceOverlay: Color.lerp(surfaceOverlay, other.surfaceOverlay, t)!,
      hudPrimary: Color.lerp(hudPrimary, other.hudPrimary, t)!,
      hudSecondary: Color.lerp(hudSecondary, other.hudSecondary, t)!,
      hudWarning: Color.lerp(hudWarning, other.hudWarning, t)!,
      hudDanger: Color.lerp(hudDanger, other.hudDanger, t)!,
      hudBackground: Color.lerp(hudBackground, other.hudBackground, t)!,
      fabBackground: Color.lerp(fabBackground, other.fabBackground, t)!,
      fabIcon: Color.lerp(fabIcon, other.fabIcon, t)!,
      statusLive: Color.lerp(statusLive, other.statusLive, t)!,
      statusEstimated: Color.lerp(statusEstimated, other.statusEstimated, t)!,
      statusOffline: Color.lerp(statusOffline, other.statusOffline, t)!,
      hudFontFamily: t < 0.5 ? hudFontFamily : other.hudFontFamily,
      hudFontSize: lerpDouble(hudFontSize, other.hudFontSize, t)!,
      borderPrimary: Color.lerp(borderPrimary, other.borderPrimary, t)!,
    );
  }
}

// ---------------------------------------------------------------------------
// AppTheme — named theme wrapper
// ---------------------------------------------------------------------------

@immutable
class AppTheme {
  final String id;
  final String displayName;
  final AppTokens tokens;

  const AppTheme({
    required this.id,
    required this.displayName,
    required this.tokens,
  });
}

// ---------------------------------------------------------------------------
// AppThemes — the four named themes (UI_SPEC §2.3)
// ---------------------------------------------------------------------------

class AppThemes {
  AppThemes._();

  static const night = AppTheme(
    id: 'night',
    displayName: 'Night',
    tokens: AppTokens(
      surfacePrimary: Color(0xFF0A0E1A),
      surfaceSecondary: Color(0xFF141927),
      surfaceOverlay: Color(0xB30A0E1A), // 70% opacity
      hudPrimary: Color(0xFF4DD9FF),
      hudSecondary: Color(0xFF8BB8C8),
      hudWarning: Color(0xFFFFB340),
      hudDanger: Color(0xFFFF3B30),
      hudBackground: Color(0x99000000), // 60% opacity
      fabBackground: Color(0xFF4DD9FF),
      fabIcon: Color(0xFF0A0E1A),
      statusLive: Color(0xFF34C759),
      statusEstimated: Color(0xFFFFB340),
      statusOffline: Color(0xFF8E8E93),
      hudFontFamily: 'JetBrainsMono',
      hudFontSize: 11.0,
      borderPrimary: Color(0xFF1E2A3A),
    ),
  );

  static const dark = AppTheme(
    id: 'dark',
    displayName: 'Dark',
    tokens: AppTokens(
      surfacePrimary: Color(0xFF000000),
      surfaceSecondary: Color(0xFF111111),
      surfaceOverlay: Color(0xB3000000),
      hudPrimary: Color(0xFFFFFFFF),
      hudSecondary: Color(0xFFAAAAAA),
      hudWarning: Color(0xFFFFB340),
      hudDanger: Color(0xFFFF3B30),
      hudBackground: Color(0x99000000),
      fabBackground: Color(0xFFFFFFFF),
      fabIcon: Color(0xFF000000),
      statusLive: Color(0xFF34C759),
      statusEstimated: Color(0xFFFFB340),
      statusOffline: Color(0xFF8E8E93),
      hudFontFamily: 'JetBrainsMono',
      hudFontSize: 11.0,
      borderPrimary: Color(0xFF222222),
    ),
  );

  static const starWars = AppTheme(
    id: 'starwars',
    displayName: 'Star Wars',
    tokens: AppTokens(
      surfacePrimary: Color(0xFF0A0A0A),
      surfaceSecondary: Color(0xFF141414),
      surfaceOverlay: Color(0xB30A0A0A),
      hudPrimary: Color(0xFFFFD700),
      hudSecondary: Color(0xFFC8A800),
      hudWarning: Color(0xFFFF8C00),
      hudDanger: Color(0xFFFF0000),
      hudBackground: Color(0x99000000),
      fabBackground: Color(0xFFFFD700),
      fabIcon: Color(0xFF0A0A0A),
      statusLive: Color(0xFF34C759),
      statusEstimated: Color(0xFFFFD700),
      statusOffline: Color(0xFF8E8E93),
      hudFontFamily: 'JetBrainsMono',
      hudFontSize: 11.0,
      borderPrimary: Color(0xFF2A2200),
    ),
  );

  static const starTrek = AppTheme(
    id: 'startrek',
    displayName: 'Star Trek',
    tokens: AppTokens(
      surfacePrimary: Color(0xFF1A0A00),
      surfaceSecondary: Color(0xFF260E00),
      surfaceOverlay: Color(0xB31A0A00),
      hudPrimary: Color(0xFFFF9900),
      hudSecondary: Color(0xFFCC6600),
      hudWarning: Color(0xFFFFCC00),
      hudDanger: Color(0xFFFF3B30),
      hudBackground: Color(0x99000000),
      fabBackground: Color(0xFFFF9900),
      fabIcon: Color(0xFF1A0A00),
      statusLive: Color(0xFF34C759),
      statusEstimated: Color(0xFFFFCC00),
      statusOffline: Color(0xFF8E8E93),
      hudFontFamily: 'JetBrainsMono',
      hudFontSize: 11.0,
      borderPrimary: Color(0xFF331500),
    ),
  );
}

// ---------------------------------------------------------------------------
// AppThemeRegistry — discovers all registered themes
// ---------------------------------------------------------------------------

class AppThemeRegistry {
  AppThemeRegistry._();

  static const List<AppTheme> themes = [
    AppThemes.night,
    AppThemes.dark,
    AppThemes.starWars,
    AppThemes.starTrek,
  ];

  /// Returns the theme with the given [id], or [AppThemes.night] if not found.
  static AppTheme find(String id) =>
      themes.firstWhere((t) => t.id == id, orElse: () => AppThemes.night);
}

// ---------------------------------------------------------------------------
// Helper — build a ThemeData from an AppTheme
// ---------------------------------------------------------------------------

ThemeData buildThemeData(AppTheme appTheme) {
  final tokens = appTheme.tokens;
  return ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: tokens.surfacePrimary,
    colorScheme: ColorScheme.dark(
      surface: tokens.surfacePrimary,
      primary: tokens.hudPrimary,
      secondary: tokens.hudSecondary,
      error: tokens.hudDanger,
    ),
    extensions: <ThemeExtension<dynamic>>[tokens],
  );
}
