import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import 'orientation_corrections.dart';

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

/// Downsample target for processing speed.
const int kTargetWidth = 80;
const int kTargetHeight = 60;

/// Sobel magnitude threshold for edge classification.
const double kSobelThreshold = 40.0;

/// RANSAC parameters.
const int kRansacIterations = 100;
const double kRansacInlierThreshold = 3.0; // pixels in downsampled image
const int kMinEdgePoints = 20;
const double kMinInlierRatio = 0.3;

/// Minimum interval between frame processing (≈2 Hz).
const Duration kProcessingInterval = Duration(milliseconds: 500);

/// Approximate horizontal field of view of a typical phone camera.
const double kDefaultHFovDeg = 60.0;

// ---------------------------------------------------------------------------
// Detected circle model
// ---------------------------------------------------------------------------

/// A circle detected in the downsampled image.
class DetectedCircle {
  final double cx;
  final double cy;
  final double radius;
  final double inlierRatio;
  final int inlierCount;

  const DetectedCircle({
    required this.cx,
    required this.cy,
    required this.radius,
    required this.inlierRatio,
    required this.inlierCount,
  });

  @override
  String toString() =>
      'DetectedCircle(cx=${cx.toStringAsFixed(1)}, cy=${cy.toStringAsFixed(1)}, '
      'r=${radius.toStringAsFixed(1)}, inliers=$inlierCount/${(inlierCount / inlierRatio).round()})';
}

// ---------------------------------------------------------------------------
// Pipeline: CameraImage → HorizonCorrection
// ---------------------------------------------------------------------------

/// Process a camera frame to detect a circular edge.
///
/// Works with Earth's horizon in orbit, or any circular object (globe,
/// beach ball) for ground testing.
///
/// Pipeline: YUV luminance → downsample → Sobel edge → RANSAC circle fit.
HorizonCorrection? detectHorizon(CameraImage image) {
  final luminance = _extractAndDownsample(image);
  if (luminance == null) return null;

  return detectHorizonFromLuminance(
    luminance.data,
    luminance.width,
    luminance.height,
  );
}

/// Process a raw luminance buffer (for testing without a camera).
HorizonCorrection? detectHorizonFromLuminance(
  Uint8List luminance,
  int width,
  int height,
) {
  final edges = sobelEdgeDetect(luminance, width, height);
  final edgePoints = extractEdgePoints(edges, width, height);
  if (edgePoints.length < kMinEdgePoints) return null;

  final circle = ransacCircleFit(edgePoints, width, height);
  if (circle == null) return null;

  return circleToCorrection(circle, width: width, height: height);
}

// ---------------------------------------------------------------------------
// Step 1: Luminance extraction + downsampling
// ---------------------------------------------------------------------------

class _LuminanceImage {
  final Uint8List data;
  final int width;
  final int height;
  _LuminanceImage(this.data, this.width, this.height);
}

_LuminanceImage? _extractAndDownsample(CameraImage image) {
  if (image.planes.isEmpty) return null;

  final yPlane = image.planes[0];
  final srcWidth = image.width;
  final srcHeight = image.height;
  if (srcWidth == 0 || srcHeight == 0) return null;

  final scaleX = srcWidth / kTargetWidth;
  final scaleY = srcHeight / kTargetHeight;
  final dst = Uint8List(kTargetWidth * kTargetHeight);
  final yBytes = yPlane.bytes;
  final yRowStride = yPlane.bytesPerRow;

  for (var dy = 0; dy < kTargetHeight; dy++) {
    final sy = (dy * scaleY).floor().clamp(0, srcHeight - 1);
    for (var dx = 0; dx < kTargetWidth; dx++) {
      final sx = (dx * scaleX).floor().clamp(0, srcWidth - 1);
      dst[dy * kTargetWidth + dx] = yBytes[sy * yRowStride + sx];
    }
  }

  return _LuminanceImage(dst, kTargetWidth, kTargetHeight);
}

// ---------------------------------------------------------------------------
// Step 2: Sobel edge detection
// ---------------------------------------------------------------------------

