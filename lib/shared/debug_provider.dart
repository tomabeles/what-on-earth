import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Debug settings for sensor fusion diagnostics.
///
/// All toggles default to ON. In the future, a persistent setting will
/// control whether the DBG button is visible in the HUD.
class DebugState {
  const DebugState({
    this.accelerometerEnabled = true,
    this.gyroscopeEnabled = true,
    this.magnetometerEnabled = true,
    this.showCoordAxis = false,
    this.showMagRef = false,
    this.showRawValues = false,
    this.showFilterStats = false,
  });

  /// Whether the accelerometer feeds into the complementary filter.
  /// When OFF, the filter runs gyro-only (no gravity reference).
  final bool accelerometerEnabled;

  /// Whether the gyroscope feeds into the complementary filter.
  /// When OFF, orientation uses only the accel/mag reference each sample.
  final bool gyroscopeEnabled;

  /// Whether the magnetometer feeds into the complementary filter.
  /// When OFF, heading holds at the last gyro-tracked value.
  final bool magnetometerEnabled;

  /// Render a 3D coordinate axis gizmo (R/G/B = X/Y/Z) in the center
  /// of the display, reflecting the app's orientation state.
  final bool showCoordAxis;

  /// Render a 3D arrow pointing toward magnetic north based on the
  /// magnetometer reading.
  final bool showMagRef;

  /// Show live sensor values (ax/ay/az, gx/gy/gz, mx/my/mz).
  final bool showRawValues;

  /// Show filter diagnostics (effective alpha, gravity deviation %,
  /// heading ref delta, mag interference flag).
  final bool showFilterStats;

  DebugState copyWith({
    bool? accelerometerEnabled,
    bool? gyroscopeEnabled,
    bool? magnetometerEnabled,
    bool? showCoordAxis,
    bool? showMagRef,
    bool? showRawValues,
    bool? showFilterStats,
  }) {
    return DebugState(
      accelerometerEnabled:
          accelerometerEnabled ?? this.accelerometerEnabled,
      gyroscopeEnabled: gyroscopeEnabled ?? this.gyroscopeEnabled,
      magnetometerEnabled:
          magnetometerEnabled ?? this.magnetometerEnabled,
      showCoordAxis: showCoordAxis ?? this.showCoordAxis,
      showMagRef: showMagRef ?? this.showMagRef,
      showRawValues: showRawValues ?? this.showRawValues,
      showFilterStats: showFilterStats ?? this.showFilterStats,
    );
  }
}

/// Riverpod provider for debug settings. Not persisted — resets each session.
final debugProvider =
    NotifierProvider<DebugNotifier, DebugState>(DebugNotifier.new);

class DebugNotifier extends Notifier<DebugState> {
  @override
  DebugState build() => const DebugState();

  void toggleAccelerometer() =>
      state = state.copyWith(accelerometerEnabled: !state.accelerometerEnabled);

  void toggleGyroscope() =>
      state = state.copyWith(gyroscopeEnabled: !state.gyroscopeEnabled);

  void toggleMagnetometer() =>
      state = state.copyWith(magnetometerEnabled: !state.magnetometerEnabled);

  void toggleCoordAxis() =>
      state = state.copyWith(showCoordAxis: !state.showCoordAxis);

  void toggleMagRef() =>
      state = state.copyWith(showMagRef: !state.showMagRef);

  void toggleRawValues() =>
      state = state.copyWith(showRawValues: !state.showRawValues);

  void toggleFilterStats() =>
      state = state.copyWith(showFilterStats: !state.showFilterStats);
}
