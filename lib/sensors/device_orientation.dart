/// Device orientation model (SENSOR_FUSION_SPEC).
///
/// Immutable snapshot of the fused device orientation from the
/// complementary filter in [SensorFusionEngine].
class DeviceOrientation {
  /// Heading from magnetic north, 0–360 degrees clockwise.
  final double headingDeg;

  /// Pitch: angle of the camera from nadir.
  /// 0° = nadir (camera straight down), 90° = horizon,
  /// 180° = zenith (camera straight up).
  final double pitchDeg;

  /// Roll: left-right tilt around the camera axis.
  /// 0° = level, positive = right ear down, negative = left ear down.
  /// Range: -180° to +180°.
  final double rollDeg;

  /// Whether the magnetometer data appears trustworthy.
  final bool reliable;

  final DateTime timestamp;

  const DeviceOrientation({
    required this.headingDeg,
    required this.pitchDeg,
    required this.rollDeg,
    required this.reliable,
    required this.timestamp,
  });

  /// Serialize for the bridge `UPDATE_ORIENTATION` payload.
  Map<String, dynamic> toJson() => {
        'heading': headingDeg,
        'pitch': pitchDeg,
        'roll': rollDeg,
        'reliable': reliable,
        'ts': timestamp.millisecondsSinceEpoch,
      };

  @override
  String toString() =>
      'DeviceOrientation(hdg=${headingDeg.toStringAsFixed(1)}, '
      'pch=${pitchDeg.toStringAsFixed(1)}, '
      'rol=${rollDeg.toStringAsFixed(1)}, '
      'reliable=$reliable)';
}
