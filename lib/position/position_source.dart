import 'dart:math' as math;

/// How the current ISS position was obtained.
enum PositionSourceType {
  /// Live data from the WhereTheISS.at API.
  live,

  /// Estimated via satellite.js SGP4 propagation from a stored TLE.
  estimated,

  /// Fixed position used for training / demo scenarios.
  static,

  /// Real-time GPS position from the device.
  gps,
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
    this.velocityKmS,
    this.bearingDeg,
  });

  final double latDeg;
  final double lonDeg;
  final double altKm;
  final DateTime timestamp;
  final PositionSourceType sourceType;
  final double? velocityKmS;
  final double? bearingDeg;

  OrbitalPosition copyWith({
    double? latDeg,
    double? lonDeg,
    double? altKm,
    DateTime? timestamp,
    PositionSourceType? sourceType,
    double? velocityKmS,
    double? bearingDeg,
  }) =>
      OrbitalPosition(
        latDeg: latDeg ?? this.latDeg,
        lonDeg: lonDeg ?? this.lonDeg,
        altKm: altKm ?? this.altKm,
        timestamp: timestamp ?? this.timestamp,
        sourceType: sourceType ?? this.sourceType,
        velocityKmS: velocityKmS ?? this.velocityKmS,
        bearingDeg: bearingDeg ?? this.bearingDeg,
      );

  /// Serialises to the `UPDATE_POSITION` bridge message payload format.
  Map<String, dynamic> toJson() => {
        'lat': latDeg,
        'lon': lonDeg,
        'altKm': altKm,
        'ts': timestamp.millisecondsSinceEpoch,
        'source': sourceType.name, // 'live' | 'estimated' | 'static'
        if (velocityKmS != null) 'velocityKmS': velocityKmS,
        if (bearingDeg != null) 'bearingDeg': bearingDeg,
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
        velocityKmS: (json['velocityKmS'] as num?)?.toDouble(),
        bearingDeg: (json['bearingDeg'] as num?)?.toDouble(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrbitalPosition &&
          latDeg == other.latDeg &&
          lonDeg == other.lonDeg &&
          altKm == other.altKm &&
          timestamp.isAtSameMomentAs(other.timestamp) &&
          sourceType == other.sourceType &&
          velocityKmS == other.velocityKmS &&
          bearingDeg == other.bearingDeg;

  @override
  int get hashCode => Object.hash(
        latDeg,
        lonDeg,
        altKm,
        timestamp.millisecondsSinceEpoch,
        sourceType,
        velocityKmS,
        bearingDeg,
      );

  @override
  String toString() =>
      'OrbitalPosition(lat=$latDeg, lon=$lonDeg, alt=${altKm}km, '
      'vel=${velocityKmS ?? "--"}km/s, brg=${bearingDeg ?? "--"}°, '
      'ts=$timestamp, source=${sourceType.name})';

  /// Computes the initial bearing (forward azimuth) in degrees from
  /// [from] to [to] using the spherical law of cosines.
  static double computeBearing(OrbitalPosition from, OrbitalPosition to) {
    final lat1 = from.latDeg * math.pi / 180;
    final lat2 = to.latDeg * math.pi / 180;
    final dLon = (to.lonDeg - from.lonDeg) * math.pi / 180;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final brg = math.atan2(y, x) * 180 / math.pi;
    return (brg + 360) % 360;
  }
}

/// Contract implemented by all ISS position data sources.
///
/// Concrete implementations: `ISSLiveSource` (WOE-009), `TLESource` (WOE-012),
/// `StaticSource` (WOE-015). Selection is managed by `PositionController`
/// (WOE-013).
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
