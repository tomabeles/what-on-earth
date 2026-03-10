# Patent Filing Guide: *What On Earth?!*

**Status:** Draft
**Date:** 2026-03-09
**Inventor/Attorney:** [Name]
**Application Type:** Utility Patent (Provisional → Non-Provisional)

---

## Table of Contents

1. [Phase 1: Prior Art Deep Dive](#phase-1-prior-art-deep-dive)
2. [Phase 2: Claim Strategy](#phase-2-claim-strategy)
3. [Phase 3: Draft the Specification](#phase-3-draft-the-specification)
4. [Phase 4: File the Provisional](#phase-4-file-the-provisional)
5. [Phase 5: The 12-Month Provisional Window](#phase-5-the-12-month-provisional-window)
6. [Phase 6: File the Non-Provisional](#phase-6-file-the-non-provisional)
7. [Phase 7: PCT / Foreign Filing Decision](#phase-7-pct--foreign-filing-decision)
8. [Phase 8: USPTO Examination](#phase-8-uspto-examination)
9. [Phase 9: Office Action Responses](#phase-9-office-action-responses)
10. [Phase 10: Notice of Allowance and Grant](#phase-10-notice-of-allowance-and-grant)
11. [Budget Summary](#budget-summary)
12. [Immediate Next Steps](#immediate-next-steps)
13. [Appendix A: Prior Art References](#appendix-a-prior-art-references)
14. [Appendix B: CPC Classifications to Search](#appendix-b-cpc-classifications-to-search)

---

## Phase 1: Prior Art Deep Dive

**Timeline:** 1-2 weeks

The initial web-based prior art search identified key references but was broad. Before drafting, conduct a structured search across patent and non-patent literature databases.

### 1.1 Search Databases

**USPTO (PatFT + AppFT):**
Full-text search at [USPTO Patent Full-Text Database](https://patft.uspto.gov/) and [USPTO Application Full-Text Database](https://appft.uspto.gov/). See [Appendix B](#appendix-b-cpc-classifications-to-search) for CPC classifications to search.

**Google Patents:**
Broader international coverage. Use these queries:

```
(orbital OR spacecraft OR "space station") AND "augmented reality" AND (globe OR earth OR geographic)
```

```
"sensor fusion" AND (magnetometer OR IMU) AND ("zero gravity" OR microgravity OR "free fall")
```

```
"position source" AND (TLE OR "two-line element" OR SGP4) AND (fallback OR cascade)
```

**Espacenet (EPO):**
For European prior art. Same query terms as Google Patents.

**IEEE Xplore + Google Scholar (Non-Patent Literature):**
NPL is citable prior art. Search for:

- Papers on sensor fusion in microgravity
- AR applications in space environments
- "Windows on Earth" technical papers by TERC
- CesiumJS or WebGL-based globe rendering in mobile AR contexts

### 1.2 Key References to Pull and Analyze

From the initial search, obtain and read the full text (especially claims) of these references:

| Reference | Relevance |
|---|---|
| US10565798B2 (Mobilizar — AR globe) | Closest "AR + globe" reference. AR interactions with a *physical* globe via camera recognition. |
| US9488488B2 (Google — AR maps) | Closest "sensor fusion + AR map overlay" reference. Ground-based, GPS-dependent. |
| US20200126265A1 (AR overlay system) | General AR compositing method using position + orientation data. |
| US7693702B1 (Space systems AR) | Only patent combining "space" + "AR" + "visualization." Military SA context. |
| US7315259B2 (Google — tile caching) | Defines the tile caching prior art boundary. |
| US20150193982A1 (AR overlays via position/orientation) | Broad AR positioning claims. Check if still active. |

### 1.3 Document the Results

Create a prior art matrix. This becomes your primary reference during prosecution and office action responses.

```
| Reference | Teaches Claim A? | Teaches Claim B? | Teaches C? | Key Distinction |
|-----------|-----------------|-----------------|------------|-----------------|
| ...       | Partial/Full/No | ...             | ...        | ...             |
```

Store the completed matrix in `docs/patent/PRIOR_ART_MATRIX.md`.

---

## Phase 2: Claim Strategy

**Timeline:** 1 week (concurrent with Phase 1)

### 2.1 Potentially Patentable Claim Areas

| # | Claim Area | Novelty | Obviousness Risk | Strength |
|---|---|---|---|---|
| A | Orbital AR Earth Identification | High | Medium-High | **Moderate-Strong** (best candidate) |
| B | Microgravity Sensor Fusion | High | Medium | **Strong** (most defensible) |
| C | Cascading Position Source | Medium | Medium | **Moderate** |
| D | Offline Tile Architecture | Low | High | **Weak** (well-covered prior art) |
| E | Pin + Orbital Pass Prediction | Low-Medium | High | **Weak** (straightforward orbital mechanics) |
| F | Transparent WebView Compositing | Low | High | **Weak** (implementation detail) |

### 2.2 Recommended Claim Hierarchy

#### Independent Claim 1 — Method (broadest defensible)

A method for providing augmented-reality geographic identification to an observer aboard an orbiting spacecraft, comprising:

- receiving orbital position data (lat, lon, alt) of the spacecraft from a position source;
- receiving orientation data (heading, pitch, roll) of a handheld device from a sensor fusion engine that combines magnetometer and inertial measurement unit data;
- rendering a three-dimensional globe model oriented according to the orbital position and device orientation;
- compositing the rendered globe over a live camera feed from the device such that geographic features on the globe are aligned with corresponding features visible through the spacecraft viewport.

#### Independent Claim 2 — System

A system comprising: a handheld computing device aboard an orbiting spacecraft, the device having a camera, magnetometer, and IMU; a position module providing orbital position; a sensor fusion engine producing orientation; a rendering engine generating a 3D globe; and a display compositing the globe over the camera feed.

#### Independent Claim 3 — Computer-Readable Medium

Standard CRM claim mirroring Claim 1.

#### Dependent Claims (target 15-18 to reach a ~20-claim set)

- Wherein the sensor fusion engine operates without a gravity-derived reference vector (microgravity adaptation).
- Wherein the position source cascades from a live telemetry feed to TLE-based SGP4 propagation upon loss of connectivity.
- Wherein the method further comprises detecting magnetometer interference exceeding a threshold angular rate and prompting recalibration.
- Wherein hard-iron and soft-iron calibration parameters specific to the spacecraft electromagnetic environment are applied to magnetometer readings.
- Wherein map tile data is pre-cached on the device and served by a local HTTP server to the rendering engine.
- Wherein the rendering engine is a WebGL-based globe renderer executing in a transparent WebView layer.
- Wherein the user can mark a geographic location as a personal pin, and the system calculates a next overhead pass using orbital propagation.
- Wherein the 3D globe model includes selectively toggleable layers comprising one or more of: borders, terrain, cloud cover, and city labels.
- Wherein the position source status (live, estimated, static) is persistently displayed to the observer.
- Wherein the sensor fusion update rate is at least 50 Hz and the globe rendering rate is at least 30 fps.
- Wherein the orbital position data is received from a public ISS position API as a default, configurable to an operator-provided telemetry feed.
- Wherein pin data is stored locally and synced to a cloud backend using differential last-write-wins conflict resolution when connectivity is available.

### 2.3 Claim Drafting Principles

**Breadth vs. defensibility:**

- Independent claims should NOT mention the ISS, CesiumJS, Flutter, WebView, or any specific implementation. Keep language at the level of "orbiting spacecraft," "3D globe model," "sensor fusion engine," "compositing over camera feed."
- Dependent claims narrow to specific implementations (WebGL, TLE/SGP4, local HTTP server, etc.). These are fallback positions during prosecution.

**35 USC 101 considerations:**

- Emphasize the technical problem (orientation in microgravity without GPS) and the technical solution (specific sensor fusion + cascading position source + real-time compositing).
- Avoid claim language that reads as "displaying information." Frame operations as "rendering... compositing... orienting based on sensor data."

**Means-plus-function risk:**

- Avoid "means for" language. Use "a sensor fusion engine configured to..." or "a rendering engine that..."

---

## Phase 3: Draft the Specification

**Timeline:** 2-4 weeks

### 3.1 Document Structure

```
TITLE OF THE INVENTION
CROSS-REFERENCE TO RELATED APPLICATIONS
FIELD OF THE INVENTION
BACKGROUND OF THE INVENTION
  - Description of the problem (astronaut geography identification)
  - Description of prior art and its limitations
SUMMARY OF THE INVENTION
BRIEF DESCRIPTION OF THE DRAWINGS
DETAILED DESCRIPTION OF PREFERRED EMBODIMENTS
  - System overview
  - Position module (3 source types + cascading)
  - Sensor fusion engine (complementary filter, microgravity adaptation)
  - Globe rendering and AR compositing
  - Tile cache architecture
  - Pin store and pass prediction
  - Bridge protocol (Flutter <-> JS)
  - Onboarding and calibration
CLAIMS
ABSTRACT
```

### 3.2 Specification Drafting Priorities

#### Background Section

- Cite the documented astronaut difficulty identifying geography from orbit. Real NASA/ESA quotes exist in public literature.
- Cite Windows on Earth (TERC, 2012) and its limitations: not AR, not real-time, not mobile, not sensor-fused.
- Cite ground-based ISS tracker apps and explain why they solve a different problem (ground looking up vs. orbit looking down).
- Cite standard sensor fusion approaches and explain why they fail in microgravity (accelerometer assumes 1G).
- Do NOT disparage prior art. Describe neutrally, then distinguish.

#### Detailed Description

The project TECH_SPEC (`docs/TECH_SPEC.md`) is essentially a specification draft. Convert it into patent prose with the following additions:

**Include multiple embodiments.** Do not limit to CesiumJS/Flutter:

- "In one embodiment, the globe renderer is a WebGL-based engine executing in a browser view. In another embodiment, the globe renderer is a native GPU pipeline using Metal or Vulkan."
- "In one embodiment, the position source cascades from an HTTP API to SGP4 propagation. In another embodiment, the position source receives real-time telemetry over a local TCP connection."

**Describe but don't claim** the things that are weak on patentability (tile caching, basic AR compositing). This builds a defensive portfolio even if those claims are rejected.

**Include pseudocode** for the sensor fusion algorithm, the cascading position logic, and the pass calculator. This satisfies 35 USC 112.

#### Key Sentences for Prosecution Leverage

Include these or similar sentences in the detailed description:

> "Unlike terrestrial AR applications that rely on GPS for positioning and gravitational acceleration for determining device pitch and roll, the present invention operates in an environment where neither GPS signals nor a reliable gravity vector is available."

> "The sensor fusion engine of the present invention compensates for the abnormally high magnetic interference characteristic of a metal-hulled spacecraft by applying per-device hard-iron and soft-iron calibration parameters and by detecting interference events that exceed physically possible angular rates."

### 3.3 Drawings

Plan for approximately 8-12 sheets of formal drawings:

| Figure | Content |
|---|---|
| 1 | System overview block diagram (device, position sources, sensor fusion, renderer, display) |
| 2 | AR compositing stack (camera layer, globe layer, UI layer) |
| 3 | Position source cascade flowchart (live -> TLE -> static, with decision nodes) |
| 4 | Sensor fusion engine block diagram (magnetometer, accel, gyro -> complementary filter -> H/P/R) |
| 5 | Magnetometer calibration and interference detection flowchart |
| 6 | Globe rendering pipeline (position + orientation -> camera parameters -> tile fetch -> render -> composite) |
| 7 | Tile cache architecture (local HTTP server, LRU eviction, background sync) |
| 8 | Pin workflow (tap -> create -> store -> sync -> pass calculation) |
| 9 | User interface mockup: AR view with status indicators, layer toggles |
| 10 | Bridge protocol sequence diagram (Flutter <-> JS messages) |
| 11 | Orbital pass prediction geometry diagram (spacecraft, Earth, elevation angle) |
| 12 | Onboarding flow (position confirm -> tile download -> calibration) |

**Format:** Black-and-white line drawings. Can be created with draw.io, Figma, or OmniGraffle and exported as PDF. Must meet USPTO formal drawing requirements (37 CFR 1.84): margins, numbering, reference numerals matching the specification.

---

## Phase 4: File the Provisional

**Timeline:** Target 2-4 weeks from project start

### 4.1 Why Provisional First

- Establishes the priority date immediately.
- Provides 12 months to refine claims, continue development, and assess commercial viability.
- Costs only the USPTO filing fee ($320 micro entity, $640 small entity).
- No formal claims required, but include draft claims for prosecution continuity.

### 4.2 Filing Checklist

- [ ] Specification (full text; can be rough, but completeness strengthens priority date)
- [ ] Draft claims (not required but strongly recommended)
- [ ] Drawings (informal acceptable for provisional, but use formal drawings if ready)
- [ ] Cover sheet (PTO/SB/16)
- [ ] Filing fee ($320 micro / $640 small entity)
- [ ] Micro entity certification (PTO/SB/15A) if applicable: fewer than 4 previously filed US patent applications and gross income below the threshold

### 4.3 Filing Method

File through [USPTO Patent Center](https://patentcenter.uspto.gov/):

- Application type: Provisional
- Upon filing, receive a provisional application number and filing date (this is the priority date)

---

## Phase 5: The 12-Month Provisional Window

### 5.1 Continue Development

- Build and test the app on actual hardware.
- **Critical:** Validate or redesign the sensor fusion for microgravity. If the accelerometer-based complementary filter fails in simulated zero-G, document the adaptation. This strengthens the patent.
- Document any novel solutions discovered during development.

### 5.2 Supplement with CIP if Needed

- If significant new technology is developed during the 12 months (e.g., camera-based horizon detection for magnetometer-free orientation), consider filing a Continuation-in-Part (CIP) or a new provisional.
- Any new matter added after the provisional filing will not receive the original priority date.

### 5.3 Commercial Assessment

- Talk to potential licensees (space agencies, commercial station operators).
- Assess whether foreign filing is warranted (PCT vs. direct national filings).
- **Decision point at month 10:** File non-provisional or abandon?

---

## Phase 6: File the Non-Provisional

**Timeline:** Month 11-12 of the provisional period

### 6.1 Filing Strategy

**Recommended: File a new non-provisional claiming priority to the provisional.**

- File under 35 USC 111(a), claiming benefit of the provisional under 35 USC 119(e).
- Must be filed within 12 months of the provisional filing date.
- Allows refinement of the specification and claims based on development learnings.

**Not recommended: Convert the provisional to non-provisional.**

- Loses remaining provisional period.
- Rarely advantageous.

### 6.2 Non-Provisional Filing Checklist

- [ ] Final specification (refined from provisional + development learnings)
- [ ] Formal claims (the ~20-claim set from Phase 2, refined)
- [ ] Formal drawings (meeting 37 CFR 1.84)
- [ ] Abstract (150 words maximum)
- [ ] Application Data Sheet (ADS)
- [ ] Declaration/oath (PTO/AIA/01)
- [ ] Claim of priority to provisional (in ADS)
- [ ] Information Disclosure Statement (IDS)
- [ ] Filing fee: ~$800 micro entity / ~$1,600 small entity (filing + search + examination)

### 6.3 Information Disclosure Statement (IDS)

File the IDS with or promptly after the non-provisional. Cite ALL prior art from Phase 1, including:

- All patents and published applications identified
- Windows on Earth (NPL: Wikipedia article and TERC publications)
- Sensor fusion academic papers
- ISS tracker apps (NPL)
- The project TECH_SPEC if it was publicly accessible before filing

**Duty of candor (37 CFR 1.56):** As both inventor and attorney of record, diligence here is especially important. Cite anything material to patentability, even if unfavorable. Failure to disclose is inequitable conduct and can render the patent unenforceable.

---

## Phase 7: PCT / Foreign Filing Decision

**Timeline:** Month 12 (concurrent with non-provisional filing)

### 7.1 When to File PCT

Consider filing PCT if:

- Commercial LEO station operators are headquartered outside the US (ESA partners are EU-based).
- Preservation of options in the EU, Japan, or other jurisdictions is desired for up to 30 months.

### 7.2 PCT Filing Details

- File within 12 months of the earliest priority date (the provisional filing date).
- Designates all PCT member states automatically.
- Provides an International Search Report (ISR) and Written Opinion, which serve as a useful preview of prosecution challenges.
- National phase entry deadline: 30 months from priority date.
- Cost: approximately $2,000-4,000 for filing and transmittal fees.

### 7.3 If Skipping PCT

- Direct national filings in individual countries are still possible within 12 months of the priority date.
- For most small entities, PCT is more cost-effective when protection in more than one foreign jurisdiction is desired.

---

## Phase 8: USPTO Examination

**Timeline:** Months 14-30 (typically)

### 8.1 Expected Timeline

| Event | Typical Timing |
|---|---|
| Filing receipt | Immediately |
| Application publication (18 months from priority) | ~Month 18 |
| First office action | 12-24 months after non-provisional filing |
| Final office action (if needed) | 3-6 months after response |
| Notice of Allowance or continued prosecution | 6-12 months after final OA |
| **Total to grant** | **2-4 years from non-provisional filing** |

### 8.2 Accelerated Examination Options

**Track One (Prioritized Examination):**

- Additional fee: ~$1,000 micro / ~$2,000 small entity.
- First office action within 6 months.
- Worth considering if commercial urgency exists (e.g., active licensing negotiations with a space agency).

**Patent Prosecution Highway (PPH):**

- Available if PCT was filed and a favorable ISR/Written Opinion was received.
- Use PPH for faster US examination based on the international search results.

---

## Phase 9: Office Action Responses

### 9.1 Anticipated First Office Action

Based on the prior art landscape, the first office action will almost certainly contain:

**35 USC 103 rejection** combining:

1. A ground-based AR patent (e.g., US9488488B2 or US20200126265A1) teaching "AR overlay using sensor fusion + camera."
2. Windows on Earth or another space-context reference teaching "Earth viewing from orbital altitude for astronauts."
3. Possibly a tile caching reference teaching "offline map data."
4. Examiner argument: "It would have been obvious to one of ordinary skill in the art to combine the AR overlay of Reference 1 with the orbital viewing context of Reference 2."

**Possible 35 USC 101 rejection** characterizing the claims as an "abstract idea of displaying geographic information."

### 9.2 Response Strategy: 35 USC 103

#### Primary Argument — No Motivation to Combine + Teaching Away

- Ground-based AR patents *teach toward* GPS positioning. An orbital context explicitly lacks GPS. A person having ordinary skill in the art (PHOSITA) would not look to a GPS-dependent system to solve an orbital positioning problem.
- Ground-based sensor fusion *relies on* a gravity vector from the accelerometer. In microgravity (free-fall), this approach fails. The prior art teaches away from applying standard sensor fusion in orbit.
- Windows on Earth is a desktop simulation tool. It does not teach or suggest real-time sensor-fused AR compositing on a mobile device. A PHOSITA examining Windows on Earth would have no motivation to add sensor fusion and camera overlay.

#### Secondary Argument — Unexpected Results

- The combination of orbital position + device orientation + 3D globe rendering produces a qualitatively different result than any prior art system. The observer can hold a device toward an actual spacecraft viewport and see geography identification in real-time. No combination of prior art achieves this.

#### Fallback — Amend to Dependent Claims

- If the broadest independent claim is rejected and cannot be overcome on argument alone, amend to incorporate the microgravity sensor fusion limitation or the cascading position source limitation. These narrow the claims but are substantially more defensible.

### 9.3 Response Strategy: 35 USC 101

Cite:

- *Enfish, LLC v. Microsoft Corp.*, 822 F.3d 1327 (Fed. Cir. 2016)
- *DDR Holdings, LLC v. Hotels.com, L.P.*, 773 F.3d 1245 (Fed. Cir. 2014)

Arguments:

- The invention improves the functioning of the device itself (sensor fusion for a novel operating environment, not merely automating a mental process).
- The claims are tied to a specific technical implementation, not an abstract concept.
- The problem solved (geographic identification in microgravity without GPS) is a technical problem with a technical solution.

### 9.4 Response Deadlines

| Action | Deadline |
|---|---|
| Non-final office action response | 3 months (extendable to 6 months with escalating fees) |
| Final office action response | 3 months (extendable to 6 months with escalating fees) |

### 9.5 After a Final Rejection

**Option A — Request for Continued Examination (RCE):**

- Fee: $480 micro entity / $960 small entity.
- Reopens prosecution with a new non-final office action.
- Budget for 1-2 RCEs.

**Option B — Appeal to PTAB:**

- File Notice of Appeal + Appeal Brief.
- Timeline: 12-18 months for a decision.
- PTAB reversal rate for 103 rejections is meaningful (~30-40%).
- Best option when the examiner is wrong on the law, not merely the facts.

**Option C — AFCP 2.0 (After-Final Consideration Pilot):**

- File an amendment after final with a request for AFCP consideration.
- Examiner receives additional search time. Often resolves cases without requiring an RCE.

---

## Phase 10: Notice of Allowance and Grant

### 10.1 Upon Receiving Notice of Allowance

- Pay the issue fee within 3 months: $300 micro / $600 small entity.
- Review the allowed claims one final time. This is the last opportunity to correct errors.
- Patent grants approximately 4 weeks after issue fee payment.

### 10.2 Post-Grant Actions

**Maintenance fees** (mark calendar):

| Due Date | Micro Entity | Small Entity |
|---|---|---|
| 3.5 years after grant | $400 | $800 |
| 7.5 years after grant | $900 | $1,800 |
| 11.5 years after grant | $1,850 | $3,700 |

**Continuation applications:** Consider filing a continuation before grant to pursue additional claim sets (broader claims, different dependent claim combinations, or claims directed to other embodiments).

**Patent marking:** Once granted, mark the app with the patent number per 35 USC 287 to preserve damages rights in any future enforcement action.

---

## Budget Summary

| Item | Micro Entity | Small Entity |
|---|---|---|
| Provisional filing | $320 | $640 |
| Non-provisional filing + search + examination | ~$800 | ~$1,600 |
| Drawings (self-prepared) | $0 | $0 |
| IDS (filed with application) | $0 | $0 |
| Track One (optional) | $1,000 | $2,000 |
| 1-2 office action responses (attorney time only) | $0 | $0 |
| 1 RCE (if needed) | $480 | $960 |
| Issue fee | $300 | $600 |
| PCT (optional) | ~$2,000-4,000 | ~$2,000-4,000 |
| **Total (US only, no Track One)** | **~$1,900** | **~$3,800** |
| **Total (US + PCT + Track One)** | **~$5,000-7,000** | **~$8,000-10,000** |

Since the inventor is also the attorney of record, no external counsel fees apply. The primary cost beyond filing fees is the inventor/attorney's time.

---

## Immediate Next Steps

1. **This week:** Start the structured prior art search (Phase 1.1). Pull full text of the 6 key references listed in Section 1.2.
2. **Next week:** Build the prior art matrix (`docs/patent/PRIOR_ART_MATRIX.md`). Finalize claim hierarchy.
3. **Weeks 3-4:** Draft specification, converting `docs/TECH_SPEC.md` into patent prose. Prepare drawings.
4. **Weeks 4-5:** File provisional application via USPTO Patent Center.

---

## Appendix A: Prior Art References

### Directly Relevant

| Reference | Title / Description | Key Distinction from Present Invention |
|---|---|---|
| Windows on Earth (NASA/TERC, 2012) | Desktop simulation of Earth view from ISS for astronaut photography target identification. Uses GeoFusion digital Earth visualization. | Not AR, not real-time sensor-fused, not overlaid on camera feed, not a mobile app. Pre-rendered desktop simulation. |
| US10565798B2 (Mobilizar, 2018) | AR interactions with a physical globe. Camera recognizes geography on a globe's surface and overlays AR content. | Different use case: educational tool for a physical desk globe. No orbital position input, no sensor fusion for orientation. |
| ISS Real-Time Tracker 3D | Ground-based app showing ISS position on a 3D globe with planned AR sky-viewing feature. | Designed for ground users looking UP at ISS, not astronauts looking DOWN at Earth. |
| Spot the Station (NASA) | Ground-based ISS spotting app with AR trajectory overlay. | For ground users. No 3D globe overlay, no orbital observer perspective. |
| ESA AR for Astronauts | HoloLens-based AR for maintenance procedures aboard ISS. | Different problem domain: equipment maintenance support, not Earth observation. |

### Partially Relevant

| Reference | Overlap | Distinction |
|---|---|---|
| US9488488B2 (Google — AR Maps) | GPS + compass + accelerometer for AR map overlay | Ground-based, GPS-dependent, no orbital position |
| US20200126265A1 (AR System) | Position + orientation -> camera -> AR overlay | Generic AR framework, no orbital/globe specifics |
| US20110141254A1 (Mobile AR) | 3D orientation data for AR display | General mobile AR, not orbital context |
| US7315259B2 (Google — Tile Caching) | Offline tile caching on constrained devices | Well-established prior art; defines boundary for Claim D |
| US7693702B1 (Space Systems AR) | AR visualization of satellite data, military SA | Visualizes satellite systems, not Earth geography from orbit |
| US9824495B2 / US10565796B2 (AR Scene Compositing) | Semi-transparent overlay compositing | General compositing technique, no globe or orbital context |

---

## Appendix B: CPC Classifications to Search

| CPC Code | Description |
|---|---|
| `G06T19/006` | AR with 3D objects |
| `G01C21/20` | Navigation using satellite position |
| `G01C21/26` | Navigation by magnetometer |
| `G02B27/0172` | AR display systems |
| `B64G1/10` | Crew accommodation in spacecraft |
| `G09B29/10` | Globe-based teaching/display |
| `H04N7/18` | Camera with overlay systems |