/// Apply Sobel edge detection to a luminance image.
///
/// Returns a gradient magnitude buffer (Float32List) of the same dimensions.
@visibleForTesting
Float32List sobelEdgeDetect(Uint8List luminance, int width, int height) {
  final mag = Float32List(width * height);

  for (var y = 1; y < height - 1; y++) {
    for (var x = 1; x < width - 1; x++) {
      final tl = luminance[(y - 1) * width + (x - 1)].toDouble();
      final tc = luminance[(y - 1) * width + x].toDouble();
      final tr = luminance[(y - 1) * width + (x + 1)].toDouble();
      final ml = luminance[y * width + (x - 1)].toDouble();
      final mr = luminance[y * width + (x + 1)].toDouble();
      final bl = luminance[(y + 1) * width + (x - 1)].toDouble();
      final bc = luminance[(y + 1) * width + x].toDouble();
      final br = luminance[(y + 1) * width + (x + 1)].toDouble();

      final gx = -tl + tr - 2 * ml + 2 * mr - bl + br;
      final gy = -tl - 2 * tc - tr + bl + 2 * bc + br;

      mag[y * width + x] = math.sqrt(gx * gx + gy * gy);
    }
  }

  return mag;
}

// ---------------------------------------------------------------------------
// Step 3: Edge point extraction
// ---------------------------------------------------------------------------

/// Extract pixel coordinates where edge magnitude exceeds the threshold.
@visibleForTesting
List<(double, double)> extractEdgePoints(
  Float32List magnitude,
  int width,
  int height,
) {
  final points = <(double, double)>[];
  for (var y = 1; y < height - 1; y++) {
    for (var x = 1; x < width - 1; x++) {
      if (magnitude[y * width + x] > kSobelThreshold) {
        points.add((x.toDouble(), y.toDouble()));
      }
    }
  }
  return points;
}

// ---------------------------------------------------------------------------
// Step 4: RANSAC circle fitting
// ---------------------------------------------------------------------------

/// Fit the best circle through the given edge points using RANSAC.
///
/// Returns null if no circle meets the minimum inlier ratio.
@visibleForTesting
DetectedCircle? ransacCircleFit(
  List<(double, double)> points,
  int width,
  int height, {
  int? seed,
}) {
  if (points.length < 3) return null;

  final rng = math.Random(seed ?? 42);
  DetectedCircle? best;

  final minRadius = math.min(width, height) * 0.1;
  final maxRadius = math.max(width, height) * 2.0;

  for (var iter = 0; iter < kRansacIterations; iter++) {
    final i0 = rng.nextInt(points.length);
    var i1 = rng.nextInt(points.length);
    while (i1 == i0) {
      i1 = rng.nextInt(points.length);
    }
    var i2 = rng.nextInt(points.length);
    while (i2 == i0 || i2 == i1) {
      i2 = rng.nextInt(points.length);
    }

    final circle = fitCircleThrough3(points[i0], points[i1], points[i2]);
    if (circle == null) continue;

    final (cx, cy, r) = circle;
    if (r < minRadius || r > maxRadius) continue;

    var inliers = 0;
    for (final p in points) {
      final dist = math.sqrt(
        (p.$1 - cx) * (p.$1 - cx) + (p.$2 - cy) * (p.$2 - cy),
      );
      if ((dist - r).abs() < kRansacInlierThreshold) {
        inliers++;
      }
    }

    final ratio = inliers / points.length;
    if (ratio < kMinInlierRatio) continue;

    if (best == null || inliers > best.inlierCount) {
      best = DetectedCircle(
        cx: cx,
        cy: cy,
        radius: r,
        inlierRatio: ratio,
        inlierCount: inliers,
      );
    }
  }

  return best;
}

/// Algebraic circle through 3 points. Returns `(cx, cy, radius)` or null
/// if the points are collinear.
@visibleForTesting
(double, double, double)? fitCircleThrough3(
  (double, double) p0,
  (double, double) p1,
  (double, double) p2,
) {
  final (ax, ay) = p0;
  final (bx, by) = p1;
  final (cx, cy) = p2;

  final d = 2 * (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by));
  if (d.abs() < 1e-10) return null;

  final ux = ((ax * ax + ay * ay) * (by - cy) +
          (bx * bx + by * by) * (cy - ay) +
          (cx * cx + cy * cy) * (ay - by)) /
      d;
  final uy = ((ax * ax + ay * ay) * (cx - bx) +
          (bx * bx + by * by) * (ax - cx) +
          (cx * cx + cy * cy) * (bx - ax)) /
      d;

  final r = math.sqrt((ax - ux) * (ax - ux) + (ay - uy) * (ay - uy));
  return (ux, uy, r);
}

// ---------------------------------------------------------------------------
// Step 5: Circle → orientation correction
// ---------------------------------------------------------------------------

