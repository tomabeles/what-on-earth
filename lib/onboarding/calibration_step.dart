import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../sensors/calibration.dart';
import '../sensors/sensor_fusion.dart';
import '../sensors/sensor_fusion_provider.dart';
import '../shared/theme.dart';

// ---------------------------------------------------------------------------
// Hard-iron computation (WOE-047)
// ---------------------------------------------------------------------------

/// Compute hard-iron bias as the midpoint of min/max per axis.
///
/// Returns `[biasX, biasY, biasZ]` in µT.
List<double> computeHardIron(List<RawSensorSample> samples) {
  if (samples.isEmpty) return [0.0, 0.0, 0.0];

  var minX = double.infinity, maxX = double.negativeInfinity;
  var minY = double.infinity, maxY = double.negativeInfinity;
  var minZ = double.infinity, maxZ = double.negativeInfinity;

  for (final s in samples) {
    if (s.x < minX) minX = s.x;
    if (s.x > maxX) maxX = s.x;
    if (s.y < minY) minY = s.y;
    if (s.y > maxY) maxY = s.y;
    if (s.z < minZ) minZ = s.z;
    if (s.z > maxZ) maxZ = s.z;
  }

  return [
    (minX + maxX) / 2,
    (minY + maxY) / 2,
    (minZ + maxZ) / 2,
  ];
}

/// Compute calibration confidence based on sample spread.
///
/// Typical Earth field is ~25–65 µT. Good calibration requires samples
/// spread across a reasonable range on each axis. Confidence is the
/// minimum of per-axis spread ratios clamped to [0, 1].
double computeConfidence(List<RawSensorSample> samples) {
  if (samples.length < 10) return 0.0;

  const expectedSpread = 60.0; // µT — typical Earth field magnitude

  double spread(double Function(RawSensorSample) axis) {
    final values = samples.map(axis);
    return values.reduce(math.max) - values.reduce(math.min);
  }

  final sx = spread((s) => s.x);
  final sy = spread((s) => s.y);
  final sz = spread((s) => s.z);

  // If any axis has < 10 µT spread the user hasn't done the figure-8 fully
  final minSpread = [sx, sy, sz].reduce(math.min);
  if (minSpread < 10.0) {
    return (samples.length / 100.0).clamp(0.0, 0.3) *
        (minSpread / 10.0).clamp(0.0, 1.0);
  }

  // Confidence = min spread ratio across axes, weighted by sample count
  final ratio = [sx, sy, sz]
      .map((s) => (s / expectedSpread).clamp(0.0, 1.0))
      .reduce(math.min);

  final countFactor = (samples.length / 100.0).clamp(0.0, 1.0);
  return (ratio * countFactor).clamp(0.0, 1.0);
}

// ---------------------------------------------------------------------------
// CalibrationStep — wraps CalibrationScreen with live magnetometer data
// ---------------------------------------------------------------------------

/// Onboarding step 3: magnetometer calibration with live sensor data.
///
/// Subscribes to magnetometer events, collects samples, computes hard-iron
/// bias and confidence in real time, and saves results on completion.
///
/// Reference: TECH_SPEC §7.2, §9.5, PRD FR-SEN-003
class CalibrationStep extends ConsumerStatefulWidget {
  const CalibrationStep({super.key, this.onComplete, this.onSkip});

  /// Called when calibration is complete and saved.
  final VoidCallback? onComplete;

  /// Called when the user skips calibration.
  final VoidCallback? onSkip;

  @override
  ConsumerState<CalibrationStep> createState() => _CalibrationStepState();
}

class _CalibrationStepState extends ConsumerState<CalibrationStep> {
  final List<RawSensorSample> _samples = [];
  StreamSubscription<MagnetometerEvent>? _magSub;
  double _confidence = 0.0;
  bool _collecting = false;

  @override
  void initState() {
    super.initState();
    _startCollecting();
  }

