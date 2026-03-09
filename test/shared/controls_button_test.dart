import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:what_on_earth/shared/hud_command_panel.dart';
import 'package:what_on_earth/shared/layer_control_panel.dart';
import 'package:what_on_earth/shared/theme.dart';

Widget _wrap() {
  return ProviderScope(
    child: MaterialApp(
      theme: buildThemeData(AppThemes.night),
      home: const Scaffold(
        body: HudCommandPanel(),
      ),
    ),
  );
}

void main() {
  group('HudCommandPanel', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('shows CTRL> and SET> buttons', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('CTRL>'), findsOneWidget);
      expect(find.text('SET>'), findsOneWidget);
    });

    testWidgets('opens layer toggles on CTRL> tap', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.byType(LayerToggles), findsNothing);

      await tester.tap(find.text('CTRL>'));
      await tester.pumpAndSettle();

      expect(find.byType(LayerToggles), findsOneWidget);
    });

    testWidgets('layer toggles show Stars, Borders, and Water',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.text('CTRL>'));
      await tester.pumpAndSettle();

      expect(find.text('STARS'), findsOneWidget);
      expect(find.text('BORDERS'), findsOneWidget);
      expect(find.text('WATER'), findsOneWidget);
    });

    testWidgets('toggle updates state without crash', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.text('CTRL>'));
      await tester.pumpAndSettle();

      // Tap the first layer toggle (STARS)
      await tester.tap(find.text('STARS'));
      await tester.pump();
    });

    testWidgets('dismisses modal on second CTRL> tap', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.text('CTRL>'));
      await tester.pumpAndSettle();
      expect(find.byType(LayerToggles), findsOneWidget);

      await tester.tap(find.text('CTRL>'));
      await tester.pumpAndSettle();
      expect(find.byType(LayerToggles), findsNothing);
    });
  });
}
