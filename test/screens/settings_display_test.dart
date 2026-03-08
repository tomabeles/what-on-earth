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

  group('SettingsScreen Display section (WOE-080)', () {
    testWidgets('shows Display section title', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('Display'), findsOneWidget);
    });

    testWidgets('shows all four theme names', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('Night'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('Star Wars'), findsOneWidget);
      expect(find.text('Star Trek'), findsOneWidget);
    });

    testWidgets('shows Telemetry HUD toggle', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('Telemetry HUD'), findsOneWidget);
      expect(find.byType(SwitchListTile), findsOneWidget);
    });

    testWidgets('HUD toggle can be tapped', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // Find the SwitchListTile and tap it
      final switchTile = find.byType(SwitchListTile);
      expect(switchTile, findsOneWidget);

      await tester.tap(switchTile);
      await tester.pumpAndSettle();

      // The toggle should have changed state (no crash)
      expect(find.byType(SwitchListTile), findsOneWidget);
    });
  });

  group('SettingsScreen navigation (WOE-066)', () {
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
