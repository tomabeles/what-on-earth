import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../position/position_source.dart';
import 'hud_visibility_provider.dart';
import 'theme.dart';

// ---------------------------------------------------------------------------
// HudData — data model for the data strip (WOE-074)
// ---------------------------------------------------------------------------

/// Data model for telemetry HUD readouts.
class HudData {
  const HudData({
    this.latDeg,
    this.lonDeg,
    this.altKm,
    this.headingDeg,
    this.pitchDeg,
    this.rollDeg,
    this.velocityKmS,
    this.sourceType,
    this.ageSeconds,
    this.fps,
  });

  final double? latDeg;
  final double? lonDeg;
  final double? altKm;
  final double? headingDeg;
  final double? pitchDeg;
  final double? rollDeg;
  final double? velocityKmS;
  final PositionSourceType? sourceType;
  final int? ageSeconds;
  final int? fps;
}

// ---------------------------------------------------------------------------
// FPS provider (WOE-075)
// ---------------------------------------------------------------------------

/// Provider for the FPS value reported by CesiumJS.
final fpsProvider = NotifierProvider<FpsNotifier, int?>(FpsNotifier.new);

class FpsNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void set(int? value) => state = value;
}

/// Provider for live HUD telemetry data, updated by ARScreen.
final hudDataProvider =
    NotifierProvider<HudDataNotifier, HudData>(HudDataNotifier.new);

class HudDataNotifier extends Notifier<HudData> {
  @override
  HudData build() => const HudData();

  void update(HudData data) => state = data;
}

// ---------------------------------------------------------------------------
// TelemetryHud widget
// ---------------------------------------------------------------------------

/// Full-screen `CustomPaint` overlay layer for telemetry HUD elements.
///
/// Layer 3 in the AR Stack (above WebView, below UI chrome). When visibility
/// is OFF, renders nothing (`SizedBox.shrink()`).
///
/// Contains: reticle (WOE-070), heading tape (WOE-071), pitch ladder (WOE-072),
/// roll indicator (WOE-073), data strip (WOE-074), FPS counter (WOE-075).
///
/// Reference: UI_SPEC SS5.2
class TelemetryHud extends ConsumerWidget {
  const TelemetryHud({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(hudVisibilityProvider);
    if (!visible) return const SizedBox.shrink();

    final tokens = Theme.of(context).extension<AppTokens>()!;
    final data = ref.watch(hudDataProvider);
    final fps = ref.watch(fpsProvider);
    final padding = MediaQuery.of(context).padding;

    return CustomPaint(
      painter: HudPainter(
        tokens: tokens,
        headingDeg: data.headingDeg ?? 0,
        pitchDeg: data.pitchDeg ?? 0,
        rollDeg: data.rollDeg ?? 0,
        data: data,
        fps: fps,
        topPadding: padding.top,
      ),
      size: Size.infinite,
    );
  }
}

// ---------------------------------------------------------------------------
// HudPainter
// ---------------------------------------------------------------------------

/// Custom painter for all HUD overlay elements.
class HudPainter extends CustomPainter {
  HudPainter({
    required this.tokens,
    required this.headingDeg,
    required this.pitchDeg,
    required this.rollDeg,
    required this.data,
    required this.fps,
    this.topPadding = 0,
  });

  final AppTokens tokens;
  final double headingDeg;
  final double pitchDeg;
  final double rollDeg;
  final HudData data;
  final int? fps;
  final double topPadding;

  Color get hudColor => tokens.hudPrimary;

  @override
  void paint(Canvas canvas, Size size) {
    _paintReticle(canvas, size);
    _paintHeadingTape(canvas, size);
    _paintPitchLadder(canvas, size);
    _paintRollIndicator(canvas, size);
    _paintDataStrip(canvas, size);
    _paintFpsCounter(canvas, size);
  }

  // ── Reticle (WOE-070) ────────────────────────────────────────────────────

  void _paintReticle(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = hudColor.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const gap = 6.0;
    const arm = 8.0;

    canvas.drawLine(
        center.translate(0, -gap), center.translate(0, -gap - arm), paint);
    canvas.drawLine(
        center.translate(0, gap), center.translate(0, gap + arm), paint);
    canvas.drawLine(
        center.translate(-gap, 0), center.translate(-gap - arm, 0), paint);
    canvas.drawLine(
        center.translate(gap, 0), center.translate(gap + arm, 0), paint);
  }

  // ── Heading Tape (WOE-071) ───────────────────────────────────────────────

  static const _cardinals = {
    0: 'N',
    45: 'NE',
    90: 'E',
    135: 'SE',
    180: 'S',
    225: 'SW',
    270: 'W',
    315: 'NW',
  };

