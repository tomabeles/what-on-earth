import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sensors/sensor_fusion.dart';
import '../sensors/sensor_fusion_provider.dart';
import 'debug_provider.dart';
import 'theme.dart';

/// Debug overlay showing live raw sensor values (accel, gyro, mag).
class DebugRawValuesOverlay extends ConsumerWidget {
  const DebugRawValuesOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(debugProvider).showRawValues) {
      return const SizedBox.shrink();
    }

    // Watch orientation stream to trigger repaints at ~50 Hz.
    ref.watch(orientationStreamProvider);

    final engine = ref.read(sensorFusionEngineProvider);
    final tokens = Theme.of(context).extension<AppTokens>()!;

    return CustomPaint(
      size: Size.infinite,
      painter: _RawValuesPainter(
        accel: engine.lastRawAccel,
        gyro: engine.lastRawGyro,
        mag: engine.lastRawMag,
        tokens: tokens,
      ),
    );
  }
}

class _RawValuesPainter extends CustomPainter {
  _RawValuesPainter({
    required this.accel,
    required this.gyro,
    required this.mag,
    required this.tokens,
  });

  final RawSensorSample? accel;
  final RawSensorSample? gyro;
  final RawSensorSample? mag;
  final AppTokens tokens;

  static const _rowHeight = 14.0;
  static const _padding = 6.0;
  static const _panelWidth = 200.0;

  @override
  void paint(Canvas canvas, Size size) {
    const rows = 3;
    const panelHeight = rows * _rowHeight + 2 * _padding;
    // Position above the telemetry data strip (which occupies bottom ~96px).
    final panelY = size.height - 200;
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

    _drawRow(canvas, 'A', accel, 2, x, y);
    y += _rowHeight;
    _drawRow(canvas, 'G', gyro, 2, x, y);
    y += _rowHeight;
    _drawRow(canvas, 'M', mag, 1, x, y);
  }

  void _drawRow(
    Canvas canvas,
    String label,
    RawSensorSample? sample,
    int decimals,
    double x,
    double y,
  ) {
    // Label
    _drawText(canvas, '$label:', Offset(x, y), tokens.hudSecondary);

    if (sample == null) {
      _drawText(canvas, '--', Offset(x + 20, y), tokens.hudPrimary);
      return;
    }

    final values =
        '${_fmt(sample.x, decimals)}  ${_fmt(sample.y, decimals)}  ${_fmt(sample.z, decimals)}';
    _drawText(canvas, values, Offset(x + 20, y), tokens.hudPrimary);
  }

  String _fmt(double v, int decimals) {
    final s = v.toStringAsFixed(decimals);
    // Pad to consistent width: sign + digits
    return s.padLeft(decimals == 2 ? 7 : 6);
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
  bool shouldRepaint(_RawValuesPainter oldDelegate) => true;
}
