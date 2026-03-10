import 'dart:math' as math;

import '../position/position_source.dart';
import 'orientation_corrections.dart';

const double _earthRadiusKm = 6371.0;
const double _deg2rad = math.pi / 180.0;

/// Compute the LVLH (Local Vertical Local Horizontal) reference frame
/// from an orbital position.
///
/// The LVLH frame defines three orthogonal axes:
/// - **R (nadir)**: unit vector from spacecraft toward Earth center
/// - **V (along-track)**: from bearing or defaulting to East
/// - **H (cross-track)**: R × V (right-handed)
///
/// This is used as a substitute for accelerometer-derived gravity
/// when operating in microgravity.
LvlhFrame computeLvlhFrame(OrbitalPosition position) {
  final lat = position.latDeg * _deg2rad;
  final lon = position.lonDeg * _deg2rad;
  final alt = position.altKm;

  // Geodetic → ECEF position vector
  final r = _earthRadiusKm + alt;
  final cosLat = math.cos(lat);
  final sinLat = math.sin(lat);
  final cosLon = math.cos(lon);
  final sinLon = math.sin(lon);

  final px = r * cosLat * cosLon;
  final py = r * cosLat * sinLon;
  final pz = r * sinLat;

  // Nadir = -position (from spacecraft toward Earth center)
  final pMag = math.sqrt(px * px + py * py + pz * pz);
  final nadirX = -px / pMag;
  final nadirY = -py / pMag;
  final nadirZ = -pz / pMag;

  // Velocity direction from bearing, or default to East
  double vx, vy, vz;
  if (position.bearingDeg != null) {
    final brg = position.bearingDeg! * _deg2rad;
    // ENU basis at this position
    final eastX = -sinLon;
    final eastY = cosLon;
    const eastZ = 0.0;
    final northX = -sinLat * cosLon;
    final northY = -sinLat * sinLon;
    final northZ = cosLat;

    vx = math.sin(brg) * eastX + math.cos(brg) * northX;
    vy = math.sin(brg) * eastY + math.cos(brg) * northY;
    vz = math.sin(brg) * eastZ + math.cos(brg) * northZ;
  } else {
    // Default to East direction
    vx = -sinLon;
    vy = cosLon;
    vz = 0.0;
  }

  // Normalize velocity
  final vMag = math.sqrt(vx * vx + vy * vy + vz * vz);
  vx /= vMag;
  vy /= vMag;
  vz /= vMag;

  // Cross-track = nadir × velocity
  var hx = nadirY * vz - nadirZ * vy;
  var hy = nadirZ * vx - nadirX * vz;
  var hz = nadirX * vy - nadirY * vx;
  final hMag = math.sqrt(hx * hx + hy * hy + hz * hz);
  hx /= hMag;
  hy /= hMag;
  hz /= hMag;

  return LvlhFrame(
    nadirEcef: (nadirX, nadirY, nadirZ),
    velocityEcef: (vx, vy, vz),
    crossTrackEcef: (hx, hy, hz),
    referencePitchDeg: 0.0,
    referenceRollDeg: 0.0,
    altKm: alt,
    timestamp: position.timestamp,
  );
}