  void _paintHeadingTape(Canvas canvas, Size size) {
    final tapeTop = topPadding + 20;
    const tapeHeight = 40.0;
    final tapeRect =
        Rect.fromLTWH(0, tapeTop, size.width, tapeHeight);

    // Background strip
    canvas.drawRect(
      tapeRect,
      Paint()..color = tokens.hudBackground,
    );

    final tickPaint = Paint()
      ..color = hudColor
      ..strokeWidth = 1.0;

    // Visible range: heading ± 30 degrees
    const visibleArc = 60.0;
    final startDeg = headingDeg - visibleArc / 2;

    for (var d = startDeg.floor(); d <= (headingDeg + visibleArc / 2).ceil(); d++) {
      final deg = ((d % 360) + 360) % 360;
      final x = ((d - startDeg) / visibleArc) * size.width;

      if (deg % 5 != 0) continue;

      final isMajor = deg % 10 == 0;
      final tickLen = isMajor ? 12.0 : 6.0;
      final tickBottom = tapeTop + tapeHeight;

      canvas.drawLine(
        Offset(x, tickBottom - tickLen),
        Offset(x, tickBottom),
        tickPaint,
      );

      if (isMajor) {
        final label =
            _cardinals[deg] ?? deg.toString();
        _drawText(
          canvas,
          label,
          Offset(x, tapeTop + 4),
          tokens.hudFontFamily,
          tokens.hudFontSize - 2,
          hudColor,
          align: TextAlign.center,
        );
      }
    }

    // Center notch (downward triangle)
    final cx = size.width / 2;
    final notchPath = Path()
      ..moveTo(cx - 6, tapeTop)
      ..lineTo(cx + 6, tapeTop)
      ..lineTo(cx, tapeTop + 8)
      ..close();
    canvas.drawPath(notchPath, Paint()..color = hudColor);

    // Current heading text above tape
    _drawText(
      canvas,
      headingDeg.round().toString(),
      Offset(cx, tapeTop - 14),
      tokens.hudFontFamily,
      tokens.hudFontSize,
      hudColor,
      align: TextAlign.center,
    );
  }

  // ── Pitch Ladder (WOE-072) ───────────────────────────────────────────────

  void _paintPitchLadder(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = hudColor.withValues(alpha: 0.6)
      ..strokeWidth = 1.0;

    final centerY = size.height / 2;
    const xOffset = 60.0; // Left third
    const pxPerDeg = 4.0;
    const maxLen = 80.0;
    const minLen = 20.0;

    for (final increment in [-30, -25, -20, -15, -10, -5, 5, 10, 15, 20, 25, 30]) {
      final y = centerY - increment * pxPerDeg;
      final len = minLen + (increment.abs() / 30) * (maxLen - minLen);
      final halfLen = len / 2;

      canvas.drawLine(
        Offset(xOffset - halfLen, y),
        Offset(xOffset + halfLen, y),
        paint,
      );

      // Labels at ±10, ±20, ±30
      if (increment.abs() % 10 == 0) {
        final label = increment > 0 ? '+$increment' : '$increment';
        _drawText(
          canvas,
          label,
          Offset(xOffset + halfLen + 4, y - 5),
          tokens.hudFontFamily,
          tokens.hudFontSize - 2,
          hudColor.withValues(alpha: 0.6),
        );
      }
    }
  }

  // ── Roll Indicator (WOE-073) ─────────────────────────────────────────────

