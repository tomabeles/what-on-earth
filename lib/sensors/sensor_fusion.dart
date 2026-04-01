import 'dart:async';
import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

import 'calibration.dart';
import 'device_orientation.dart';
import 'orientation_corrections.dart';

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
// Orientation mode — SENSOR_FUSION_SPEC §Sensor Axis Mapping
// ---------------------------------------------------------------------------

/// Device orientation mode determines how sensor axes map to pitch/yaw/roll.
///
/// The physical sensor axes (X, Y, Z) are hardware-fixed. Which axis
/// corresponds to "pitch change" vs "roll change" depends on whether the
/// device is locked to portrait or landscape.
enum OrientationMode {
  /// Portrait: X right, Y up, Z toward user.
  /// Gyro mapping: X→pitch, Y→yaw, Z→roll.
  portrait,

  /// Landscape: X up, Y right, Z toward user.
  /// Gyro mapping: Y→pitch, X→yaw, Z→roll (with sign adjustments).
  landscape,
}

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Complementary filter coefficient. 0.98 = trust gyro 98% for short-term,
/// accelerometer/magnetometer 2% for long-term drift correction.
const double kFilterAlpha = 0.98;

/// Higher alpha for orbit mode — almost pure gyro integration, since the
/// accelerometer reads near-zero in microgravity.
const double kOrbitGyroOnlyAlpha = 0.995;

/// Minimum horizon correction confidence to use for orientation reference.
const double kMinHorizonConfidence = 0.3;

/// Expected acceleration magnitude at rest (1g in m/s²).
const double _kGravity = 9.81;

/// Maximum allowable deviation from 1g before the filter suppresses the
/// accelerometer reference. 10% allows for normal sensor noise while
/// catching centripetal / linear acceleration from rotation or movement.
const double _kGravityDeviationThreshold = 0.10;

const double _rad2deg = 180.0 / math.pi;
const double _deg2rad = math.pi / 180.0;

// ---------------------------------------------------------------------------
// Pure functions — accelerometer reference
// ---------------------------------------------------------------------------

/// Compute the camera pitch from nadir using the accelerometer.
///
/// Convention (SENSOR_FUSION_SPEC):
///   0° = nadir (camera straight down)
///   90° = horizon
///   180° = zenith (camera straight up)
///
/// The camera points along the device -Z axis. This formula measures the
/// angle between -Z and the gravity direction, which is independent of
/// portrait vs landscape orientation.
///
/// Derivation: pitch = acos(az / |a|) = atan2(sqrt(ax²+ay²), az).
double accelPitch(RawSensorSample accel) {
  final ax = accel.x;
  final ay = accel.y;
  final az = accel.z;
  return math.atan2(math.sqrt(ax * ax + ay * ay), az) * _rad2deg;
}

/// Compute roll from the accelerometer.
///
/// Convention (SENSOR_FUSION_SPEC):
///   0° = level (gravity perpendicular to screen)
///   positive = right ear down
///   negative = left ear down
///
/// "Right" is a different device axis in portrait vs landscape, so the
/// formula depends on [mode].
double accelRoll(RawSensorSample accel, OrientationMode mode) {
  switch (mode) {
    case OrientationMode.portrait:
      // Portrait: "right" = +X, "up" = +Y.
      // atan2(ax, ay): positive when the +X side (right) drops (gravity
      // component along +X increases).
      return math.atan2(accel.x, accel.y) * _rad2deg;
    case OrientationMode.landscape:
      // Landscape: "right" = +Y, "up" = +X.
      return math.atan2(accel.y, accel.x) * _rad2deg;
  }
}

// ---------------------------------------------------------------------------
// Pure functions — magnetometer heading
// ---------------------------------------------------------------------------

