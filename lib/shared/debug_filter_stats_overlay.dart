import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sensors/sensor_fusion.dart';
import '../sensors/sensor_fusion_provider.dart';
import 'debug_provider.dart';
import 'theme.dart';

/// Debug overlay showing complementary filter diagnostics.
class DebugFilterStatsOverlay extends ConsumerWidget {
  const DebugFilterStatsOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(debugProvider).showFilterStats) {
      return const SizedBox.shrink();
    }

    ref.watch(orientationStreamProvider);

    final engine = ref.read(sensorFusionEngineProvider);
    final tokens = Theme.of(context).extension<AppTokens>()!;

    return CustomPaint(
      size: Size.infinite,
      painter: _FilterStatsPainter(
        effectiveAlpha: engine.lastEffectiveAlpha,
        gravityDeviation: engine.lastGravityDeviation,
        headingRefDelta: engine.lastHeadingRefDelta,
        interference: engine.interferenceDetected,
        tokens: tokens,
      ),
    );
  }
}

class _FilterStatsPainter extends CustomPainter {
  _FilterStatsPainter({
    required this.effectiveAlpha,
    required this.gravityDeviation,
    required this.headingRefDelta,
    required this.interference,
    required this.tokens,
  });

  final double effectiveAlpha;
  final double gravityDeviation;
  final double headingRefDelta;
  final bool interference;
  final AppTokens tokens;

  static const _rowHeight = 14.0;
  static const _padding = 6.0;
  static const _panelWidth = 200.0;

  @override
  void paint(Canvas canvas, Size size) {
    const rows = 4;
    const panelHeight = rows * _rowHeight + 2 * _padding;
    // Sits below the raw values panel (which is at ~size.height - 200).
    final panelY = size.height - 200 + 56;
    const panelX = 16.0;

    // Background
    final panelRect =
        Rect.fromLTWH(panelX, panelY, _panelWidth, panelHeight);
    canvas.drawRect(
      panelRect,
      Paint()..color = tokens.hudBackground.withValues(alpha: 0.3),
    );
    canvas.drawRect(
      panelRect,
      Paint()
        ..color = const Color(0xBFC0C0C0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    var y = panelY + _padding;
    final x = panelX + _padding;

    // Alpha
    final alphaColor = effectiveAlpha <= kFilterAlpha
        ? tokens.hudPrimary
        : effectiveAlpha < 0.995
            ? tokens.hudWarning
            : tokens.hudDanger;
    _drawLabelValue(
        canvas, 'ALPHA', effectiveAlpha.toStringAsFixed(3), alphaColor, x, y);
    y += _rowHeight;

    // Gravity deviation
    final gravPct = (gravityDeviation * 100).toStringAsFixed(1);
    final gravColor = gravityDeviation < 0.10
        ? tokens.hudPrimary
        : gravityDeviation < 0.20
            ? tokens.hudWarning
            : tokens.hudDanger;
    _drawLabelValue(canvas, 'GRAV', '$gravPct%', gravColor, x, y);
    y += _rowHeight;

    // Heading reference delta
    final hdgColor = headingRefDelta < 5
        ? tokens.hudPrimary
        : headingRefDelta < 15
            ? tokens.hudWarning
            : tokens.hudDanger;
    _drawLabelValue(canvas, 'HDG\u0394',
        '${headingRefDelta.toStringAsFixed(1)}\u00B0', hdgColor, x, y);
    y += _rowHeight;

    // Magnetometer interference
    final magColor = interference ? tokens.hudDanger : tokens.hudPrimary;
    final magText = interference ? 'WARN' : 'OK';
    _drawLabelValue(canvas, 'MAG', magText, magColor, x, y);
  }

  void _drawLabelValue(
    Canvas canvas,
    String label,
    String value,
    Color valueColor,
    double x,
    double y,
  ) {
    _drawText(canvas, label.padRight(6), Offset(x, y), tokens.hudSecondary);
    _drawText(canvas, value, Offset(x + 48, y), valueColor);
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: tokens.hudFontFamily,
          fontSize: 10,
          color: color,
          shadows: const [Shadow(blurRadius: 3, color: Colors.black)],
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp.paint(canvas, position);
  }

  @override
  bool shouldRepaint(_FilterStatsPainter oldDelegate) => true;
}
