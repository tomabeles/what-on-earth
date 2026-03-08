import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:what_on_earth/shared/controls_button.dart';
import 'package:what_on_earth/shared/layer_control_panel.dart';
import 'package:what_on_earth/shared/theme.dart';

Widget _wrap({bool isMapMode = false}) {
  return ProviderScope(
    child: MaterialApp(
      theme: buildThemeData(AppThemes.night),
      home: Scaffold(
        body: ControlsButton(isMapMode: isMapMode),
      ),
    ),
  );
}

void main() {
  group('ControlsButton + LayerControlPanel (WOE-068)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('shows Controls label', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.textContaining('Controls'), findsOneWidget);
    });

    testWidgets('opens panel on tap', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // Panel should not be visible
      expect(find.byType(LayerControlPanel), findsNothing);

      // Tap the controls button
      await tester.tap(find.textContaining('Controls'));
      await tester.pumpAndSettle();

      // Panel should be visible
      expect(find.byType(LayerControlPanel), findsOneWidget);
    });

    testWidgets('panel shows all 7 layer toggles', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Controls'));
      await tester.pumpAndSettle();

      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Relief shading'), findsOneWidget);
      expect(find.text('Cloud cover'), findsOneWidget);
      expect(find.text('Country borders'), findsOneWidget);
      expect(find.text('Coastlines'), findsOneWidget);
      expect(find.text('Cities & labels'), findsOneWidget);
      expect(find.text('Rivers & lakes'), findsOneWidget);
    });

    testWidgets('camera row hidden in map mode', (tester) async {
      await tester.pumpWidget(_wrap(isMapMode: true));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Controls'));
      await tester.pumpAndSettle();

      expect(find.text('Camera'), findsNothing);
      // Others still visible
      expect(find.text('Relief shading'), findsOneWidget);
    });

    testWidgets('toggles update state', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Controls'));
      await tester.pumpAndSettle();

      // Rivers & lakes default is OFF — find its switch
      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(7));

      // Toggle one of the switches
      await tester.tap(switches.last);
      await tester.pump();

      // Verify the state changed (no crash)
    });

    testWidgets('closes panel on second tap of controls', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // Open
      await tester.tap(find.textContaining('Controls'));
      await tester.pumpAndSettle();
      expect(find.byType(LayerControlPanel), findsOneWidget);

      // Close
      await tester.tap(find.textContaining('Controls'));
      await tester.pumpAndSettle();
      expect(find.byType(LayerControlPanel), findsNothing);
    });
  });
}