/// Compute heading using vector projection — singularity-free at all pitches.
///
/// Projects the camera direction (-Z) and the magnetic field onto the
/// horizontal plane (perpendicular to gravity) and measures the CW angle
/// from magnetic north to the camera direction.
///
/// Unlike the classic tilt-compensated formula, this approach does NOT
/// depend on `atan2(ay, az)` for a roll angle, which is singular when
/// the phone is upright (ay ≈ 0, az ≈ 0). That singularity caused the
/// heading reference to flip ±180° from sensor noise.
///
/// When the camera points straight up or down (pitch near 0° or 180°),
/// the camera's horizontal projection vanishes. In that case we fall back
/// to the classic tilt-compensated formula, which is well-behaved at
/// those pitch angles.
///
/// Returns heading in degrees, 0–360, CW from magnetic north.
double vectorHeading(RawSensorSample accel, RawSensorSample mag) {
  // --- Up direction from gravity ---
  final ux = accel.x, uy = accel.y, uz = accel.z;
  final uMag = math.sqrt(ux * ux + uy * uy + uz * uz);
  if (uMag < 0.5) return 0; // degenerate (free-fall / microgravity)
  final unx = ux / uMag, uny = uy / uMag, unz = uz / uMag;

  // --- Magnetic east = normalize(mag × up) ---
  // (NOT up × mag — that gives west.)
  final ex = mag.y * unz - mag.z * uny;
  final ey = mag.z * unx - mag.x * unz;
  final ez = mag.x * uny - mag.y * unx;
  final eMag = math.sqrt(ex * ex + ey * ey + ez * ez);
  if (eMag < 1e-6) return 0; // degenerate (mag aligned with gravity)
  final enx = ex / eMag, eny = ey / eMag, enz = ez / eMag;

  // --- Magnetic north = up × east ---
  final nx = uny * enz - unz * eny;
  final ny = unz * enx - unx * enz;
  final nz = unx * eny - uny * enx;

  // --- Camera direction projected onto horizontal plane ---
  // camera = (0, 0, -1)
  final camDotUp = -unz; // (0,0,-1) · up
  final chx = 0.0 - camDotUp * unx; // = unz * unx
  final chy = 0.0 - camDotUp * uny; // = unz * uny
  final chz = -1.0 - camDotUp * unz; // = -(1 - unz²)
  final chMag = math.sqrt(chx * chx + chy * chy + chz * chz);

  if (chMag < 1e-4) {
    // Camera points along gravity (pitch near 0° or 180°).
    // Fall back to the classic tilt-compensated formula, which is
    // well-behaved at these pitches (singular only at pitch 90°).
    final pitchRad =
        math.atan2(-accel.x, math.sqrt(accel.y * accel.y + accel.z * accel.z));
    final rollRad = math.atan2(accel.y, accel.z);
    var h = tiltCompensatedHeading(mag, pitchRad, rollRad) * _rad2deg;
    if (h < 0) h += 360.0;
    return h;
  }

  // --- Heading = atan2(east component, north component) ---
  final eastComp = chx * enx + chy * eny + chz * enz;
  final northComp = chx * nx + chy * ny + chz * nz;
  var h = math.atan2(eastComp, northComp) * _rad2deg;
  if (h < 0) h += 360.0;
  return h;
}

/// Legacy tilt-compensated heading — kept for reference and tests.
///
/// WARNING: This has a singularity when the phone is upright (ay ≈ 0,
/// az ≈ 0). Prefer [vectorHeading] for production use.
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

  final mxComp = mx * cosPitch + mz * sinPitch;
  final myComp =
      mx * sinRoll * sinPitch + my * cosRoll - mz * sinRoll * cosPitch;

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

// ---------------------------------------------------------------------------
// Pure function — complementary filter (SENSOR_FUSION_SPEC §Complementary
// Filter Behavior)
// ---------------------------------------------------------------------------