  void _paintRollIndicator(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = topPadding + 10;
    const radius = 50.0;

    final arcPaint = Paint()
      ..color = hudColor.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Arc centered above heading tape, spanning ±60° from top
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy + radius), radius: radius),
      -math.pi / 2 - math.pi / 3,
      math.pi * 2 / 3,
      false,
      arcPaint,
    );

    // Tick marks at 0, ±10, ±20, ±30, ±45, ±60
    final tickAngles = [0, -10, 10, -20, 20, -30, 30, -45, 45, -60, 60];
    for (final deg in tickAngles) {
      final angle = -math.pi / 2 + deg * math.pi / 180;
      final isZero = deg == 0;
      final tickLen = isZero ? 8.0 : 5.0;
      final inner = radius - tickLen;

      final outerX = cx + radius * math.cos(angle);
      final outerY = cy + radius + radius * math.sin(angle);
      final innerX = cx + inner * math.cos(angle);
      final innerY = cy + radius + inner * math.sin(angle);

      canvas.drawLine(
        Offset(innerX, innerY),
        Offset(outerX, outerY),
        arcPaint,
      );
    }

    // Pointer at current roll
    final clampedRoll = rollDeg.clamp(-60.0, 60.0);
    final pointerAngle = -math.pi / 2 + clampedRoll * math.pi / 180;
    final pointerColor =
        rollDeg.abs() > 30 ? tokens.hudWarning : hudColor;
    final pointerPaint = Paint()
      ..color = pointerColor
      ..strokeWidth = 2.0;

    final pInnerR = radius - 10;
    canvas.drawLine(
      Offset(
        cx + pInnerR * math.cos(pointerAngle),
        cy + radius + pInnerR * math.sin(pointerAngle),
      ),
      Offset(
        cx + radius * math.cos(pointerAngle),
        cy + radius + radius * math.sin(pointerAngle),
      ),
      pointerPaint,
    );
  }

  // ── Data Strip (WOE-074) ─────────────────────────────────────────────────

  void _paintDataStrip(Canvas canvas, Size size) {
    const margin = 16.0;
    const colWidth = 130.0;
    const rowHeight = 16.0;
    const padding = 8.0;

    final bottomY = size.height - margin - 80; // Above controls/FAB area

    // Left column background
    final leftRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(margin, bottomY, colWidth, 4 * rowHeight + 2 * padding),
      const Radius.circular(8),
    );
    canvas.drawRRect(leftRect, Paint()..color = tokens.hudBackground);

    // Right column background
    final rightRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
          size.width - margin - colWidth, bottomY, colWidth, 4 * rowHeight + 2 * padding),
      const Radius.circular(8),
    );
    canvas.drawRRect(rightRect, Paint()..color = tokens.hudBackground);

    // Left column data
    final leftX = margin + padding;
    var y = bottomY + padding;

    _drawLabelValue(canvas, 'LAT', _formatLat(data.latDeg), leftX, y);
    y += rowHeight;
    _drawLabelValue(canvas, 'LON', _formatLon(data.lonDeg), leftX, y);
    y += rowHeight;
    _drawLabelValue(canvas, 'ALT', _formatAlt(data.altKm), leftX, y);
    y += rowHeight;
    _drawLabelValue(
        canvas, 'HDG', data.headingDeg?.round().toString() ?? '--', leftX, y);

    // Right column data
    final rightX = size.width - margin - colWidth + padding;
    y = bottomY + padding;

    final velText = (data.sourceType == PositionSourceType.live &&
            data.velocityKmS != null)
        ? '${data.velocityKmS!.toStringAsFixed(2)} km/s'
        : '--';
    _drawLabelValue(canvas, 'VEL', velText, rightX, y);
    y += rowHeight;

    _drawLabelValue(
        canvas, 'SRC', _sourceLabel(data.sourceType), rightX, y);
    y += rowHeight;

    if (data.sourceType != PositionSourceType.static) {
      final ageText =
          data.ageSeconds != null ? '${data.ageSeconds}s' : '--';
      _drawLabelValue(canvas, 'AGE', ageText, rightX, y);
    }
    y += rowHeight;

    _drawLabelValue(
        canvas, 'PCH', _formatSigned(data.pitchDeg), rightX, y);
  }

  void _drawLabelValue(
      Canvas canvas, String label, String value, double x, double y) {
    _drawText(canvas, '$label ', Offset(x, y), tokens.hudFontFamily,
        tokens.hudFontSize - 2, tokens.hudSecondary);
    _drawText(canvas, value, Offset(x + 30, y), tokens.hudFontFamily,
        tokens.hudFontSize, hudColor);
  }

  static String _formatLat(double? v) {
    if (v == null) return '--';
    final dir = v >= 0 ? 'N' : 'S';
    return '${v.abs().toStringAsFixed(3)} $dir';
  }

  static String _formatLon(double? v) {
    if (v == null) return '--';
    final dir = v >= 0 ? 'E' : 'W';
    return '${v.abs().toStringAsFixed(3)} $dir';
  }

  static String _formatAlt(double? v) =>
      v != null ? '${v.toStringAsFixed(1)} km' : '--';

  static String _formatSigned(double? v) =>
      v != null ? (v >= 0 ? '+${v.round()}' : '${v.round()}') : '--';

  static String _sourceLabel(PositionSourceType? type) => switch (type) {
        PositionSourceType.live => 'Live',
        PositionSourceType.estimated => 'TLE',
        PositionSourceType.static => 'Static',
        null => '--',
      };

  // ── FPS Counter (WOE-075) ────────────────────────────────────────────────

  void _paintFpsCounter(Canvas canvas, Size size) {
    final fpsColor = fps == null || fps! >= 25
        ? tokens.hudSecondary
        : fps! >= 15
            ? tokens.hudWarning
            : tokens.hudDanger;
    final text = 'FPS: ${fps ?? '--'}';
    _drawText(
      canvas,
      text,
      Offset(size.width - 16, topPadding + 8),
      tokens.hudFontFamily,
      tokens.hudFontSize - 2,
      fpsColor,
      align: TextAlign.right,
    );
  }

  // ── Text helper ──────────────────────────────────────────────────────────

  void _drawText(
    Canvas canvas,
    String text,
    Offset position,
    String fontFamily,
    double fontSize,
    Color color, {
    TextAlign align = TextAlign.left,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSize,
          color: color,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    double dx;
    switch (align) {
      case TextAlign.center:
        dx = position.dx - tp.width / 2;
      case TextAlign.right:
        dx = position.dx - tp.width;
      default:
        dx = position.dx;
    }
    tp.paint(canvas, Offset(dx, position.dy));
  }

  @override
  bool shouldRepaint(HudPainter oldDelegate) => true;
}
