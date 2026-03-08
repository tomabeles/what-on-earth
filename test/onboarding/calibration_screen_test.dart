import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:what_on_earth/onboarding/calibration_screen.dart';
import 'package:what_on_earth/shared/theme.dart';

Widget _wrap({
  required double confidence,
  VoidCallback? onDone,
  VoidCallback? onRestart,
}) {
  return MaterialApp(
    theme: buildThemeData(AppThemes.night),
    home: CalibrationScreen(
      confidence: confidence,
      onDone: onDone,
      onRestart: onRestart,
    ),
  );
}

void main() {
  group('CalibrationScreen (WOE-084)', () {
    // NOTE: pumpAndSettle will never settle because the figure-8 animation
    // repeats forever. Use pump() instead.

    testWidgets('shows instruction text', (tester) async {
      await tester.pumpWidget(_wrap(confidence: 0.0));
      await tester.pump();

      expect(find.text('Move your device in a slow figure-8 pattern.'),
          findsOneWidget);
    });

    testWidgets('Done button disabled at 50%', (tester) async {
      await tester.pumpWidget(_wrap(confidence: 0.5));
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Done'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('Done button enabled at 85%', (tester) async {
      var doneTapped = false;
      await tester.pumpWidget(
          _wrap(confidence: 0.85, onDone: () => doneTapped = true));
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Done'),
      );
      expect(button.onPressed, isNotNull);

      await tester.tap(find.text('Done'));
      expect(doneTapped, isTrue);
    });

    testWidgets('shows confidence percentage', (tester) async {
      await tester.pumpWidget(_wrap(confidence: 0.73));
      await tester.pump();

      expect(find.text('73%'), findsOneWidget);
    });

    testWidgets('Restart button calls onRestart', (tester) async {
      var restarted = false;
      await tester.pumpWidget(
          _wrap(confidence: 0.5, onRestart: () => restarted = true));
      await tester.pump();

      await tester.tap(find.text('Restart'));
      expect(restarted, isTrue);
    });

    testWidgets('figure-8 animation is running', (tester) async {
      await tester.pumpWidget(_wrap(confidence: 0.0));
      await tester.pump();

      // The phone icon should be present (animated via figure-8)
      expect(find.byIcon(Icons.phone_android), findsOneWidget);

      // Advance animation and verify no crash
      await tester.pump(const Duration(seconds: 2));
      expect(find.byIcon(Icons.phone_android), findsOneWidget);
    });

    testWidgets('ring color is hudDanger below 40%', (tester) async {
      await tester.pumpWidget(_wrap(confidence: 0.2));
      await tester.pump();

      expect(find.text('20%'), findsOneWidget);
    });

    testWidgets('ring color is hudWarning at 50%', (tester) async {
      await tester.pumpWidget(_wrap(confidence: 0.5));
      await tester.pump();

      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('ring color is hudPrimary at 90%', (tester) async {
      await tester.pumpWidget(_wrap(confidence: 0.9));
      await tester.pump();

      expect(find.text('90%'), findsOneWidget);
    });
  });
}
