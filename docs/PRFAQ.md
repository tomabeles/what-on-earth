# PR/FAQ: What On Earth?!

---

## PRESS RELEASE

**FOR IMMEDIATE RELEASE**

### Astronauts See Home Like Never Before with *What On Earth?!* — the First Augmented-Reality Earth Viewer Built for Life in Low Earth Orbit

*New mobile app gives crew members on the International Space Station and future orbital platforms a live, sensor-fused, offline-capable view of the planet below, complete with personal pins, map layers, and real-time ISS telemetry.*

**HOUSTON, TX — [Launch Date]** — Today, the team behind *What On Earth?!* announced the availability of the world's first augmented-reality (AR) Earth-viewing application designed exclusively for astronauts living and working in Low Earth Orbit (LEO). Available on iOS and Android, the app fuses the onboard sensors of a smartphone or tablet — GPS, magnetometer, accelerometer, and camera — with real-time orbital position data to render a live, orientation-aware, three-dimensional view of Earth exactly as it appears from wherever the crew member is standing, floating, or looking out the cupola window.

For the first time, an astronaut can hold up their device toward any viewport or hatch, and *What On Earth?!* will display a precisely aligned, interactive 3D globe overlaid on the camera feed. Country borders, road networks, points of interest, and real-time cloud layers orient themselves automatically as the astronaut moves and tilts the device. Because orbital connectivity is intermittent and precious, the app operates in an **offline-first** mode: map tiles and data layers are pre-downloaded, compressed, and stored locally, so the full experience is available even during communication blackouts.

"Looking down at Earth from orbit is a transformative experience — but it can also be disorienting," said [Founder/CEO Name], founder of *What On Earth?!*. "Crew members have told us they often can't tell whether that coastline is the Gulf of Mexico or the Mediterranean. We built this app so that every pass over every city, every ocean, and every mountain range becomes a moment of genuine connection — to the planet, and to home."

*What On Earth?!* ships with three position-source modes. Out of the box, it consumes a **live ISS position feed**, giving International Space Station crew members zero-configuration operation from first launch. Mission planners or future commercial-station operators can supply **static coordinates** for training scenarios, or pipe in **real-time telemetry from onboard systems** over a local network connection for use on any orbital platform. As the position source is modular, future operators — Artemis Gateway, commercial LEO stations, or government crewed vehicles — can integrate their own data streams with minimal engineering effort.

Beyond navigation, *What On Earth?!* is a personal connection to the people and places astronauts leave behind. Crew members can drop **personal pins** — marking their hometown, their family's house, their launch site, or anywhere else with personal meaning — and see exactly when the station is passing overhead. Pins persist across sessions and sync when connectivity returns.

*What On Earth?!* is available today on the Apple App Store and Google Play Store. Crew licensing and enterprise deployment packages for space agencies and commercial operators are available directly from the *What On Earth?!* team.

---

## FREQUENTLY ASKED QUESTIONS

### Customer FAQs

---

**Q: How does the app know where the ISS is in real time?**

A: By default, *What On Earth?!* pulls live position data from a real-time ISS position feed, which provides the station's latitude, longitude, and altitude updated several times per minute. No configuration is needed — the app starts showing the correct Earth view the moment it receives a position fix. When the device is offline, it uses the last known position and the station's orbital mechanics model to extrapolate forward until connectivity is restored.

---

**Q: What do the on-device sensors actually do? Can't I just use GPS?**

A: Orbital altitude (roughly 400 km) puts the ISS well above GPS satellite signal geometry, so traditional GPS positioning is unreliable for determining the station's location in orbit. Instead, *What On Earth?!* uses the device's **magnetometer** (compass) and **accelerometer/gyroscope** (IMU) to determine the physical orientation of the device — which way it is pointing relative to Earth's surface and the horizon. The app combines that orientation data with the station's known orbital position to render the globe in the correct direction and attitude. GPS may be used opportunistically if a signal is available, but the core experience does not depend on it.

---

**Q: What layers are available on the globe?**

A: The initial release ships with:

- Country and territory borders
- Major road and highway networks
- Cities and settlements (points of interest)
- Bodies of water and coastlines
- Topographic relief shading
- Real-time cloud cover (when connectivity is available; cached otherwise)

Additional layers — agricultural land use, night-time lights, wildfire activity, ocean currents, and more — are planned for future releases based on crew feedback.

---

**Q: How does offline mode work? How much storage does it need?**

A: Before a mission (or during any connectivity window), *What On Earth?!* pre-fetches and compresses map tiles and layer data for the entire globe at orbital-relevant zoom levels. The compressed tile cache occupies approximately 2–4 GB depending on which layers are enabled. During communication blackouts — which can last 20–30 minutes at a time for ISS — the app continues to function fully using cached tiles. When connectivity is restored, the app automatically syncs any newly released tiles, layer updates, and personal pin data in the background.

---

**Q: How do I add a personal pin?**

A: Tap anywhere on the AR globe or the 2D map view, then select "Add Pin." You can name the pin, choose an icon, and add a note. The app will display a countdown showing the next time your orbital path will bring you within viewing distance of that location. Pins are stored locally and backed up to the cloud when connectivity allows.

---

**Q: Does the app work on any mobile device, or does it require special hardware?**

A: *What On Earth?!* is designed for standard consumer iOS and Android smartphones and tablets. It requires a device with a rear camera, magnetometer, and a 6-axis IMU (accelerometer + gyroscope) — hardware present in virtually all devices released in the last six years. No custom hardware, crew-worn sensors, or specialized mounting equipment is required, though a window-suction mount or cradle improves the hands-free AR experience significantly.

