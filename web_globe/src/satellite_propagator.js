/**
 * SGP4 orbital propagator using satellite.js.
 *
 * Usage:
 *   initTLE(line1, line2)  — parse a TLE and initialise the satrec.
 *   propagateNow()         — propagate to the current wall-clock time;
 *                            returns a position object or null on error.
 *
 * Reference: TECH_SPEC §4.3
 */

import * as satellite from 'satellite.js';

let _satrec = null;

/**
 * Initialise the SGP4 propagator from TLE lines 1 and 2.
 * The optional name line (line 0) is not needed by satellite.js.
 *
 * @param {string} line1 - TLE line 1 (the line starting with '1 ')
 * @param {string} line2 - TLE line 2 (the line starting with '2 ')
 */
export function initTLE(line1, line2) {
  _satrec = satellite.twoline2satrec(line1.trim(), line2.trim());
}

/**
 * Propagate the ISS position to the current UTC time using SGP4.
 *
 * @returns {{ lat: number, lon: number, altKm: number, ts: number, source: string } | null}
 *   Geodetic position, or null if no TLE has been set or propagation fails.
 */
/**
 * Calculate the next overhead pass for a given observer location.
 * Iterates forward in 60-second steps up to 48 hours.
 *
 * @param {number} lat - Observer latitude in degrees
 * @param {number} lon - Observer longitude in degrees
 * @returns {{ passStartUtc: number, maxElevationDeg: number, passDurationSeconds: number } | null}
 */
export function calculateNextPass(lat, lon) {
  if (!_satrec) return null;

  const observerGd = {
    latitude: satellite.degreesToRadians(lat),
    longitude: satellite.degreesToRadians(lon),
    height: 0, // sea level
  };

  const stepMs = 60 * 1000; // 1-minute steps
  const maxMs = 48 * 60 * 60 * 1000; // 48 hours
  const now = Date.now();
  const elevThreshold = 10; // degrees

  let passStart = null;
  let maxElev = 0;

  for (let t = 0; t < maxMs; t += stepMs) {
    const date = new Date(now + t);
    const posVel = satellite.propagate(_satrec, date);
    if (!posVel || !posVel.position || posVel.position === false) continue;

    const gmst = satellite.gstime(date);
    const posEcf = satellite.eciToEcf(posVel.position, gmst);
    const lookAngles = satellite.ecfToLookAngles(observerGd, posEcf);
    const elevDeg = satellite.radiansToDegrees(lookAngles.elevation);

    if (elevDeg >= elevThreshold) {
      if (!passStart) passStart = date;
      if (elevDeg > maxElev) maxElev = elevDeg;
    } else if (passStart) {
      // Pass ended
      return {
        passStartUtc: passStart.getTime(),
        maxElevationDeg: Math.round(maxElev * 10) / 10,
        passDurationSeconds: Math.round((date.getTime() - passStart.getTime()) / 1000),
      };
    }
  }

  // Pass started but didn't end within window
  if (passStart) {
    return {
      passStartUtc: passStart.getTime(),
      maxElevationDeg: Math.round(maxElev * 10) / 10,
      passDurationSeconds: Math.round((now + maxMs - passStart.getTime()) / 1000),
    };
  }

  return null;
}

export function propagateNow() {
  if (!_satrec) return null;

  const now = new Date();
  const posVel = satellite.propagate(_satrec, now);

  // satellite.js returns false for the position field when propagation fails
  // (e.g. decay, bad TLE epoch).
  if (!posVel || !posVel.position || posVel.position === false) return null;

  const gmst = satellite.gstime(now);
  const geo = satellite.eciToGeodetic(posVel.position, gmst);

  return {
    lat: satellite.degreesLat(geo.latitude),
    lon: satellite.degreesLong(geo.longitude),
    altKm: geo.height, // satellite.js already returns km
    ts: now.getTime(), // ms since epoch — matches OrbitalPosition.fromJson 'ts' key
    source: 'estimated',
  };
}
