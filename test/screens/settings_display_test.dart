import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:what_on_earth/screens/settings_screen.dart';
import 'package:what_on_earth/shared/nav_speed_dial.dart';
import 'package:what_on_earth/shared/theme.dart';

Widget _wrap() {
  return ProviderScope(
    child: MaterialApp(
      theme: buildThemeData(AppThemes.night),
      home: const SettingsScreen(),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsScreen Display section', () {
    testWidgets('shows DISPLAY section title', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('DISPLAY'), findsOneWidget);
    });

    testWidgets('shows HUD COLOR label and color picker', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('HUD COLOR'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('shows TELEMETRY HUD toggle', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('TELEMETRY HUD'), findsOneWidget);
    });

    testWidgets('HUD toggle can be tapped', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // Find the text and tap it
      await tester.tap(find.text('TELEMETRY HUD'));
      await tester.pumpAndSettle();
    });
  });

  group('SettingsScreen navigation', () {
    testWidgets('contains NavSpeedDial with settings active', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.byType(NavSpeedDial), findsOneWidget);

      final dial =
          tester.widget<NavSpeedDial>(find.byType(NavSpeedDial));
      expect(dial.activeDestination, NavDestination.settings);
    });
  });
}
