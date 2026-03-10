// Data models for orbital orientation correction sources.
//
// These corrections supplement or replace the accelerometer/magnetometer
// reference in SensorFusionEngine when operating in microgravity.

/// Correction derived from camera-based horizon/circle detection.
///
/// When the camera detects a circular edge (Earth's horizon in orbit,
/// or a test object like a globe/beach-ball on the ground), the center
/// offset from the image center provides pitch/roll corrections.
class HorizonCorrection {
  /// Pitch correction in degrees derived from the circle's vertical offset.
  final double pitchDeg;

  /// Roll correction in degrees derived from the circle's horizontal offset.
  final double rollDeg;

  /// Confidence 0–1 based on RANSAC inlier ratio.
  final double confidence;

  /// When this correction was computed.
  final DateTime timestamp;

  /// Radius of the detected circle in normalized image coordinates (0–1).
  final double normalizedRadius;

  const HorizonCorrection({
    required this.pitchDeg,
    required this.rollDeg,
    required this.confidence,
    required this.timestamp,
    required this.normalizedRadius,
  });

  /// Whether this correction is still fresh enough to use (< 2 seconds old).
  bool isFresh([DateTime? now]) =>
      (now ?? DateTime.now()).difference(timestamp).inMilliseconds < 2000;

  @override
  String toString() =>
      'HorizonCorrection(pitch=${pitchDeg.toStringAsFixed(1)}, '
      'roll=${rollDeg.toStringAsFixed(1)}, '
      'conf=${confidence.toStringAsFixed(2)}, '
      'r=${normalizedRadius.toStringAsFixed(3)})';
}

/// LVLH (Local Vertical Local Horizontal) reference frame computed from
/// orbital position telemetry.
///
/// In orbit, the "down" direction points from the spacecraft toward Earth's
/// center (nadir). This provides a gravity-like reference vector when the
/// accelerometer reads near-zero in microgravity.
class LvlhFrame {
  /// Nadir unit vector in ECEF (points from spacecraft toward Earth center).
  final (double x, double y, double z) nadirEcef;

  /// Velocity (along-track) unit vector in ECEF.
  final (double x, double y, double z) velocityEcef;

  /// Cross-track unit vector in ECEF (completes the right-handed frame).
  final (double x, double y, double z) crossTrackEcef;

  /// Expected pitch for nadir-pointing attitude (0° = looking straight down).
  final double referencePitchDeg;

  /// Expected roll for nadir-pointing attitude (0° = level).
  final double referenceRollDeg;

  /// Altitude in km — used to determine if we're in orbit.
  final double altKm;

  /// When this frame was computed.
  final DateTime timestamp;

  const LvlhFrame({
    required this.nadirEcef,
    required this.velocityEcef,
    required this.crossTrackEcef,
    required this.referencePitchDeg,
    required this.referenceRollDeg,
    required this.altKm,
    required this.timestamp,
  });

  /// Whether this position suggests orbital altitude (> 200 km).
  bool get isOrbital => altKm > 200;

  /// Whether this frame is still recent enough to use (< 30 seconds old).
  bool isFresh([DateTime? now]) =>
      (now ?? DateTime.now()).difference(timestamp).inSeconds < 30;

  @override
  String toString() =>
      'LvlhFrame(alt=${altKm.toStringAsFixed(0)}km, orbital=$isOrbital)';
}
