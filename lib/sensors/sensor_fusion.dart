import 'dart:async';
import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

/// Raw three-axis sample from a single sensor.
class RawSensorSample {
  final double x;
  final double y;
  final double z;
  final DateTime timestamp;

  const RawSensorSample({
    required this.x,
    required this.y,
    required this.z,
    required this.timestamp,
  });
}

/// Fused device orientation in degrees.
class OrientationSample {
  /// Heading from magnetic north, 0-360 degrees clockwise.
  final double headingDeg;

  /// Pitch: -90 (face down) to +90 (face up / skyward).
  final double pitchDeg;

  /// Roll: -180 to +180 degrees.
  final double rollDeg;

  /// Whether the magnetometer data appears trustworthy.
  final bool reliable;

  final DateTime timestamp;

  const OrientationSample({
    required this.headingDeg,
    required this.pitchDeg,
    required this.rollDeg,
    required this.reliable,
    required this.timestamp,
  });

  @override
  String toString() =>
      'OrientationSample(hdg=${headingDeg.toStringAsFixed(1)}, '
      'pch=${pitchDeg.toStringAsFixed(1)}, '
      'rol=${rollDeg.toStringAsFixed(1)}, '
      'reliable=$reliable)';
}

// ---------------------------------------------------------------------------
// Complementary filter — pure function (TECH_SPEC §7.2)
// ---------------------------------------------------------------------------

/// Complementary filter coefficient. 0.98 = trust gyro 98% for short-term,
/// accelerometer/magnetometer 2% for long-term drift correction.
const double kFilterAlpha = 0.98;

const double _rad2deg = 180.0 / math.pi;
const double _deg2rad = math.pi / 180.0;

/// Compute accelerometer-derived pitch and roll (reference orientation).
///
/// Returns `(pitchRad, rollRad)`.
(double, double) accelPitchRoll(RawSensorSample accel) {
  final ax = accel.x;
  final ay = accel.y;
  final az = accel.z;
  final pitchRad = math.atan2(-ax, math.sqrt(ay * ay + az * az));
  final rollRad = math.atan2(ay, az);
  return (pitchRad, rollRad);
}

/// Compute tilt-compensated heading from magnetometer and known pitch/roll.
///
/// Returns heading in radians (0 to 2π, clockwise from magnetic north).
double tiltCompensatedHeading(
  RawSensorSample mag,
  double pitchRad,
  double rollRad,
) {
  final mx = mag.x;
  final my = mag.y;
  final mz = mag.z;

  final cosPitch = math.cos(pitchRad);
  final sinPitch = math.sin(pitchRad);
  final cosRoll = math.cos(rollRad);
  final sinRoll = math.sin(rollRad);

  // Tilt compensation
  final mxComp = mx * cosPitch + mz * sinPitch;
  final myComp = mx * sinRoll * sinPitch + my * cosRoll - mz * sinRoll * cosPitch;

  var headingRad = math.atan2(-myComp, mxComp);
  if (headingRad < 0) headingRad += 2 * math.pi;
  return headingRad;
}

/// Apply one step of the complementary filter.
///
/// Pure function for testability. All angles in degrees.
///
/// [prev] may be null for the first sample (uses accel/mag reference directly).
/// [dt] is the time delta in seconds since the previous sample.
OrientationSample applyFilter({
  required OrientationSample? prev,
  required RawSensorSample accel,
  required RawSensorSample mag,
  required RawSensorSample gyro,
  required double dt,
  required DateTime timestamp,
  double alpha = kFilterAlpha,
}) {
  // --- Reference orientation from accelerometer + magnetometer ---
  final (refPitchRad, refRollRad) = accelPitchRoll(accel);
  final refHeadingRad = tiltCompensatedHeading(mag, refPitchRad, refRollRad);

  final refPitchDeg = refPitchRad * _rad2deg;
  final refRollDeg = refRollRad * _rad2deg;
  final refHeadingDeg = refHeadingRad * _rad2deg;

  if (prev == null || dt <= 0) {
    // First sample — use accelerometer/magnetometer reference directly
    return OrientationSample(
      headingDeg: _wrapHeading(refHeadingDeg),
      pitchDeg: _clampPitch(refPitchDeg),
      rollDeg: _wrapRoll(refRollDeg),
      reliable: true,
      timestamp: timestamp,
    );
  }

  // --- Gyroscope integration (short-term) ---
  // sensors_plus gyro is in rad/s; integrate over dt.
  // Device axes: x = pitch rate, y = roll rate, z = yaw rate
  final gyroPitchDelta = gyro.x * _rad2deg * dt;
  final gyroRollDelta = gyro.y * _rad2deg * dt;
  final gyroYawDelta = gyro.z * _rad2deg * dt;

  final gyroPitch = prev.pitchDeg + gyroPitchDelta;
  final gyroRoll = prev.rollDeg + gyroRollDelta;
  final gyroHeading = prev.headingDeg - gyroYawDelta; // yaw: negative for CW

  // --- Complementary filter blend ---
  final fusedPitch = alpha * gyroPitch + (1 - alpha) * refPitchDeg;
  final fusedRoll = alpha * gyroRoll + (1 - alpha) * refRollDeg;
  final fusedHeading = _blendAngles(gyroHeading, refHeadingDeg, alpha);

  return OrientationSample(
    headingDeg: _wrapHeading(fusedHeading),
    pitchDeg: _clampPitch(fusedPitch),
    rollDeg: _wrapRoll(fusedRoll),
    reliable: true,
    timestamp: timestamp,
  );
}

