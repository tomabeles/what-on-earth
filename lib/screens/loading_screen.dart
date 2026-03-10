import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animated loading screen shown during app initialization.
///
/// Displays a pulsing HUD-style reticle with a rotating globe wireframe
/// and the app title. Matches the fighter-jet cockpit aesthetic.
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  LoadingScreenState createState() => LoadingScreenState();
}

class LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _rotateController;
  late final AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      value: 1.0,
    );
  }

  /// Call this to fade out before navigating away.
  Future<void> fadeOut() async {
    await _fadeController.reverse();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeController,
      child: Scaffold(
        backgroundColor: const Color(0xFF08080F),
        body: Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([_pulseController, _rotateController]),
            builder: (context, _) {
              return CustomPaint(
                size: const Size(300, 400),
                painter: _LoadingPainter(
                  pulse: _pulseController.value,
                  rotation: _rotateController.value * 2 * math.pi,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LoadingPainter extends CustomPainter {
  _LoadingPainter({required this.pulse, required this.rotation});

  final double pulse;
  final double rotation;

  static const _green = Color(0xFF00E640);
  static const _dimGreen = Color(0xFF008C28);
  static const _fontFamily = 'monospace';

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 30;

    _paintGlobe(canvas, cx, cy);
    _paintReticle(canvas, cx, cy);
    _paintTitle(canvas, size);
    _paintLoadingDots(canvas, size);
  }

  void _paintGlobe(Canvas canvas, double cx, double cy) {
    const r = 100.0;
    final globePaint = Paint()
      ..color = _green.withValues(alpha: 0.15 + pulse * 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Globe outline
    canvas.drawCircle(Offset(cx, cy), r, globePaint);

    // Latitude lines
    final latPaint = Paint()
      ..color = _dimGreen.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (final latDeg in [-45, 0, 45]) {
      final latRad = latDeg * math.pi / 180;
      final yOff = r * math.sin(latRad);
      final halfW = r * math.cos(latRad);
      final arcH = halfW * 0.12;
      final rect = Rect.fromLTRB(
        cx - halfW, cy - yOff - arcH,
        cx + halfW, cy - yOff + arcH,
      );
      final paint = latDeg == 0
          ? (Paint()
            ..color = _green.withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5)
          : latPaint;
      canvas.drawOval(rect, paint);
    }

    // Longitude lines (rotating)
    final lonPaint = Paint()
      ..color = _dimGreen.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (final lonDeg in [-60, -20, 20, 60]) {
      final adjusted = lonDeg * math.pi / 180 + rotation;
      final xOff = r * math.sin(adjusted);
      final halfW = (r * math.cos(adjusted)).abs() * 0.2;
      if (halfW < 2) continue;
      canvas.drawOval(
        Rect.fromLTRB(cx + xOff - halfW, cy - r, cx + xOff + halfW, cy + r),
        lonPaint,
      );
    }

    // Glow pulse
    final glowPaint = Paint()
      ..color = _green.withValues(alpha: 0.05 + pulse * 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(cx, cy), r + 4, glowPaint);
  }

  void _paintReticle(Canvas canvas, double cx, double cy) {
    final alpha = 0.4 + pulse * 0.4;
    final paint = Paint()
      ..color = _green.withValues(alpha: alpha)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    const gap = 8.0;
    const arm = 20.0;

    // Cross arms
    canvas.drawLine(Offset(cx, cy - gap - arm), Offset(cx, cy - gap), paint);
    canvas.drawLine(Offset(cx, cy + gap), Offset(cx, cy + gap + arm), paint);
    canvas.drawLine(Offset(cx - gap - arm, cy), Offset(cx - gap, cy), paint);
    canvas.drawLine(Offset(cx + gap, cy), Offset(cx + gap + arm, cy), paint);

    // Corner brackets
    const t = 6.0;
    final bp = Paint()
      ..color = _green.withValues(alpha: alpha * 0.8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final dx in [-1.0, 1.0]) {
      for (final dy in [-1.0, 1.0]) {
        final x = cx + dx * gap;
        final y = cy + dy * gap;
        canvas.drawLine(Offset(x, y), Offset(x, y + dy * -t), bp);
        canvas.drawLine(Offset(x, y), Offset(x + dx * -t, y), bp);
      }
    }
  }

  void _paintTitle(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: const TextSpan(
        text: 'WHAT ON EARTH?!',
        style: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: _green,
          letterSpacing: 4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(
      canvas,
      Offset((size.width - tp.width) / 2, size.height / 2 + 100),
    );
  }

  void _paintLoadingDots(Canvas canvas, Size size) {
    // Three dots that pulse in sequence
    final baseY = size.height / 2 + 140;
    final baseCx = size.width / 2;

    for (var i = 0; i < 3; i++) {
      final phase = (pulse + i * 0.33) % 1.0;
      final alpha = 0.2 + phase * 0.6;
      final radius = 2.5 + phase * 1.5;
      canvas.drawCircle(
        Offset(baseCx - 12 + i * 12, baseY),
        radius,
        Paint()..color = _green.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_LoadingPainter old) => true;
}
