import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sensors/sensor_fusion_provider.dart';
import 'debug_provider.dart';
import 'theme.dart';

const double _deg2rad = math.pi / 180.0;

/// Debug overlay rendering a 3D coordinate axis gizmo at screen center.
///
/// Red = X, Green = Y, Blue = Z. The axes rotate to reflect the device's
/// fused orientation (heading, pitch, roll).
class DebugCoordAxisOverlay extends ConsumerWidget {
  const DebugCoordAxisOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(debugProvider).showCoordAxis) {
      return const SizedBox.shrink();
    }

    final ori = ref.watch(orientationStreamProvider);
    final tokens = Theme.of(context).extension<AppTokens>()!;

    final data = ori.value;
    return CustomPaint(
      size: Size.infinite,
      painter: _CoordAxisPainter(
        headingDeg: data?.headingDeg ?? 0,
        pitchDeg: data?.pitchDeg ?? 90,
        rollDeg: data?.rollDeg ?? 0,
        tokens: tokens,
      ),
    );
  }
}

class _CoordAxisPainter extends CustomPainter {
  _CoordAxisPainter({
    required this.headingDeg,
    required this.pitchDeg,
    required this.rollDeg,
    required this.tokens,
  });

  final double headingDeg;
  final double pitchDeg;
  final double rollDeg;
  final AppTokens tokens;

  static const _axisLength = 60.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // --- Build rotation matrix from Euler angles (ZXY: yaw → pitch → roll) ---
    // Convert pitch from spec convention (0°=nadir, 90°=horizon) to standard
    // (0°=horizon, +90°=zenith, -90°=nadir).
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
    final r20 = -sy * cr + cy * sp * sr;
    final r21 = sy * sr + cy * sp * cr;
    final r22 = cy * cp;

    // Each column of R is the projected unit axis vector.
    // X-axis: (r00, r10, r20), Y-axis: (r01, r11, r21), Z-axis: (r02, r12, r22)
    // Orthographic projection: take (column[0], column[1]) for screen (x, y).
    // Canvas Y is inverted (down = positive), so negate the y component.

    final axes = <_Axis>[
      _Axis('X', r00, r10, r20, const Color(0xFFFF4040)),
      _Axis('Y', r01, r11, r21, const Color(0xFF40FF40)),
      _Axis('Z', r02, r12, r22, const Color(0xFF4080FF)),
    ];

    // Depth-sort: draw farthest first (smallest z') so nearer axes overlap.
    axes.sort((a, b) => a.z.compareTo(b.z));

    // Origin dot
    canvas.drawCircle(
      center,
      3,
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );

    for (final axis in axes) {
      final end = Offset(
        center.dx + axis.x * _axisLength,
        center.dy - axis.y * _axisLength, // flip Y
      );

      // Line
      canvas.drawLine(
        center,
        end,
        Paint()
          ..color = axis.color
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );

      // Label
      final labelOffset = Offset(
        center.dx + axis.x * (_axisLength + 10),
        center.dy - axis.y * (_axisLength + 10) - 5,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: axis.label,
          style: TextStyle(
            color: axis.color,
            fontSize: 10,
            fontFamily: tokens.hudFontFamily,
            fontWeight: FontWeight.bold,
            shadows: const [Shadow(blurRadius: 4, color: Colors.black)],
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, labelOffset);
    }
  }

  @override
  bool shouldRepaint(_CoordAxisPainter oldDelegate) => true;
}

class _Axis {
  const _Axis(this.label, this.x, this.y, this.z, this.color);
  final String label;
  final double x;
  final double y;
  final double z;
  final Color color;
}
