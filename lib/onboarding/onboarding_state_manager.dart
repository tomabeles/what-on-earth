import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefKey = 'onboarding_complete_mask';

/// Number of onboarding steps (welcome, tile download, calibration).
const onboardingStepCount = 3;

/// Bitmask indicating all steps complete: bits 0, 1, 2 set.
const _allComplete = 0x7;

/// Provides the onboarding completion bitmask.
///
/// Bit 0 = welcome complete, bit 1 = tile download complete,
/// bit 2 = calibration complete. `isComplete` is true when all three
/// bits are set (mask == 0x7).
///
/// Reference: PRD FR-ONB-003, FR-ONB-004, TECH_SPEC §7.5
final onboardingStateProvider =
    NotifierProvider<OnboardingStateManager, int>(OnboardingStateManager.new);

class OnboardingStateManager extends Notifier<int> {
  @override
  int build() {
    _loadSaved();
    return 0;
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted) return;
    final mask = prefs.getInt(_prefKey) ?? 0;
    state = mask;
  }

  /// Whether all onboarding steps are complete.
  bool get isComplete => (state & _allComplete) == _allComplete;

  /// Returns the index of the first incomplete step (0, 1, or 2), or
  /// [onboardingStepCount] if all steps are complete.
  int get currentStep {
    for (var i = 0; i < onboardingStepCount; i++) {
      if ((state & (1 << i)) == 0) return i;
    }
    return onboardingStepCount;
  }

  /// Marks the given [stepIndex] (0, 1, or 2) as complete.
  Future<void> markStepComplete(int stepIndex) async {
    assert(stepIndex >= 0 && stepIndex < onboardingStepCount);
    final newMask = state | (1 << stepIndex);
    state = newMask;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKey, newMask);
  }

  /// Resets all onboarding progress (for testing / debug).
  Future<void> reset() async {
    state = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }
}
