import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:what_on_earth/onboarding/onboarding_state_manager.dart';

void main() {
  group('OnboardingStateManager', () {
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() => container.dispose());

    test('initial state is 0 (no steps complete)', () {
      final mask = container.read(onboardingStateProvider);
      expect(mask, 0);
    });

    test('markStepComplete sets the correct bit', () async {
      final notifier = container.read(onboardingStateProvider.notifier);
      await notifier.markStepComplete(0);
      expect(container.read(onboardingStateProvider), 1);

      await notifier.markStepComplete(1);
      expect(container.read(onboardingStateProvider), 3);

      await notifier.markStepComplete(2);
      expect(container.read(onboardingStateProvider), 7);
    });

    test('isComplete returns true when all 3 bits set', () async {
      final notifier = container.read(onboardingStateProvider.notifier);
      expect(notifier.isComplete, false);

      await notifier.markStepComplete(0);
      await notifier.markStepComplete(1);
      expect(notifier.isComplete, false);

      await notifier.markStepComplete(2);
      expect(notifier.isComplete, true);
    });

    test('currentStep returns first incomplete step index', () async {
      final notifier = container.read(onboardingStateProvider.notifier);
      expect(notifier.currentStep, 0);

      await notifier.markStepComplete(0);
      expect(notifier.currentStep, 1);

      await notifier.markStepComplete(1);
      expect(notifier.currentStep, 2);

      await notifier.markStepComplete(2);
      expect(notifier.currentStep, onboardingStepCount);
    });

    test('markStepComplete is idempotent', () async {
      final notifier = container.read(onboardingStateProvider.notifier);
      await notifier.markStepComplete(1);
      await notifier.markStepComplete(1);
      expect(container.read(onboardingStateProvider), 2);
    });

    test('state persists to SharedPreferences', () async {
      final notifier = container.read(onboardingStateProvider.notifier);
      await notifier.markStepComplete(0);
      await notifier.markStepComplete(2);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('onboarding_complete_mask'), 5);
    });

    test('loads saved mask from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'onboarding_complete_mask': 7});
      final c2 = ProviderContainer();
      addTearDown(c2.dispose);

      c2.read(onboardingStateProvider);
      await Future<void>.delayed(Duration.zero);

      expect(c2.read(onboardingStateProvider), 7);
      expect(c2.read(onboardingStateProvider.notifier).isComplete, true);
    });

    test('reset clears mask and SharedPreferences', () async {
      final notifier = container.read(onboardingStateProvider.notifier);
      await notifier.markStepComplete(0);
      await notifier.markStepComplete(1);
      await notifier.markStepComplete(2);
      expect(notifier.isComplete, true);

      await notifier.reset();
      expect(container.read(onboardingStateProvider), 0);
      expect(notifier.isComplete, false);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('onboarding_complete_mask'), isNull);
    });

    test('steps can be completed out of order', () async {
      final notifier = container.read(onboardingStateProvider.notifier);
      await notifier.markStepComplete(2);
      expect(container.read(onboardingStateProvider), 4);
      expect(notifier.currentStep, 0);

      await notifier.markStepComplete(0);
      expect(notifier.currentStep, 1);
    });
  });
}
