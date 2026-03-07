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