/// Apply one step of the complementary filter.
///
/// Pure function for testability. All output angles in degrees.
///
/// [prev] may be null for the first sample (uses accel/mag reference
/// directly). [dt] is the time delta in seconds since the previous sample.
///
/// [mode] selects portrait or landscape gyro axis mapping.
///
/// In orbit mode, the accelerometer reads near-zero. Optional corrections:
/// - [horizonCorrection]: camera-derived pitch/roll reference (replaces accel).
/// - [lvlhFrame]: LVLH nadir reference from orbital telemetry.
DeviceOrientation applyFilter({
  required DeviceOrientation? prev,
  required RawSensorSample accel,
  required RawSensorSample mag,
  required RawSensorSample gyro,
  required double dt,
  required DateTime timestamp,
  double alpha = kFilterAlpha,
  HorizonCorrection? horizonCorrection,
  LvlhFrame? lvlhFrame,
  OrientationMode mode = OrientationMode.landscape,
}) {
  // --- Reference pitch/roll ---
  double refPitchDeg;
  double refRollDeg;

  final bool hasHorizon = horizonCorrection != null &&
      horizonCorrection.isFresh(timestamp) &&
      horizonCorrection.confidence >= kMinHorizonConfidence;

  if (hasHorizon) {
    // Camera-derived correction (highest priority in orbit).
    refPitchDeg = horizonCorrection.pitchDeg;
    refRollDeg = horizonCorrection.rollDeg;
  } else {
    // Accelerometer-derived reference.
    // Pitch: 0° = nadir, 90° = horizon, 180° = zenith.
    refPitchDeg = accelPitch(accel);
    // Roll: 0° = level, + = right ear down.
    refRollDeg = accelRoll(accel, mode);
  }

  // --- Reference heading (magnetometer) ---
  // Vector projection approach — singularity-free at all pitch angles.
  final refHeadingDeg = vectorHeading(accel, mag);

  if (prev == null || dt <= 0) {
    return DeviceOrientation(
      headingDeg: _wrapHeading(refHeadingDeg),
      pitchDeg: _clampPitch(refPitchDeg),
      rollDeg: _wrapRoll(refRollDeg),
      reliable: true,
      timestamp: timestamp,
    );
  }

  // --- Gyroscope integration (short-term) ---

  // Yaw rate: project gyro angular velocity onto the gravity direction.
  // This correctly handles all orientations — landscape left (X up),
  // landscape right (X down), portrait, and intermediate angles —
  // without needing to know the specific screen rotation.
  // Positive projected rate = CCW from above = heading decreases.
  final gMag = math.sqrt(
      accel.x * accel.x + accel.y * accel.y + accel.z * accel.z);
  final yawRate = gMag > 0.5
      ? (gyro.x * accel.x + gyro.y * accel.y + gyro.z * accel.z) / gMag
      : 0.0;
  final gyroYawDelta = -yawRate * _rad2deg * dt;

  // Pitch and roll rates depend on orientation mode.
  double gyroPitchDelta;
  double gyroRollDelta;

  switch (mode) {
    case OrientationMode.portrait:
      // Portrait: pitch=X, roll=Z.
      gyroPitchDelta = gyro.x * _rad2deg * dt;
      gyroRollDelta = gyro.z * _rad2deg * dt;
    case OrientationMode.landscape:
      // Landscape: pitch=Y (sign-flipped), roll=Z (sign-flipped).
      gyroPitchDelta = -gyro.y * _rad2deg * dt;
      gyroRollDelta = -gyro.z * _rad2deg * dt;
  }

  final gyroPitch = prev.pitchDeg + gyroPitchDelta;
  final gyroHeading = prev.headingDeg + gyroYawDelta;
  final gyroRoll = prev.rollDeg + gyroRollDelta;

  // --- Adaptive alpha: suppress accel reference during non-gravitational
  // acceleration (centripetal force from rotation, vehicle maneuvers, etc.)
  // SENSOR_FUSION_SPEC §3.3 — vehicle acceleration filtering.
  final aMag = math.sqrt(
      accel.x * accel.x + accel.y * accel.y + accel.z * accel.z);
  final gravityDeviation = (aMag - _kGravity).abs() / _kGravity;
  // When deviation exceeds threshold, ramp alpha toward 0.999 so the gyro
  // dominates and centripetal/linear forces can't drag pitch/roll around.
  final effectiveAlpha = gravityDeviation > _kGravityDeviationThreshold
      ? math.min(alpha + (1 - alpha) * 0.9, 0.999)
      : alpha;

  // --- Complementary filter blend ---
  final fusedPitch =
      effectiveAlpha * gyroPitch + (1 - effectiveAlpha) * refPitchDeg;
  final fusedRoll =
      effectiveAlpha * gyroRoll + (1 - effectiveAlpha) * refRollDeg;
  final fusedHeading =
      _blendAngles(gyroHeading, refHeadingDeg, effectiveAlpha);

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
  final aRad = a * _deg2rad;
  final bRad = b * _deg2rad;
  final sinBlend = alpha * math.sin(aRad) + (1 - alpha) * math.sin(bRad);
  final cosBlend = alpha * math.cos(aRad) + (1 - alpha) * math.cos(bRad);
  return math.atan2(sinBlend, cosBlend) * _rad2deg;
}

