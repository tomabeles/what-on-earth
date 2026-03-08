import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:what_on_earth/screens/pin_list_screen.dart';
import 'package:what_on_earth/shared/nav_speed_dial.dart';
import 'package:what_on_earth/shared/theme.dart';

Widget _wrap() {
  return MaterialApp(
    theme: buildThemeData(AppThemes.night),
    home: const PinListScreen(),
  );
}

void main() {
  group('PinListScreen (WOE-066)', () {
    testWidgets('renders Pins title', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // "Pins" appears as both the centered title and NAV label
      expect(find.text('Pins'), findsAtLeastNWidgets(1));
    });

    testWidgets('contains NavSpeedDial', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.byType(NavSpeedDial), findsOneWidget);
    });

    testWidgets('NavSpeedDial has pins active destination', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      final dial =
          tester.widget<NavSpeedDial>(find.byType(NavSpeedDial));
      expect(dial.activeDestination, NavDestination.pins);
    });
  });
}
