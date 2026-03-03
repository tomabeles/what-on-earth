/// How the current ISS position was obtained.
enum PositionSourceType {
  /// Live data from the WhereTheISS.at API.
  live,

  /// Estimated via satellite.js SGP4 propagation from a stored TLE.
  estimated,

  /// Fixed position used for training / demo scenarios.
  static,
}

/// Immutable snapshot of the ISS orbital position at a point in time.
///
/// JSON keys match the `UPDATE_POSITION` bridge message payload (TECH_SPEC §8.1):
/// `{lat, lon, altKm, ts, source}`.
class OrbitalPosition {
  const OrbitalPosition({
    required this.latDeg,
    required this.lonDeg,
    required this.altKm,
    required this.timestamp,
    required this.sourceType,
  });

  final double latDeg;
  final double lonDeg;
  final double altKm;
  final DateTime timestamp;
  final PositionSourceType sourceType;

  OrbitalPosition copyWith({
    double? latDeg,
    double? lonDeg,
    double? altKm,
    DateTime? timestamp,
    PositionSourceType? sourceType,
  }) =>
      OrbitalPosition(
        latDeg: latDeg ?? this.latDeg,
        lonDeg: lonDeg ?? this.lonDeg,
        altKm: altKm ?? this.altKm,
        timestamp: timestamp ?? this.timestamp,
        sourceType: sourceType ?? this.sourceType,
      );

  /// Serialises to the `UPDATE_POSITION` bridge message payload format.
  Map<String, dynamic> toJson() => {
        'lat': latDeg,
        'lon': lonDeg,
        'altKm': altKm,
        'ts': timestamp.millisecondsSinceEpoch,
        'source': sourceType.name, // 'live' | 'estimated' | 'static'
      };

  factory OrbitalPosition.fromJson(Map<String, dynamic> json) =>
      OrbitalPosition(
        latDeg: (json['lat'] as num).toDouble(),
        lonDeg: (json['lon'] as num).toDouble(),
        altKm: (json['altKm'] as num).toDouble(),
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          json['ts'] as int,
          isUtc: true,
        ),
        sourceType: PositionSourceType.values.byName(json['source'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrbitalPosition &&
          latDeg == other.latDeg &&
          lonDeg == other.lonDeg &&
          altKm == other.altKm &&
          timestamp.isAtSameMomentAs(other.timestamp) &&
          sourceType == other.sourceType;

  @override
  int get hashCode => Object.hash(
        latDeg,
        lonDeg,
        altKm,
        timestamp.millisecondsSinceEpoch,
        sourceType,
      );

  @override
  String toString() =>
      'OrbitalPosition(lat=$latDeg, lon=$lonDeg, alt=${altKm}km, '
      'ts=$timestamp, source=${sourceType.name})';
}

/// Contract implemented by all ISS position data sources.
///
/// Concrete implementations: `ISSLiveSource` (WOE-009), `TLESource` (WOE-011),
/// `StaticSource` (WOE-015). Selection is managed by `PositionController`
/// (WOE-012).
abstract class PositionSource {
  /// Continuous stream of orbital position snapshots.
  Stream<OrbitalPosition> get positionStream;

  /// Identifies how positions produced by this source are obtained.
  PositionSourceType get type;

  /// Begins emitting positions on [positionStream].
  Future<void> start();

  /// Stops emitting positions and releases any held resources.
  Future<void> stop();
}