/// Convert a detected circle to pitch/roll corrections based on its offset
/// from the image center.
@visibleForTesting
HorizonCorrection? circleToCorrection(
  DetectedCircle circle, {
  int width = kTargetWidth,
  int height = kTargetHeight,
  double hFovDeg = kDefaultHFovDeg,
}) {
  final centerX = width / 2.0;
  final centerY = height / 2.0;

  // Offset from image center, normalized to [-1, 1]
  final offsetX = (circle.cx - centerX) / centerX;
  final offsetY = (circle.cy - centerY) / centerY;

  final vFovDeg = hFovDeg * height / width;

  // Circle below center → device tilted up → positive pitch correction
  final pitchCorrection = -offsetY * (vFovDeg / 2.0);
  // Circle right of center → device rolled left → positive roll correction
  final rollCorrection = -offsetX * (hFovDeg / 2.0);

  final normalizedRadius = circle.radius / math.max(width, height);

  return HorizonCorrection(
    pitchDeg: pitchCorrection,
    rollDeg: rollCorrection,
    confidence: circle.inlierRatio,
    timestamp: DateTime.now(),
    normalizedRadius: normalizedRadius,
  );
}

// ---------------------------------------------------------------------------
// HorizonDetectorEngine — manages camera stream + throttled processing
// ---------------------------------------------------------------------------

/// Processes camera frames at ~2 Hz to detect circular edges and produce
/// [HorizonCorrection]s.
///
/// Usage:
/// ```dart
/// final detector = HorizonDetectorEngine();
/// await detector.start(cameraController);
/// detector.correctionStream.listen((correction) { ... });
/// await detector.stop();
/// ```
class HorizonDetectorEngine {
  final _controller = StreamController<HorizonCorrection>.broadcast();
  DateTime _lastProcessed = DateTime.fromMillisecondsSinceEpoch(0);
  bool _processing = false;
  bool _running = false;

  /// Stream of horizon corrections at ~2 Hz.
  Stream<HorizonCorrection> get correctionStream => _controller.stream;

  /// Most recent correction (may be null if none detected yet).
  HorizonCorrection? lastCorrection;

  /// Whether the engine is actively processing frames.
  bool get isRunning => _running;

  /// Start processing camera frames for horizon detection.
  void start(CameraController camera) {
    if (_running) return;
    _running = true;
    camera.startImageStream(_onCameraImage);
  }

  void _onCameraImage(CameraImage image) {
    if (!_running || _processing) return;

    final now = DateTime.now();
    if (now.difference(_lastProcessed) < kProcessingInterval) return;

    _processing = true;
    _lastProcessed = now;

    // Process in a compute isolate to avoid jank
    compute(_processFrame, _FrameData.fromImage(image)).then((correction) {
      _processing = false;
      if (!_running) return;
      if (correction != null) {
        lastCorrection = correction;
        _controller.add(correction);
      }
    }).catchError((_) {
      _processing = false;
    });
  }

  /// Stop processing and release the image stream.
  Future<void> stop(CameraController camera) async {
    if (!_running) return;
    _running = false;
    try {
      await camera.stopImageStream();
    } catch (_) {
      // Camera may already be disposed
    }
  }

  /// Release resources.
  Future<void> dispose() async {
    _running = false;
    await _controller.close();
  }
}

// ---------------------------------------------------------------------------
// Isolate-safe frame data
// ---------------------------------------------------------------------------

/// Serializable frame data that can be sent to a compute isolate.
class _FrameData {
  final Uint8List yPlane;
  final int yRowStride;
  final int width;
  final int height;

  _FrameData({
    required this.yPlane,
    required this.yRowStride,
    required this.width,
    required this.height,
  });

  factory _FrameData.fromImage(CameraImage image) {
    return _FrameData(
      yPlane: Uint8List.fromList(image.planes[0].bytes),
      yRowStride: image.planes[0].bytesPerRow,
      width: image.width,
      height: image.height,
    );
  }
}

/// Top-level function for compute isolate — processes a single frame.
HorizonCorrection? _processFrame(_FrameData data) {
  if (data.width == 0 || data.height == 0) return null;

  // Downsample
  final scaleX = data.width / kTargetWidth;
  final scaleY = data.height / kTargetHeight;
  final dst = Uint8List(kTargetWidth * kTargetHeight);

  for (var dy = 0; dy < kTargetHeight; dy++) {
    final sy = (dy * scaleY).floor().clamp(0, data.height - 1);
    for (var dx = 0; dx < kTargetWidth; dx++) {
      final sx = (dx * scaleX).floor().clamp(0, data.width - 1);
      dst[dy * kTargetWidth + dx] = data.yPlane[sy * data.yRowStride + sx];
    }
  }

  return detectHorizonFromLuminance(dst, kTargetWidth, kTargetHeight);
}
