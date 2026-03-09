import 'package:flutter/material.dart';

import 'layer_control_panel.dart';
import 'settings_content.dart';
import 'theme.dart';

/// Which modal is currently open.
enum HudCommand { none, ctrl, settings }

/// Fighter-jet style command button panel + centered modal overlays.
///
/// Renders a vertically-centered column of command buttons on the right edge
/// of the screen. Tapping a button opens its modal overlay in the center;
/// tapping outside the modal dismisses it.
///
/// Buttons: CTRL> (layer toggles), SET> (settings). Extensible for PIN>, MAP>.
class HudCommandPanel extends StatefulWidget {
  const HudCommandPanel({super.key});

  @override
  State<HudCommandPanel> createState() => _HudCommandPanelState();
}

class _HudCommandPanelState extends State<HudCommandPanel> {
  HudCommand _active = HudCommand.none;

  void _toggle(HudCommand cmd) {
    setState(() => _active = _active == cmd ? HudCommand.none : cmd);
  }

  void _dismiss() {
    setState(() => _active = HudCommand.none);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;

    return Stack(
      children: [
        // Tap barrier (full-screen, only when modal is open)
        if (_active != HudCommand.none)
          Positioned.fill(
            child: GestureDetector(
              onTap: _dismiss,
              behavior: HitTestBehavior.opaque,
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),

        // Modal overlay (centered)
        if (_active != HudCommand.none)
          Center(
            child: _HudModal(
              tokens: tokens,
              child: _buildModalContent(),
            ),
          ),

        // Right-side button column (always visible, on top of barrier)
        Positioned(
          right: 16,
          top: 0,
          bottom: 0,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HudCommandButton(
                  label: 'CTRL>',
                  isActive: _active == HudCommand.ctrl,
                  tokens: tokens,
                  onTap: () => _toggle(HudCommand.ctrl),
                ),
                const SizedBox(height: 8),
                _HudCommandButton(
                  label: 'SET>',
                  isActive: _active == HudCommand.settings,
                  tokens: tokens,
                  onTap: () => _toggle(HudCommand.settings),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModalContent() {
    return switch (_active) {
      HudCommand.ctrl => const LayerToggles(),
      HudCommand.settings => const SettingsBody(),
      HudCommand.none => const SizedBox.shrink(),
    };
  }
}

/// Square transparent button with white border and HUD-primary text.
class _HudCommandButton extends StatelessWidget {
  const _HudCommandButton({
    required this.label,
    required this.isActive,
    required this.tokens,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final AppTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border.all(color: const Color(0xBFC0C0C0), width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: tokens.hudPrimary,
            fontFamily: tokens.hudFontFamily,
            fontSize: tokens.hudFontSize,
          ),
        ),
      ),
    );
  }
}

/// Centered modal container — white border, zero radius, semi-transparent.
class _HudModal extends StatelessWidget {
  const _HudModal({
    required this.tokens,
    required this.child,
  });

  final AppTokens tokens;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Container(
      constraints: BoxConstraints(
        maxWidth: 320,
        maxHeight: screenSize.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        border: Border.all(color: const Color(0xBFC0C0C0), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: child,
    );
  }
}
