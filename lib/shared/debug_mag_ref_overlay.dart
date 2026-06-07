import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sensors/sensor_fusion.dart';
import '../sensors/sensor_fusion_provider.dart';
import 'debug_provider.dart';
import 'theme.dart';

const double _deg2rad = math.pi / 180.0;

/// Debug overlay rendering a 3D arrow toward magnetic north at screen center.
///
/// The raw magnetometer vector is rotated by the device's fused orientation
/// and projected orthographically, showing which direction the field points
/// relative to the current view.
class DebugMagRefOverlay extends ConsumerWidget {
  const DebugMagRefOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(debugProvider).showMagRef) {
      return const SizedBox.shrink();
    }

    final ori = ref.watch(orientationStreamProvider);
    final engine = ref.read(sensorFusionEngineProvider);
    final tokens = Theme.of(context).extension<AppTokens>()!;

    final data = ori.value;
    return CustomPaint(
      size: Size.infinite,
      painter: _MagRefPainter(
        mag: engine.lastRawMag,
        headingDeg: data?.headingDeg ?? 0,
        pitchDeg: data?.pitchDeg ?? 90,
        rollDeg: data?.rollDeg ?? 0,
        tokens: tokens,
      ),
    );
  }
}

class _MagRefPainter extends CustomPainter {
  _MagRefPainter({
    required this.mag,
    required this.headingDeg,
    required this.pitchDeg,
    required this.rollDeg,
    required this.tokens,
  });

  final RawSensorSample? mag;
  final double headingDeg;
  final double pitchDeg;
  final double rollDeg;
  final AppTokens tokens;

  static const _arrowLength = 80.0;
  static const _headSize = 10.0;

  @override
  void paint(Canvas canvas, Size size) {
    final m = mag;
    if (m == null) return;

    final mMag =
        math.sqrt(m.x * m.x + m.y * m.y + m.z * m.z);
    if (mMag < 1e-6) return;

    // Normalize magnetometer vector
    final nx = m.x / mMag, ny = m.y / mMag, nz = m.z / mMag;

    // Build the same rotation matrix as the coord axis overlay
    final yaw = headingDeg * _deg2rad;
    final pitch = (pitchDeg - 90.0) * _deg2rad;
    final roll = rollDeg * _deg2rad;

    final sy = math.sin(yaw), cy = math.cos(yaw);
    final sp = math.sin(pitch), cp = math.cos(pitch);
    final sr = math.sin(roll), cr = math.cos(roll);

    // R = Rz(yaw) * Rx(pitch) * Ry(roll)
    final r00 = cy * cr + sy * sp * sr;
    final r01 = -cy * sr + sy * sp * cr;
    final r02 = sy * cp;
    final r10 = cp * sr;
    final r11 = cp * cr;
    final r12 = -sp;

    // Project mag vector: p = R * n, take (px, py)
    final px = r00 * nx + r01 * ny + r02 * nz;
    final py = r10 * nx + r11 * ny + r12 * nz;

    final center = Offset(size.width / 2, size.height / 2);
    final tip = Offset(
      center.dx + px * _arrowLength,
      center.dy - py * _arrowLength, // flip Y for canvas
    );

    final color = tokens.hudPrimary;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Arrow shaft
    canvas.drawLine(center, tip, paint);

    // Arrowhead — small triangle at the tip
    final dx = tip.dx - center.dx;
    final dy = tip.dy - center.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 1) return;

    final ux = dx / len, uy = dy / len;
    // Perpendicular
    final px2 = -uy, py2 = ux;

    final base1 = Offset(
      tip.dx - ux * _headSize + px2 * _headSize * 0.4,
      tip.dy - uy * _headSize + py2 * _headSize * 0.4,
    );
    final base2 = Offset(
      tip.dx - ux * _headSize - px2 * _headSize * 0.4,
      tip.dy - uy * _headSize - py2 * _headSize * 0.4,
    );

    final headPath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(base1.dx, base1.dy)
      ..lineTo(base2.dx, base2.dy)
      ..close();
    canvas.drawPath(headPath, Paint()..color = color);

    // Label "N" near the tip
    final labelOffset = Offset(
      tip.dx + ux * 8,
      tip.dy + uy * 8 - 6,
    );
    final tp = TextPainter(
      text: TextSpan(
        text: 'N',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontFamily: tokens.hudFontFamily,
          fontWeight: FontWeight.bold,
          shadows: const [Shadow(blurRadius: 4, color: Colors.black)],
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp.paint(canvas, labelOffset);
  }

  @override
  bool shouldRepaint(_MagRefPainter oldDelegate) => true;
}
