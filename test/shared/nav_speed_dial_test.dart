import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:what_on_earth/shared/nav_speed_dial.dart';
import 'package:what_on_earth/shared/theme.dart';

Widget _wrap({
  NavDestination? activeDestination,
  VoidCallback? onMapTap,
  VoidCallback? onPinsTap,
  VoidCallback? onSettingsTap,
}) {
  return MaterialApp(
    theme: buildThemeData(AppThemes.night),
    home: Scaffold(
      body: Stack(
        children: [
          Positioned(
            right: 16,
            bottom: 16,
            child: NavSpeedDial(
              activeDestination: activeDestination,
              onMapTap: onMapTap,
              onPinsTap: onPinsTap,
              onSettingsTap: onSettingsTap,
            ),
          ),
        ],
      ),
    ),
  );
}

void main() {
  group('NavSpeedDial (WOE-065)', () {
    testWidgets('shows grid icon when closed', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.grid_view), findsOneWidget);
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('expands on tap, shows 3 secondary FABs', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // Tap the primary FAB (find by grid_view icon)
      await tester.tap(find.byIcon(Icons.grid_view));
      await tester.pumpAndSettle();

      // Should show close icon
      expect(find.byIcon(Icons.close), findsOneWidget);

      // Should show 3 secondary FABs with labels
      expect(find.text('Map'), findsOneWidget);
      expect(find.text('Pins'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Should have 4 total FABs (1 primary + 3 secondary)
      expect(find.byType(FloatingActionButton), findsNWidgets(4));
    });

    testWidgets('collapses when primary FAB tapped again', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // Expand
      await tester.tap(find.byIcon(Icons.grid_view));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.close), findsOneWidget);

      // Tap primary FAB again to close
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Should show grid icon (closed state)
      expect(find.byIcon(Icons.grid_view), findsOneWidget);
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('fires onMapTap callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(onMapTap: () => tapped = true));
      await tester.pumpAndSettle();

      // Expand
      await tester.tap(find.byIcon(Icons.grid_view));
      await tester.pumpAndSettle();

      // Tap Map label
      await tester.tap(find.text('Map'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('fires onPinsTap callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(onPinsTap: () => tapped = true));
      await tester.pumpAndSettle();

      // Expand
      await tester.tap(find.byIcon(Icons.grid_view));
      await tester.pumpAndSettle();

      // Tap Pins label
      await tester.tap(find.text('Pins'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('fires onSettingsTap callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(onSettingsTap: () => tapped = true));
      await tester.pumpAndSettle();

      // Expand
      await tester.tap(find.byIcon(Icons.grid_view));
      await tester.pumpAndSettle();

      // Tap Settings label
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });
}
