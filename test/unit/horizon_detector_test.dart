import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:what_on_earth/sensors/horizon_detector.dart';
import 'package:what_on_earth/sensors/orientation_corrections.dart';

void main() {
  group('fitCircleThrough3', () {
    test('fits circle through 3 non-collinear points', () {
      // Points on a circle centered at (5, 5) with radius 5
      final p0 = (10.0, 5.0); // right
      final p1 = (5.0, 10.0); // top
      final p2 = (0.0, 5.0); // left

      final result = fitCircleThrough3(p0, p1, p2);
      expect(result, isNotNull);

      final (cx, cy, r) = result!;
      expect(cx, closeTo(5.0, 1e-6));
      expect(cy, closeTo(5.0, 1e-6));
      expect(r, closeTo(5.0, 1e-6));
    });

    test('returns null for collinear points', () {
      final p0 = (0.0, 0.0);
      final p1 = (1.0, 1.0);
      final p2 = (2.0, 2.0);

      expect(fitCircleThrough3(p0, p1, p2), isNull);
    });
  });

  group('sobelEdgeDetect', () {
    test('detects strong edges', () {
      // Create a 10x10 image: left half dark (0), right half bright (255)
      final width = 10;
      final height = 10;
      final luminance = Uint8List(width * height);
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          luminance[y * width + x] = x < 5 ? 0 : 255;
        }
      }

      final edges = sobelEdgeDetect(luminance, width, height);

      // Edge magnitude should be high near x=5 (the boundary)
      // and low far from it
      final edgeAtBoundary = edges[5 * width + 5]; // at the boundary
      final edgeAtCenter = edges[5 * width + 2]; // far from boundary

      expect(edgeAtBoundary, greaterThan(edgeAtCenter));
    });
  });

  group('extractEdgePoints', () {
    test('extracts points above threshold', () {
      final width = 5;
      final height = 5;
      final magnitude = Float32List(width * height);
      // Put a strong edge at (2, 2)
      magnitude[2 * width + 2] = 100.0;
      // And a weak edge at (3, 3)
      magnitude[3 * width + 3] = 10.0;

      final points = extractEdgePoints(magnitude, width, height);

      expect(points.length, equals(1));
      expect(points[0].$1, equals(2.0));
      expect(points[0].$2, equals(2.0));
    });
  });

  group('ransacCircleFit', () {
    test('finds a circle in clean data', () {
      // Generate points on a circle at (40, 30) with radius 20
      const cx = 40.0;
      const cy = 30.0;
      const r = 20.0;

      final points = <(double, double)>[];
      for (var i = 0; i < 50; i++) {
        final angle = i * 2 * math.pi / 50;
        points.add((cx + r * math.cos(angle), cy + r * math.sin(angle)));
      }

      final circle = ransacCircleFit(points, 80, 60);

      expect(circle, isNotNull);
      expect(circle!.cx, closeTo(cx, 1.0));
      expect(circle.cy, closeTo(cy, 1.0));
      expect(circle.radius, closeTo(r, 1.0));
      expect(circle.inlierRatio, greaterThan(0.8));
    });

    test('finds circle with noise', () {
      const cx = 40.0;
      const cy = 30.0;
      const r = 25.0;
      final rng = math.Random(123);

      final points = <(double, double)>[];
      // 40 circle points
      for (var i = 0; i < 40; i++) {
        final angle = i * 2 * math.pi / 40;
        points.add((
          cx + r * math.cos(angle) + (rng.nextDouble() - 0.5) * 2,
          cy + r * math.sin(angle) + (rng.nextDouble() - 0.5) * 2,
        ));
      }
      // 10 random noise points
      for (var i = 0; i < 10; i++) {
        points.add((rng.nextDouble() * 80, rng.nextDouble() * 60));
      }

      final circle = ransacCircleFit(points, 80, 60);

      expect(circle, isNotNull);
      expect(circle!.cx, closeTo(cx, 3.0));
      expect(circle.cy, closeTo(cy, 3.0));
      expect(circle.radius, closeTo(r, 3.0));
    });

    test('returns null for too few points', () {
      expect(ransacCircleFit([(1, 2)], 80, 60), isNull);
      expect(ransacCircleFit([], 80, 60), isNull);
    });
  });

  group('circleToCorrection', () {
    test('centered circle produces near-zero correction', () {
      final circle = DetectedCircle(
        cx: 40,
        cy: 30,
        radius: 20,
        inlierRatio: 0.8,
        inlierCount: 40,
      );

      final correction = circleToCorrection(circle);

      expect(correction, isNotNull);
      expect(correction!.pitchDeg.abs(), lessThan(1.0));
      expect(correction.rollDeg.abs(), lessThan(1.0));
    });

    test('off-center circle produces proportional correction', () {
      // Circle below center → device tilted up → positive pitch
      final circle = DetectedCircle(
        cx: 40, // centered horizontally
        cy: 50, // below center (center is 30)
        radius: 20,
        inlierRatio: 0.8,
        inlierCount: 40,
      );

      final correction = circleToCorrection(circle);

      expect(correction, isNotNull);
      // Circle below center → negative offsetY → positive pitch correction
      expect(correction!.pitchDeg, lessThan(0));
    });

    test('circle right of center produces roll correction', () {
      final circle = DetectedCircle(
        cx: 70, // right of center
        cy: 30, // centered vertically
        radius: 20,
        inlierRatio: 0.8,
        inlierCount: 40,
      );

      final correction = circleToCorrection(circle);

      expect(correction, isNotNull);
      expect(correction!.rollDeg, isNot(closeTo(0, 1.0)));
    });
  });

  group('detectHorizonFromLuminance', () {
    test('detects a bright circle on dark background', () {
      const width = 80;
      const height = 60;
      final luminance = Uint8List(width * height);

      // Draw a filled bright circle at center
      const cx = 40.0;
      const cy = 30.0;
      const r = 15.0;

      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final dx = x - cx;
          final dy = y - cy;
          final dist = math.sqrt(dx * dx + dy * dy);
          luminance[y * width + x] = dist <= r ? 200 : 20;
        }
      }

      final correction = detectHorizonFromLuminance(luminance, width, height);

      // Should detect the circle edge
      expect(correction, isNotNull);
      // Circle is centered, so corrections should be small
      expect(correction!.pitchDeg.abs(), lessThan(10.0));
      expect(correction.rollDeg.abs(), lessThan(10.0));
      expect(correction.confidence, greaterThan(0));
    });

    test('returns null for uniform image (no edges)', () {
      const width = 80;
      const height = 60;
      final luminance = Uint8List(width * height);
      // Fill with uniform value
      for (var i = 0; i < luminance.length; i++) {
        luminance[i] = 128;
      }

      final correction = detectHorizonFromLuminance(luminance, width, height);
      expect(correction, isNull);
    });

    test('detects off-center circle (simulates globe/beach ball)', () {
      const width = 80;
      const height = 60;
      final luminance = Uint8List(width * height);

      // Draw a bright circle offset to upper-left
      const cx = 25.0;
      const cy = 20.0;
      const r = 12.0;

      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final dx = x - cx;
          final dy = y - cy;
          final dist = math.sqrt(dx * dx + dy * dy);
          luminance[y * width + x] = dist <= r ? 180 : 30;
        }
      }

      final correction = detectHorizonFromLuminance(luminance, width, height);

      expect(correction, isNotNull);
      // Circle is left of center → should produce some roll correction
      expect(correction!.rollDeg.abs(), greaterThan(1.0));
    });
  });

  group('HorizonCorrection', () {
    test('isFresh checks timestamp', () {
      final fresh = HorizonCorrection(
        pitchDeg: 0,
        rollDeg: 0,
        confidence: 0.8,
        timestamp: DateTime.now(),
        normalizedRadius: 0.2,
      );
      expect(fresh.isFresh(), isTrue);

      final stale = HorizonCorrection(
        pitchDeg: 0,
        rollDeg: 0,
        confidence: 0.8,
        timestamp: DateTime.now().subtract(const Duration(seconds: 5)),
        normalizedRadius: 0.2,
      );
      expect(stale.isFresh(), isFalse);
    });
  });
}