  void _startCollecting() {
    _samples.clear();
    _confidence = 0.0;
    _collecting = true;

    _magSub = magnetometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen((event) {
      if (!_collecting) return;

      _samples.add(RawSensorSample(
        x: event.x,
        y: event.y,
        z: event.z,
        timestamp: event.timestamp,
      ));

      // Recompute confidence every 10 samples to avoid jank
      if (_samples.length % 10 == 0) {
        if (!mounted) return;
        setState(() {
          _confidence = computeConfidence(_samples);
        });
      }
    });
  }

  void _restart() {
    _magSub?.cancel();
    setState(() {
      _samples.clear();
      _confidence = 0.0;
    });
    _startCollecting();
  }

  Future<void> _done() async {
    _collecting = false;
    _magSub?.cancel();

    final hardIron = computeHardIron(_samples);
    final params = CalibrationParams(
      hardIron: hardIron,
      softIron: [
        [1.0, 0.0, 0.0],
        [0.0, 1.0, 0.0],
        [0.0, 0.0, 1.0],
      ],
      calibratedAt: DateTime.now(),
      confidence: _confidence,
    );

    // Save to persistent storage
    final store = CalibrationStore();
    await store.save(params);

    // Update live sensor fusion engine
    if (mounted) {
      ref.read(sensorFusionEngineProvider).updateCalibration(params);
    }

    widget.onComplete?.call();
  }

  void _skip() {
    _collecting = false;
    _magSub?.cancel();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Orientation accuracy may be reduced without calibration'),
          duration: Duration(seconds: 3),
        ),
      );
    }

    widget.onSkip?.call();
  }

  @override
  void dispose() {
    _magSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Re-use the existing CalibrationScreen UI (minus Scaffold)
        Expanded(
          child: _CalibrationBody(
            confidence: _confidence,
            onDone: _confidence >= 0.8 ? _done : null,
            onRestart: _restart,
            tokens: tokens,
          ),
        ),
        // Skip button at bottom
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TextButton(
              onPressed: _skip,
              child: Text(
                'Skip',
                style: TextStyle(color: tokens.hudSecondary),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Calibration body — compact layout for embedding in onboarding PageView
// ---------------------------------------------------------------------------

class _CalibrationBody extends StatelessWidget {
  const _CalibrationBody({
    required this.confidence,
    this.onDone,
    this.onRestart,
    required this.tokens,
  });

  final double confidence;
  final VoidCallback? onDone;
  final VoidCallback? onRestart;
  final AppTokens tokens;

  @override
  Widget build(BuildContext context) {
    final doneEnabled = confidence >= 0.8;
    final percent = (confidence * 100).toInt().clamp(0, 100);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.explore, size: 48, color: tokens.hudPrimary),
            const SizedBox(height: 16),
            Text(
              'Compass Calibration',
              style: TextStyle(
                color: tokens.hudPrimary,
                fontSize: 22,
                fontFamily: tokens.hudFontFamily,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Confidence indicator
            Text(
              '$percent%',
              style: TextStyle(
                color: tokens.hudPrimary,
                fontFamily: tokens.hudFontFamily,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                value: confidence.clamp(0.0, 1.0),
                backgroundColor: tokens.borderPrimary,
                valueColor: AlwaysStoppedAnimation(
                  confidence < 0.4
                      ? tokens.hudDanger
                      : confidence < 0.8
                          ? tokens.hudWarning
                          : tokens.hudPrimary,
                ),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Move your device in a slow\nfigure-8 pattern.',
              style: TextStyle(
                color: tokens.hudSecondary,
                fontSize: 14,
                fontFamily: tokens.hudFontFamily,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: doneEnabled ? onDone : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.fabBackground,
                foregroundColor: tokens.fabIcon,
                disabledBackgroundColor: tokens.borderPrimary,
                disabledForegroundColor: tokens.hudSecondary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
              ),
              child: const Text('Done'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRestart,
              child: Text(
                'Restart',
                style: TextStyle(color: tokens.hudSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
