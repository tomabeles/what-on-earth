// CESIUM_BASE_URL is set in index.html <head> before Cesium.js loads.
// Here we just verify the imports are reachable.

import * as Cesium from 'cesium';
import * as satellite from 'satellite.js';

// Sanity-check: both imports resolve.
console.log('globe_bundle_loaded');
console.log(typeof satellite); // 'object' — confirms satellite.js is bundled

export { Cesium, satellite };
