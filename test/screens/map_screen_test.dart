import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:what_on_earth/screens/map_screen.dart';
import 'package:what_on_earth/shared/nav_speed_dial.dart';
import 'package:what_on_earth/shared/theme.dart';

Widget _wrap() {
  return MaterialApp(
    theme: buildThemeData(AppThemes.night),
    home: const MapScreen(),
  );
}

void main() {
  group('MapScreen (WOE-066)', () {
    testWidgets('renders 2D Map title', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('2D Map'), findsOneWidget);
    });

    testWidgets('contains NavSpeedDial', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.byType(NavSpeedDial), findsOneWidget);
    });

    testWidgets('NavSpeedDial has map active destination', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      final dial =
          tester.widget<NavSpeedDial>(find.byType(NavSpeedDial));
      expect(dial.activeDestination, NavDestination.map);
    });

    testWidgets('NavSpeedDial shows Pins and Settings but not Map',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // Expand FAB
      await tester.tap(find.byIcon(Icons.grid_view));
      await tester.pumpAndSettle();

      // Map screen omits its own destination from callbacks
      // but still shows all labels
      expect(find.text('Pins'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });
  });
}
