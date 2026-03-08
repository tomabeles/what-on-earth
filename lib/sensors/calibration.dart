import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Magnetometer calibration parameters (TECH_SPEC §9.5).
///
/// Hard-iron bias is a constant offset caused by permanent magnets in or near
/// the device. Subtracting it from raw magnetometer readings is the simplest
/// and most impactful correction.
class CalibrationParams {
  /// Hard-iron offset `[x, y, z]` in µT.
  final List<double> hardIron;

  /// Soft-iron 3×3 correction matrix (identity = no soft-iron distortion).
  final List<List<double>> softIron;

  /// When the calibration was performed.
  final DateTime calibratedAt;

  /// Confidence score 0–1.
  final double confidence;

  const CalibrationParams({
    required this.hardIron,
    required this.softIron,
    required this.calibratedAt,
    required this.confidence,
  });

  /// Default identity (no correction applied).
  factory CalibrationParams.identity() => CalibrationParams(
        hardIron: [0.0, 0.0, 0.0],
        softIron: [
          [1.0, 0.0, 0.0],
          [0.0, 1.0, 0.0],
          [0.0, 0.0, 1.0],
        ],
        calibratedAt: DateTime.fromMillisecondsSinceEpoch(0),
        confidence: 0.0,
      );

  Map<String, dynamic> toJson() => {
        'hardIron': hardIron,
        'softIron': softIron.map((r) => r.toList()).toList(),
        'calibratedAt': calibratedAt.toIso8601String(),
        'confidence': confidence,
      };

  factory CalibrationParams.fromJson(Map<String, dynamic> json) {
    return CalibrationParams(
      hardIron: (json['hardIron'] as List).cast<double>(),
      softIron: (json['softIron'] as List)
          .map((r) => (r as List).cast<double>())
          .toList(),
      calibratedAt: DateTime.parse(json['calibratedAt'] as String),
      confidence: (json['confidence'] as num).toDouble(),
    );
  }
}

/// Persistent store for magnetometer calibration using `flutter_secure_storage`.
class CalibrationStore {
  static const _key = 'mag_calibration';

  final FlutterSecureStorage _storage;

  CalibrationStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Save calibration params.
  Future<void> save(CalibrationParams params) async {
    await _storage.write(key: _key, value: jsonEncode(params.toJson()));
  }

  /// Load saved calibration params, or null if none saved.
  Future<CalibrationParams?> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    return CalibrationParams.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  /// Delete saved calibration.
  Future<void> clear() async {
    await _storage.delete(key: _key);
  }
}
