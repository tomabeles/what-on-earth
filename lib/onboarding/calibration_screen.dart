import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../shared/theme.dart';

/// Standalone Calibration screen used by Onboarding step 3 (WOE-046) and
/// Settings → Sensor (WOE-083).
///
/// Full-screen dark surface with an animated device silhouette performing a
/// figure-8 motion, a confidence ring, and Done/Restart buttons.
///
/// The calibration algorithm is in WOE-047. This ticket builds only the UI
/// shell, accepting confidence as external input.
///
/// Reference: UI_SPEC SS4.8
class CalibrationScreen extends StatelessWidget {
  const CalibrationScreen({
    super.key,
    required this.confidence,
    this.onDone,
    this.onRestart,
  });

  /// Calibration confidence from 0.0 to 1.0.
  final double confidence;

  /// Called when the user taps Done (only enabled when confidence >= 0.8).
  final VoidCallback? onDone;

  /// Called when the user taps Restart (resets to 0%).
  final VoidCallback? onRestart;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final doneEnabled = confidence >= 0.8;

    return Scaffold(
      backgroundColor: tokens.surfacePrimary,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated figure-8 device silhouette
              const _Figure8Animation(),
              const SizedBox(height: 32),
              // Confidence ring
              _ConfidenceRing(
                confidence: confidence,
                tokens: tokens,
              ),
              const SizedBox(height: 24),
              // Instruction text
              Text(
                'Move your device in a slow figure-8 pattern.',
                style: TextStyle(
                  color: tokens.hudPrimary,
                  fontSize: 14,
                  fontFamily: tokens.hudFontFamily,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Done button
              ElevatedButton(
                onPressed: doneEnabled ? onDone : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: tokens.fabBackground,
                  foregroundColor: tokens.fabIcon,
                  disabledBackgroundColor: tokens.borderPrimary,
                  disabledForegroundColor: tokens.hudSecondary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
                ),
                child: const Text('Done'),
              ),
              const SizedBox(height: 12),
              // Restart button
              TextButton(
                onPressed: onRestart,
                child: Text(
                  'Restart',
                  style: TextStyle(color: tokens.hudSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Figure-8 Animation
// ---------------------------------------------------------------------------

class _Figure8Animation extends StatefulWidget {
  const _Figure8Animation();

  @override
  State<_Figure8Animation> createState() => _Figure8AnimationState();
}

class _Figure8AnimationState extends State<_Figure8Animation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;

    return SizedBox(
      width: 180,
      height: 180,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value * 2 * math.pi;
          // Lissajous curve: x = sin(t), y = sin(2t)
          final x = math.sin(t) * 80;
          final y = math.sin(2 * t) * 40;

          return Stack(
            children: [
              Center(
                child: Transform.translate(
                  offset: Offset(x, y),
                  child: Icon(
                    Icons.phone_android,
                    size: 36,
                    color: tokens.hudPrimary,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Confidence Ring
// ---------------------------------------------------------------------------

class _ConfidenceRing extends StatelessWidget {
  const _ConfidenceRing({
    required this.confidence,
    required this.tokens,
  });

  final double confidence;
  final AppTokens tokens;

  Color get _ringColor {
    if (confidence < 0.4) return tokens.hudDanger;
    if (confidence < 0.8) return tokens.hudWarning;
    return tokens.hudPrimary;
  }

  @override
  Widget build(BuildContext context) {
    final percent = (confidence * 100).toInt().clamp(0, 100);

    return SizedBox(
      width: 120,
      height: 120,
      child: CustomPaint(
        painter: _RingPainter(
          progress: confidence,
          color: _ringColor,
          trackColor: tokens.borderPrimary,
        ),
        child: Center(
          child: Text(
            '$percent%',
            style: TextStyle(
              color: tokens.hudPrimary,
              fontFamily: tokens.hudFontFamily,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4; // 8dp stroke, inset by half
    const strokeWidth = 8.0;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      progress.clamp(0.0, 1.0) * 2 * math.pi,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      color != oldDelegate.color ||
      trackColor != oldDelegate.trackColor;
}
