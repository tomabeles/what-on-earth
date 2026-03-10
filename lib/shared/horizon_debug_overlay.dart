import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../sensors/horizon_detector.dart';

/// Visual debug overlay for horizon detection.
///
/// Draws the detected circle on screen and shows detection stats so the
/// user can verify the algorithm is finding circular objects (globe,
/// beach ball, horizon).
class HorizonDebugOverlay extends StatelessWidget {
  const HorizonDebugOverlay({super.key, required this.debugNotifier});

  final ValueNotifier<HorizonDebugInfo?> debugNotifier;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<HorizonDebugInfo?>(
      valueListenable: debugNotifier,
      builder: (context, info, _) {
        return CustomPaint(
          size: Size.infinite,
          painter: _HorizonDebugPainter(info),
        );
      },
    );
  }
}

class _HorizonDebugPainter extends CustomPainter {
  _HorizonDebugPainter(this.info);

  final HorizonDebugInfo? info;

  static const _green = Color(0xFF00E640);
  static const _red = Color(0xFFFF4040);
  static const _yellow = Color(0xFFFFCC00);

  @override
  void paint(Canvas canvas, Size size) {
    final debugInfo = info;

    // Draw the detected circle scaled to screen coordinates
    if (debugInfo != null && debugInfo.circle != null) {
      _paintDetectedCircle(canvas, size, debugInfo.circle!);
    }

    // Draw stats panel
    _paintStatsPanel(canvas, size, debugInfo);
  }

  void _paintDetectedCircle(Canvas canvas, Size size, DetectedCircle circle) {
    // Map from downsampled coords (80x60) to screen coords.
    // The camera preview fills the screen, so scale proportionally.
    final scaleX = size.width / kTargetWidth;
    final scaleY = size.height / kTargetHeight;
    final scale = math.min(scaleX, scaleY);

    // Center the mapping
    final offsetX = (size.width - kTargetWidth * scale) / 2;
    final offsetY = (size.height - kTargetHeight * scale) / 2;

    final cx = circle.cx * scale + offsetX;
    final cy = circle.cy * scale + offsetY;
    final r = circle.radius * scale;

    // Circle outline
    final circlePaint = Paint()
      ..color = circle.inlierRatio > 0.5
          ? _green.withValues(alpha: 0.8)
          : _yellow.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawCircle(Offset(cx, cy), r, circlePaint);

    // Center crosshair
    const armLen = 12.0;
    final crossPaint = Paint()
      ..color = _green.withValues(alpha: 0.9)
      ..strokeWidth = 1.5;

    canvas.drawLine(
      Offset(cx - armLen, cy), Offset(cx + armLen, cy), crossPaint);
    canvas.drawLine(
      Offset(cx, cy - armLen), Offset(cx, cy + armLen), crossPaint);

    // Confidence label near circle
    final confText = TextPainter(
      text: TextSpan(
        text: '${(circle.inlierRatio * 100).toInt()}%',
        style: TextStyle(
          color: _green,
          fontSize: 12,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          shadows: const [Shadow(blurRadius: 4, color: Colors.black)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    confText.paint(canvas, Offset(cx + r + 6, cy - 6));
  }

  void _paintStatsPanel(
    Canvas canvas, Size size, HorizonDebugInfo? debugInfo) {
    // Background panel in top-left
    const panelX = 12.0;
    const panelY = 80.0;
    const lineHeight = 16.0;

    final bgPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(panelX - 4, panelY - 4, 200, 100),
        const Radius.circular(4),
      ),
      bgPaint,
    );

    final lines = <(String, Color)>[];

    if (debugInfo == null) {
      lines.add(('HORIZON: WAITING...', _yellow));
    } else {
      // Edge points
      final edgeColor =
          debugInfo.edgePointCount >= kMinEdgePoints ? _green : _red;
      lines.add((
        'EDGES: ${debugInfo.edgePointCount} (min $kMinEdgePoints)',
        edgeColor,
      ));

      // Circle detection
      if (debugInfo.circle != null) {
        final c = debugInfo.circle!;
        lines.add((
          'CIRCLE: (${c.cx.toStringAsFixed(0)},${c.cy.toStringAsFixed(0)}) '
              'r=${c.radius.toStringAsFixed(1)}',
          _green,
        ));
        lines.add((
          'INLIERS: ${c.inlierCount} '
              '(${(c.inlierRatio * 100).toInt()}%)',
          c.inlierRatio > 0.5 ? _green : _yellow,
        ));
      } else {
        lines.add(('CIRCLE: NONE', _red));
      }

      // Correction
      if (debugInfo.correction != null) {
        final cor = debugInfo.correction!;
        lines.add((
          'CORR P:${cor.pitchDeg.toStringAsFixed(1)} '
              'R:${cor.rollDeg.toStringAsFixed(1)}',
          _green,
        ));
      } else {
        lines.add(('CORR: ---', _red));
      }
    }

    for (var i = 0; i < lines.length; i++) {
      final (text, color) = lines[i];
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
            shadows: const [Shadow(blurRadius: 3, color: Colors.black)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(panelX, panelY + i * lineHeight));
    }
  }

  @override
  bool shouldRepaint(_HorizonDebugPainter old) => old.info != info;
}