double _wrapHeading(double deg) {
  var h = deg % 360.0;
  if (h < 0) h += 360.0;
  return h;
}

/// Clamp pitch to the valid range: 0° (nadir) to 180° (zenith).
double _clampPitch(double deg) => deg.clamp(0.0, 180.0);

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

  final StreamController<MagnetometerInterferenceEvent>
      _interferenceController =
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

  /// Latest camera-derived horizon correction (orbit mode).
  HorizonCorrection? _horizonCorrection;

  /// Latest LVLH frame from orbital telemetry.
  LvlhFrame? _lvlhFrame;

  /// Whether the engine operates in orbit mode (microgravity).
  /// Auto-detected from LVLH altitude or set manually.
  bool _orbitMode = false;

  /// Current orientation mode (portrait or landscape).
  /// Determines gyro axis mapping and roll formula.
  OrientationMode _orientationMode = OrientationMode.landscape;

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

  /// Whether the engine is currently in orbit mode.
  bool get orbitMode => _orbitMode;

  /// Current orientation mode.
  OrientationMode get orientationMode => _orientationMode;

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

  /// Update the camera-derived horizon correction. Called by the
  /// [HorizonDetectorEngine] at ~2 Hz when a circle is detected.
  void updateHorizonCorrection(HorizonCorrection correction) {
    _horizonCorrection = correction;
  }

  /// Update the LVLH reference frame from orbital telemetry.
  /// Also auto-detects orbit mode from altitude.
  void updateLvlhFrame(LvlhFrame frame) {
    _lvlhFrame = frame;
    _orbitMode = frame.isOrbital;
  }

  /// Manually enable/disable orbit mode.
  void setOrbitMode(bool enabled) {
    _orbitMode = enabled;
  }

  /// Set the orientation mode (portrait or landscape).
  ///
  /// This changes how sensor axes are mapped to pitch/yaw/roll.
  /// Call this when the device orientation lock changes.
  void setOrientationMode(OrientationMode mode) {
    _orientationMode = mode;
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

    // Determine alpha and corrections based on orbit mode
    final alpha = kFilterAlpha;
    HorizonCorrection? horizonRef;
    LvlhFrame? lvlhRef;

    if (_orbitMode) {
      final hc = _horizonCorrection;
      if (hc != null &&
          hc.isFresh(now) &&
          hc.confidence >= kMinHorizonConfidence) {
        horizonRef = hc;
      }
      lvlhRef = _lvlhFrame;
    }

    final sample = applyFilter(
      prev: _lastOrientation,
      accel: accel,
      mag: mag,
      gyro: gyro,
      dt: dt,
      timestamp: now,
      alpha: alpha,
      horizonCorrection: horizonRef,
      lvlhFrame: lvlhRef,
      mode: _orientationMode,
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
    _horizonCorrection = null;
    _lvlhFrame = null;
    _orbitMode = false;
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
