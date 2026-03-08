import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'hud_visibility_provider.dart';
import 'theme.dart';

/// Full-screen `CustomPaint` overlay layer for telemetry HUD elements.
///
/// Layer 3 in the AR Stack (above WebView, below UI chrome). When visibility
/// is OFF, renders nothing (`SizedBox.shrink()`).
///
/// This scaffold ticket (WOE-070) contains only the center reticle. Subsequent
/// tickets WOE-071–WOE-076 add additional elements.
///
/// Reference: UI_SPEC SS5.2
class TelemetryHud extends ConsumerWidget {
  const TelemetryHud({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(hudVisibilityProvider);
    if (!visible) return const SizedBox.shrink();

    final tokens = Theme.of(context).extension<AppTokens>()!;
    return CustomPaint(
      painter: HudPainter(hudColor: tokens.hudPrimary),
      size: Size.infinite,
    );
  }
}

/// Custom painter for HUD overlay elements.
///
/// Currently paints only the center reticle crosshair. Future tickets will add
/// telemetry readouts, compass bearing, altitude tape, etc.
class HudPainter extends CustomPainter {
  HudPainter({required this.hudColor});

  final Color hudColor;

  @override
  void paint(Canvas canvas, Size size) {
    _paintReticle(canvas, size);
  }

  /// Boresight crosshair at screen center — four 8dp arms with 12dp gap
  /// (6dp on each side of center).
  void _paintReticle(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = hudColor.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const gap = 6.0; // Half of the 12dp gap
    const arm = 8.0;

    // Up
    canvas.drawLine(
      center.translate(0, -gap),
      center.translate(0, -gap - arm),
      paint,
    );
    // Down
    canvas.drawLine(
      center.translate(0, gap),
      center.translate(0, gap + arm),
      paint,
    );
    // Left
    canvas.drawLine(
      center.translate(-gap, 0),
      center.translate(-gap - arm, 0),
      paint,
    );
    // Right
    canvas.drawLine(
      center.translate(gap, 0),
      center.translate(gap + arm, 0),
      paint,
    );
  }

  @override
  bool shouldRepaint(HudPainter oldDelegate) =>
      hudColor != oldDelegate.hudColor;
}
