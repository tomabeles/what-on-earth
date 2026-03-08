import 'dart:async';
import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

import 'calibration.dart';
import 'device_orientation.dart';

// Re-export DeviceOrientation so existing imports of sensor_fusion.dart
// continue to resolve the type.
export 'device_orientation.dart';

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

/// Backwards-compatible alias for [DeviceOrientation].
typedef OrientationSample = DeviceOrientation;

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

/// Apply hard-iron correction to a raw magnetometer sample.
RawSensorSample applyHardIronCorrection(
  RawSensorSample mag,
  List<double> hardIron,
) {
  return RawSensorSample(
    x: mag.x - hardIron[0],
    y: mag.y - hardIron[1],
    z: mag.z - hardIron[2],
    timestamp: mag.timestamp,
  );
}

/// Apply one step of the complementary filter.
///
/// Pure function for testability. All angles in degrees.
///
/// [prev] may be null for the first sample (uses accel/mag reference directly).
/// [dt] is the time delta in seconds since the previous sample.
DeviceOrientation applyFilter({
  required DeviceOrientation? prev,
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
    return DeviceOrientation(
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

  return DeviceOrientation(
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

/// Fired when magnetometer interference is detected (WOE-021).
class MagnetometerInterferenceEvent {
  final DateTime timestamp;
  const MagnetometerInterferenceEvent({required this.timestamp});
}

/// Threshold in degrees for detecting magnetometer interference.
/// A heading change > 30° between consecutive 50 Hz samples implies
/// >1500°/s rotation — physically impossible from device motion.
const double kInterferenceThresholdDeg = 30.0;

/// Number of consecutive stable readings required to clear interference.
const int kStableSamplesToRecover = 5;

class SensorFusionEngine {
  final StreamController<DeviceOrientation> _controller =
      StreamController<DeviceOrientation>.broadcast();

  final StreamController<MagnetometerInterferenceEvent> _interferenceController =
      StreamController<MagnetometerInterferenceEvent>.broadcast();

  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<MagnetometerEvent>? _magSub;

  RawSensorSample? _lastAccel;
  RawSensorSample? _lastMag;
  DeviceOrientation? _lastOrientation;
  DateTime? _lastGyroTimestamp;

  /// Current hard-iron calibration offsets. Updated live via
  /// [updateCalibration] without restarting the engine.
  CalibrationParams? _calibration;

  bool _running = false;
  bool _interferenceDetected = false;
  int _stableCount = 0;

  /// Stream of fused orientation samples at ~50 Hz.
  Stream<DeviceOrientation> get orientationStream => _controller.stream;

  /// Fires when magnetometer interference is detected.
  Stream<MagnetometerInterferenceEvent> get interferenceEvents =>
      _interferenceController.stream;

  /// Whether the engine is currently running.
  bool get isRunning => _running;

  /// Start subscribing to sensors and emitting orientation samples.
  ///
  /// If [calibrationStore] is provided, loads saved calibration params
  /// on startup.
  Future<void> start({CalibrationStore? calibrationStore}) async {
    if (_running) return;
    _running = true;

    if (calibrationStore != null) {
      _calibration = await calibrationStore.load();
    }

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

  /// Update calibration params at runtime (e.g. after recalibration).
  /// Takes effect on the next sensor sample — no engine restart required.
  void updateCalibration(CalibrationParams params) {
    _calibration = params;
  }

  void _onGyro(GyroscopeEvent event) {
    final accel = _lastAccel;
    var mag = _lastMag;
    if (accel == null || mag == null) return;

    // Apply hard-iron correction if calibration is available
    final cal = _calibration;
    if (cal != null) {
      mag = applyHardIronCorrection(mag, cal.hardIron);
    }

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

    // Interference detection: check heading delta (WOE-021)
    final prev = _lastOrientation;
    if (prev != null) {
      var delta = (sample.headingDeg - prev.headingDeg).abs();
      if (delta > 180) delta = 360 - delta; // handle wrap-around
      if (delta > kInterferenceThresholdDeg) {
        _interferenceDetected = true;
        _stableCount = 0;
        _interferenceController.add(
          MagnetometerInterferenceEvent(timestamp: sample.timestamp),
        );
      } else if (_interferenceDetected) {
        _stableCount++;
        if (_stableCount >= kStableSamplesToRecover) {
          _interferenceDetected = false;
          _stableCount = 0;
        }
      }
    }

    final oriented = DeviceOrientation(
      headingDeg: sample.headingDeg,
      pitchDeg: sample.pitchDeg,
      rollDeg: sample.rollDeg,
      reliable: !_interferenceDetected,
      timestamp: sample.timestamp,
    );

    _lastOrientation = oriented;
    _controller.add(oriented);
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
    _interferenceDetected = false;
    _stableCount = 0;
  }

  /// Release resources. Engine cannot be restarted after disposal.
  Future<void> dispose() async {
    await stop();
    await _controller.close();
    await _interferenceController.close();
  }
}
