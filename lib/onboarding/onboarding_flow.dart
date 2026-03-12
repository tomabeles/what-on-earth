import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/ar_screen.dart';
import '../shared/theme.dart';
import 'calibration_step.dart';
import 'onboarding_state_manager.dart';
import 'tile_download_step.dart';

/// 3-step onboarding flow assembled as a PageView (WOE-046).
///
/// Steps:
/// 1. Welcome — app branding + "Get Started"
/// 2. Tile Download — embed [TileDownloadStep] from WOE-032
/// 3. Calibration — embed [CalibrationStep] from WOE-047
///
/// Navigation is button-driven (swipe disabled) so users can't accidentally
/// skip a step. Steps are resumable — on re-launch, the flow starts at the
/// first incomplete step.
///
/// Reference: TECH_SPEC §7.5, PRD FR-ONB-001 through FR-ONB-004
class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _completeStep(int stepIndex) async {
    await ref.read(onboardingStateProvider.notifier).markStepComplete(stepIndex);

    if (stepIndex < 2) {
      _goToPage(stepIndex + 1);
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const ARScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;

    // Watch the mask so we rebuild when the async SharedPreferences load
    // completes, then jump to the first incomplete step.
    final mask = ref.watch(onboardingStateProvider);
    final notifier = ref.read(onboardingStateProvider.notifier);
    final targetPage = notifier.currentStep.clamp(0, 2);
    if (_pageController.hasClients) {
      final currentPage = _pageController.page?.round() ?? 0;
      if (targetPage > currentPage) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(targetPage);
          }
        });
      }
    }
    // Suppress unused variable warning — we watch mask for reactivity.
    assert(mask >= 0);

    return Scaffold(
      backgroundColor: tokens.surfacePrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Page indicator
            _PageIndicator(
              pageController: _pageController,
              tokens: tokens,
            ),
            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Step 1: Welcome
                  _WelcomeStep(
                    onGetStarted: () => _completeStep(0),
                    tokens: tokens,
                  ),
                  // Step 2: Tile Download
                  TileDownloadStep(
                    onComplete: () => _completeStep(1),
                  ),
                  // Step 3: Calibration
                  CalibrationStep(
                    onComplete: () => _completeStep(2),
                    onSkip: () => _completeStep(2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 1: Welcome
// ---------------------------------------------------------------------------

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.onGetStarted, required this.tokens});

  final VoidCallback onGetStarted;
  final AppTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.public, size: 80, color: tokens.hudPrimary),
          const SizedBox(height: 24),
          Text(
            'WHAT ON EARTH?!',
            style: TextStyle(
              color: tokens.hudPrimary,
              fontSize: 26,
              fontFamily: tokens.hudFontFamily,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'This app uses your device sensors and the ISS\n'
            'position feed to show you a live view of Earth.\n'
            'No setup needed.',
            style: TextStyle(
              color: tokens.hudSecondary,
              fontSize: 14,
              fontFamily: tokens.hudFontFamily,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: onGetStarted,
            style: ElevatedButton.styleFrom(
              backgroundColor: tokens.fabBackground,
              foregroundColor: tokens.fabIcon,
              padding:
                  const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
            ),
            child: const Text('Get Started →'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page indicator dots
// ---------------------------------------------------------------------------

class _PageIndicator extends StatefulWidget {
  const _PageIndicator({
    required this.pageController,
    required this.tokens,
  });

  final PageController pageController;
  final AppTokens tokens;

  @override
  State<_PageIndicator> createState() => _PageIndicatorState();
}

class _PageIndicatorState extends State<_PageIndicator> {
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.pageController.initialPage;
    widget.pageController.addListener(_onPageChanged);
  }

  @override
  void dispose() {
    widget.pageController.removeListener(_onPageChanged);
    super.dispose();
  }

  void _onPageChanged() {
    final page = widget.pageController.page?.round() ?? 0;
    if (page != _currentPage) {
      setState(() => _currentPage = page);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) {
          final active = i == _currentPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: active ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: active
                  ? widget.tokens.hudPrimary
                  : widget.tokens.borderPrimary,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}
