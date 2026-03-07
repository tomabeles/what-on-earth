import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/theme.dart';
import 'onboarding_state_manager.dart';

/// Non-blocking banner shown on the AR view when onboarding is incomplete.
///
/// Displays "Finish setup" with a right arrow; tapping navigates to the
/// onboarding flow at the correct step (once OnboardingFlow exists — WOE-046).
///
/// A dismiss (X) button hides the banner for the current session only;
/// it reappears on next app launch if onboarding is still incomplete.
///
/// Reference: PRD FR-ONB-003, FR-ONB-004, UI_SPEC §4.7
class OnboardingBanner extends ConsumerStatefulWidget {
  const OnboardingBanner({super.key, this.onTap});

  /// Called when the user taps the banner.
  final VoidCallback? onTap;

  @override
  ConsumerState<OnboardingBanner> createState() => _OnboardingBannerState();
}

class _OnboardingBannerState extends ConsumerState<OnboardingBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    final mask = ref.watch(onboardingStateProvider);
    final isComplete = (mask & 0x7) == 0x7;

    if (isComplete || _dismissed) return const SizedBox.shrink();

    final tokens = Theme.of(context).extension<AppTokens>();
    final bg = tokens?.hudBackground ?? const Color(0x99000000);
    final primary = tokens?.hudPrimary ?? const Color(0xFF4DD9FF);
    final fontFamily = tokens?.hudFontFamily ?? 'JetBrainsMono';

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 4, left: 12, right: 12),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: primary, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Finish setup',
                    style: TextStyle(
                      color: primary,
                      fontSize: 12,
                      fontFamily: fontFamily,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, color: primary, size: 12),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _dismissed = true),
                    child: Icon(Icons.close, color: primary, size: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