---

**Q: Can crews on commercial stations or future orbital platforms use this app, not just ISS?**

A: Yes. The ISS live-telemetry feed is the default and works out of the box, but the position source is a configurable module. Station operators can integrate their own real-time telemetry system (delivered over a local IP network connection) or simply pre-configure a static orbital element set for training scenarios. We actively invite commercial LEO station partners to collaborate on custom integrations.

---

**Q: What happens if the ISS telemetry API is unavailable?**

A: The app maintains a local orbital propagation model (based on Two-Line Element sets, or TLEs) that it refreshes whenever it can. If the live API is unreachable, the app falls back to this model to estimate the current position. The estimated position is accurate to within a few kilometers for several hours after the last TLE update, which is sufficient for the app's globe-orientation use case. The UI clearly indicates when estimated rather than live position data is in use.

---

### Internal FAQs

---

**Q: Why build for astronauts specifically? Isn't the market tiny?**

A: Astronauts are an extreme-use case that validates and sharpens every technical requirement: offline-first operation under severe bandwidth constraints, sensor fusion without reliable GPS, centimeter-accurate orientation rendering, and graceful degradation in a safety-critical environment. A product that works perfectly for a crew member on the ISS is a product that works exceptionally well for backcountry hikers, maritime crews, pilots, and anyone in a connectivity-challenged environment. The astronaut market is the proving ground; the platform it produces has broad commercial adjacencies. Additionally, the growing commercial space sector — with multiple private LEO stations planned in this decade — represents a legitimate and expanding enterprise market.

---

**Q: Why use an existing ISS position feed rather than building our own telemetry ingestion from day one?**

A: Speed and focus. Integrating an existing real-time ISS position feed lets us ship a working product to ISS crew members immediately, gather real-world feedback, and validate the core AR rendering pipeline before investing engineering resources in the more complex work of integrating proprietary telemetry systems from commercial operators. The architecture is explicitly designed for position-source modularity from day one, so this is an additive expansion, not a rewrite.

---

**Q: How does the app handle the safety-critical nature of the space environment?**

A: *What On Earth?!* is a situational-awareness and personal-use tool, not a flight-critical system. It is explicitly not designed or certified for any operational task where failure would jeopardize crew safety or mission success. The app presents informational data only and defers to crew judgment and official mission systems at all times. The offline-first architecture ensures that the app never interrupts normal operations by demanding network access, and the battery and CPU footprint is minimized so it does not compete with primary crew workloads.

---

**Q: How accurate is the AR globe orientation?**

A: In the initial release, orientation accuracy is bounded by the quality of the device's magnetometer and IMU. On high-quality consumer devices, this yields globe alignment accurate to within approximately 2–5 degrees, which is sufficient to identify continents, major geographic features, and large cities. Magnetometer calibration routines are built into the onboarding flow. Future releases will explore magnetometer-free orientation using computer-vision-based horizon detection, which would improve accuracy in environments with magnetic interference (common aboard metal-hulled spacecraft).

---

**Q: What is the data licensing situation for map tiles and layers?**

A: The base map layer uses OpenStreetMap data (ODbL license), which permits offline caching and redistribution with attribution. Specialized layers — cloud cover, topographic relief, satellite imagery — are sourced from providers whose licenses permit offline use and caching under our enterprise agreements. All data provenance is documented in the app's open data registry, and no layer is shipped without confirmed offline-caching rights.

---

**Q: What does the technical architecture look like at a high level?**

A: The app is built on a cross-platform native codebase targeting iOS and Android. The core subsystems are:

- **Position Module**: abstracted interface supporting a live ISS position feed, onboard telemetry (TCP/IP local network), and static/TLE-propagated fallback sources.
- **Sensor Fusion Engine**: combines magnetometer heading, IMU attitude, and device orientation into a stable world-frame orientation quaternion updated at ≥60 Hz.
- **3D Globe Renderer**: a GPU-accelerated spherical tile renderer that projects the device's camera feed as the background layer and composites map tiles, layers, and AR annotations on top.
- **Tile Cache Manager**: pre-fetches, compresses (using a combination of vector tiles and raster tiles in compressed formats), and manages the local tile store, with a background sync daemon that runs opportunistically during connectivity windows.
- **Pin & Annotation Store**: a local-first SQLite database with conflict-free sync to a cloud backend when online.

---

**Q: What are the biggest technical risks?**

A: Three stand out:

1. **Magnetometer interference aboard spacecraft**: Metal hulls, electrical equipment, and magnetic shielding materials all perturb compass readings. We will need to work closely with crew hardware teams to characterize the magnetic environment and implement robust calibration and compensation. Our contingency is a camera-based horizon-detection orientation mode that does not rely on the magnetometer.

2. **Connectivity unpredictability**: ISS has structured communication windows, but bandwidth, latency, and availability vary significantly. The offline-first architecture mitigates this, but we must be careful not to assume any minimum connectivity level for any core feature.

3. **App store distribution in a crew environment**: Standard consumer app stores assume persistent internet for installation and updates. Crew devices are managed by agency IT and may have restricted store access. We will pursue enterprise distribution mechanisms (MDM/side-loading) in parallel with public store listing to ensure reliable crew-device delivery.

---

*What On Earth?!* | Making every orbit a moment of discovery.
