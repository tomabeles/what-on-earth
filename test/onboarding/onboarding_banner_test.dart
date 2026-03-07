import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:what_on_earth/onboarding/onboarding_banner.dart';
import 'package:what_on_earth/onboarding/onboarding_state_manager.dart';

Widget _wrap({VoidCallback? onTap}) {
  return ProviderScope(
    child: MaterialApp(
      home: Scaffold(
        body: OnboardingBanner(onTap: onTap),
      ),
    ),
  );
}

void main() {
  group('OnboardingBanner', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('shows banner when onboarding incomplete', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('Finish setup'), findsOneWidget);
    });

    testWidgets('hides banner when onboarding complete', (tester) async {
      SharedPreferences.setMockInitialValues({'onboarding_complete_mask': 7});
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('Finish setup'), findsNothing);
    });

    testWidgets('dismiss hides banner for session', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('Finish setup'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Finish setup'), findsNothing);
    });

    testWidgets('calls onTap when banner tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(onTap: () => tapped = true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Finish setup'));
      expect(tapped, true);
    });

    testWidgets('banner disappears when all steps marked complete',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('Finish setup'), findsOneWidget);

      final container = ProviderScope.containerOf(
          tester.element(find.byType(OnboardingBanner)));
      final notifier = container.read(onboardingStateProvider.notifier);
      await notifier.markStepComplete(0);
      await notifier.markStepComplete(1);
      await notifier.markStepComplete(2);
      await tester.pumpAndSettle();

      expect(find.text('Finish setup'), findsNothing);
    });
  });
}
