/// Device orientation model (TECH_SPEC §9.2).
///
/// Immutable snapshot of the fused device orientation from the
/// complementary filter in [SensorFusionEngine].
class DeviceOrientation {
  /// Heading from magnetic north, 0–360 degrees clockwise.
  final double headingDeg;

  /// Pitch: -90 (face down) to +90 (face up / skyward).
  final double pitchDeg;

  /// Roll: -180 to +180 degrees.
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