/// Blend two angles (in degrees) accounting for the 0/360 wrap-around.
double _blendAngles(double a, double b, double alpha) {
  // Convert to radians for proper circular interpolation
  final aRad = a * _deg2rad;
  final bRad = b * _deg2rad;
  // Use atan2(sin, cos) trick for circular mean
  final sinBlend = alpha * math.sin(aRad) + (1 - alpha) * math.sin(bRad);
  final cosBlend = alpha * math.cos(aRad) + (1 - alpha) * math.cos(bRad);
  return math.atan2(sinBlend, cosBlend) * _rad2deg;
}

double _wrapHeading(double deg) {
  var h = deg % 360.0;
  if (h < 0) h += 360.0;
  return h;
}

double _clampPitch(double deg) => deg.clamp(-90.0, 90.0);

double _wrapRoll(double deg) {
  var r = deg;
  while (r > 180) {
    r -= 360;
  }
  while (r < -180) {
    r += 360;
  }
  return r;
}

// ---------------------------------------------------------------------------
// SensorFusionEngine — subscribes to sensors_plus, runs filter
// ---------------------------------------------------------------------------

// sensors_plus uses Flutter platform channels which require the main isolate.
// The complementary filter is lightweight arithmetic (~50 Hz × 3 multiplies)
// and does not warrant isolate overhead. If profiling shows a need, the pure
// applyFilter() function can be moved to a compute isolate (WOE-050).

class SensorFusionEngine {
  final StreamController<OrientationSample> _controller =
      StreamController<OrientationSample>.broadcast();

  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<MagnetometerEvent>? _magSub;

  RawSensorSample? _lastAccel;
  RawSensorSample? _lastMag;
  OrientationSample? _lastOrientation;
  DateTime? _lastGyroTimestamp;

  bool _running = false;

  /// Stream of fused orientation samples at ~50 Hz.
  Stream<OrientationSample> get orientationStream => _controller.stream;

  /// Whether the engine is currently running.
  bool get isRunning => _running;

  /// Start subscribing to sensors and emitting orientation samples.
  void start() {
    if (_running) return;
    _running = true;

    _accelSub = accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen((event) {
      _lastAccel = RawSensorSample(
        x: event.x,
        y: event.y,
        z: event.z,
        timestamp: event.timestamp,
      );
    });

    _magSub = magnetometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen((event) {
      _lastMag = RawSensorSample(
        x: event.x,
        y: event.y,
        z: event.z,
        timestamp: event.timestamp,
      );
    });

    // Gyroscope drives the filter tick — on each gyro sample, run the filter
    _gyroSub = gyroscopeEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen(_onGyro);
  }

  void _onGyro(GyroscopeEvent event) {
    final accel = _lastAccel;
    final mag = _lastMag;
    if (accel == null || mag == null) return;

    final now = event.timestamp;
    final dt = _lastGyroTimestamp != null
        ? now.difference(_lastGyroTimestamp!).inMicroseconds / 1e6
        : 0.0;
    _lastGyroTimestamp = now;

    final gyro = RawSensorSample(
      x: event.x,
      y: event.y,
      z: event.z,
      timestamp: now,
    );

    final sample = applyFilter(
      prev: _lastOrientation,
      accel: accel,
      mag: mag,
      gyro: gyro,
      dt: dt,
      timestamp: now,
    );

    _lastOrientation = sample;
    _controller.add(sample);
  }

  /// Stop all sensor subscriptions and close the output stream.
  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    await _accelSub?.cancel();
    await _gyroSub?.cancel();
    await _magSub?.cancel();
    _accelSub = null;
    _gyroSub = null;
    _magSub = null;
    _lastAccel = null;
    _lastMag = null;
    _lastOrientation = null;
    _lastGyroTimestamp = null;
  }

  /// Release resources. Engine cannot be restarted after disposal.
  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }
}
