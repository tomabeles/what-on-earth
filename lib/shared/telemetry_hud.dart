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
    this.bearingDeg,
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
  final double? bearingDeg;
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

    // Background strip — slightly more transparent than other HUD panels
    canvas.drawRect(
      tapeRect,
      Paint()..color = tokens.hudBackground.withValues(alpha: 0.3),
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
      final tickTop = tapeTop;

      canvas.drawLine(
        Offset(x, tickTop),
        Offset(x, tickTop + tickLen),
        tickPaint,
      );

      if (isMajor) {
        final label =
            _cardinals[deg] ?? deg.toString();
        _drawText(
          canvas,
          label,
          Offset(x, tapeTop + tapeHeight - 16),
          tokens.hudFontFamily,
          tokens.hudFontSize - 2,
          hudColor,
          align: TextAlign.center,
        );
      }
    }

    // Bearing diamond at center of strip
    final cx = size.width / 2;
    final bearing = data.bearingDeg;
    if (bearing != null) {
      // Check if bearing is within the visible arc
      var delta = bearing - headingDeg;
      // Normalize to -180..180
      while (delta > 180) { delta -= 360; }
      while (delta < -180) { delta += 360; }
      final onScreen = delta.abs() <= visibleArc / 2;
      final diamondColor = onScreen ? hudColor : tokens.hudWarning;

      if (onScreen) {
        // Position diamond on the tape based on delta from heading
        final diamondX = cx + (delta / (visibleArc / 2)) * (size.width / 2);
        _drawDiamond(canvas, diamondX, tapeTop + tapeHeight / 2, 5, diamondColor);
      } else {
        // Clamp to edge of strip and show numeric value
        final atRight = delta > 0;
        final diamondX = atRight ? size.width - 8.0 : 8.0;
        _drawDiamond(canvas, diamondX, tapeTop + tapeHeight / 2, 5, diamondColor);
        // Show bearing value beside the diamond
        final brgText = '${bearing.round()}°';
        _drawText(
          canvas,
          brgText,
          Offset(atRight ? diamondX - 10 : diamondX + 10, tapeTop + tapeHeight / 2 - 6),
          tokens.hudFontFamily,
          tokens.hudFontSize - 2,
          diamondColor,
          align: atRight ? TextAlign.right : TextAlign.left,
        );
      }
    }

    // Heading triangle (upward, at bottom of strip)
    final notchBottom = tapeTop + tapeHeight;
    final notchPath = Path()
      ..moveTo(cx - 6, notchBottom)
      ..lineTo(cx + 6, notchBottom)
      ..lineTo(cx, notchBottom - 8)
      ..close();
    canvas.drawPath(notchPath, Paint()..color = hudColor);

    // Current heading text below tape
    _drawText(
      canvas,
      '${headingDeg.round()}°',
      Offset(cx, notchBottom + 2),
      tokens.hudFontFamily,
      tokens.hudFontSize,
      hudColor,
      align: TextAlign.center,
    );
  }

  void _drawDiamond(Canvas canvas, double x, double y, double r, Color color) {
    final path = Path()
      ..moveTo(x, y - r)
      ..lineTo(x + r, y)
      ..lineTo(x, y + r)
      ..lineTo(x - r, y)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
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

    // Pitch diamond indicator — shows current pitch on the ladder
    const visibleRange = 30.0; // ladder shows ±30°
    final pitch = pitchDeg;
    final pitchInRange = pitch.abs() <= visibleRange;
    final pitchDiamondColor = pitchInRange ? hudColor : tokens.hudWarning;

    if (pitchInRange) {
      final dy = centerY - pitch * pxPerDeg;
      _drawDiamond(canvas, xOffset, dy, 4, pitchDiamondColor);
    } else {
      // Clamp to top or bottom of ladder and show value
      final atTop = pitch > 0;
      final dy = atTop
          ? centerY - visibleRange * pxPerDeg
          : centerY + visibleRange * pxPerDeg;
      _drawDiamond(canvas, xOffset, dy, 4, pitchDiamondColor);
      final pitchText = '${pitch.round()}°';
      _drawText(
        canvas,
        pitchText,
        Offset(xOffset + 10, dy - 5),
        tokens.hudFontFamily,
        tokens.hudFontSize - 2,
        pitchDiamondColor,
      );
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

    // Left column background (4 rows: LAT, LON, ALT, HDG)
    final leftRect =
        Rect.fromLTWH(margin, bottomY, colWidth, 4 * rowHeight + 2 * padding);
    canvas.drawRect(
        leftRect, Paint()..color = tokens.hudBackground.withValues(alpha: 0.3));
    canvas.drawRect(
        leftRect,
        Paint()
          ..color = const Color(0xBFC0C0C0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0);

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
        canvas, 'HDG', data.headingDeg != null ? '${data.headingDeg!.round()}°' : '--', leftX, y);

    // Right column background (3 rows: VEL, TRK, SRC)
    final rightRect3 = Rect.fromLTWH(size.width - margin - colWidth, bottomY,
        colWidth, 3 * rowHeight + 2 * padding);
    canvas.drawRect(rightRect3,
        Paint()..color = tokens.hudBackground.withValues(alpha: 0.3));
    canvas.drawRect(
        rightRect3,
        Paint()
          ..color = const Color(0xBFC0C0C0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0);

    // Right column data
    final rightX = size.width - margin - colWidth + padding;
    y = bottomY + padding;

    final velText = data.velocityKmS != null
        ? '${data.velocityKmS!.toStringAsFixed(2)} km/s'
        : '--';
    _drawLabelValue(canvas, 'VEL', velText, rightX, y);
    y += rowHeight;

    final trkText = data.bearingDeg != null
        ? '${data.bearingDeg!.round()}°'
        : '--';
    _drawLabelValue(canvas, 'TRK', trkText, rightX, y);
    y += rowHeight;

    // SRC with connectivity dot (bottom of right column)
    _drawSrcWithDot(canvas, rightX, y);
  }

  void _drawSrcWithDot(Canvas canvas, double x, double y) {
    // Label
    _drawText(canvas, 'SRC ', Offset(x, y), tokens.hudFontFamily,
        tokens.hudFontSize - 2, tokens.hudSecondary);
    // Colored dot indicating connectivity/source
    final dotColor = _sourceColor(data.sourceType);
    canvas.drawCircle(
      Offset(x + 34, y + tokens.hudFontSize / 2),
      4,
      Paint()..color = dotColor,
    );
    // Source text
    _drawText(canvas, _sourceLabel(data.sourceType), Offset(x + 42, y),
        tokens.hudFontFamily, tokens.hudFontSize, hudColor);
  }

  Color _sourceColor(PositionSourceType? type) => switch (type) {
        PositionSourceType.live => const Color(0xFF4CAF50),
        PositionSourceType.estimated => const Color(0xFFFFC107),
        PositionSourceType.gps => const Color(0xFF2196F3),
        PositionSourceType.static => tokens.hudSecondary,
        null => tokens.hudSecondary,
      };

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

  static String _sourceLabel(PositionSourceType? type) => switch (type) {
        PositionSourceType.live => 'ISS',
        PositionSourceType.estimated => 'TLE',
        PositionSourceType.gps => 'GPS',
        PositionSourceType.static => 'STATIC',
        null => '--',
      };

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
