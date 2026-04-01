import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:what_on_earth/onboarding/onboarding_flow.dart';
import 'package:what_on_earth/onboarding/onboarding_state_manager.dart';
import 'package:what_on_earth/shared/theme.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestApp({int initialMask = 0}) {
    SharedPreferences.setMockInitialValues(
      initialMask > 0 ? {'onboarding_complete_mask': initialMask} : {},
    );

    return ProviderScope(
      child: MaterialApp(
        theme: buildThemeData(AppThemes.night),
        home: const OnboardingFlow(),
      ),
    );
  }

  group('OnboardingFlow', () {
    testWidgets('shows welcome step initially', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('WHAT ON EARTH?!'), findsOneWidget);
      expect(find.text('Get Started →'), findsOneWidget);
    });

    testWidgets('tapping Get Started advances to tile download step',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Get Started →'));
      await tester.pumpAndSettle();

      expect(find.text('Download Map Tiles'), findsOneWidget);
    });

    testWidgets('page indicator shows 3 dots', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Find AnimatedContainers used as page dots
      final dots = find.byType(AnimatedContainer);
      expect(dots, findsNWidgets(3));
    });

    testWidgets('marks step 0 complete on Get Started', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Read the container to check the provider
      final container = ProviderScope.containerOf(
        tester.element(find.byType(OnboardingFlow)),
      );

      expect(container.read(onboardingStateProvider), 0);

      await tester.tap(find.text('Get Started →'));
      await tester.pumpAndSettle();

      // Step 0 bit should be set
      expect(container.read(onboardingStateProvider) & 1, 1);
    });

    testWidgets('resumes at correct step when steps already complete',
        (tester) async {
      // Step 0 already complete (mask = 1)
      await tester.pumpWidget(buildTestApp(initialMask: 1));
      // Need extra pump for SharedPreferences async load
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Should show tile download step, not welcome
      expect(find.text('Download Map Tiles'), findsOneWidget);
      expect(find.text('Get Started →'), findsNothing);
    });

    testWidgets('skip on tile download advances to calibration', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Advance to step 2 (tile download)
      await tester.tap(find.text('Get Started →'));
      await tester.pumpAndSettle();

      // Tap Skip on the tile download step
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Should now be on calibration step
      expect(find.text('Compass Calibration'), findsOneWidget);
    });
  });
}
