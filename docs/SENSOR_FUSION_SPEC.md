# Sensor Fusion — Expected Behavior Specification

This document describes **what the user should see** for every combination of device orientation and telemetry source. It is the authoritative reference for reimplementing sensor fusion. No code assumptions are made — only physical behavior and user expectations.

---

## Terminology

| Term | Meaning | Range |
|------|---------|-------|
| **PITCH** | How far the device camera is tilted from "looking straight down" toward "looking at the horizon" and beyond to "looking straight up" | 0° = nadir (straight down), 90° = horizon, 180° = zenith (straight up) |
| **YAW** (compass heading) | The compass direction the device camera is pointing, measured clockwise from geographic north | 0° = North, 90° = East, 180° = South, 270° = West |
| **ROLL** (HDG / cross-axis tilt) | The left-right tilt of the device around the camera axis — i.e., how much the horizon line is tilted in the viewfinder | 0° = level, positive = right ear down, negative = left ear down |

These three values together define "where the camera is pointing" and "how it is rotated around that pointing axis."

---

## Scenario 1: User on Earth's Surface, ISS Telemetry

The user is standing on the ground holding a phone. The app receives ISS orbital position (lat, lon, altitude ~408 km, bearing, velocity). The globe view shows what the ISS would see from orbit, but the user's device orientation controls the camera direction.

### 1.1 Phone flat on a table, screen facing up

- **Physical pose**: Device is horizontal. Camera (back) points straight down at the table.
- **PITCH** = 0° (nadir)
- **YAW** = whatever compass direction the top of the phone faces
- **ROLL** = 0° (level — gravity is perpendicular to the screen)
- **Globe view**: Looking straight down at Earth from ISS altitude. The ground directly below the ISS sub-satellite point fills the view. Rotating the phone on the table (like a lazy susan) changes YAW — the compass direction rotates and the ground below scrolls accordingly. The view stays nadir-locked.

### 1.2 Phone upright in portrait, screen facing the user

- **Physical pose**: Device is vertical, held in front of the user like reading a text message.
- **PITCH** = 90° (horizon)
- **YAW** = the compass direction the user is facing (the back of the phone points that way)
- **ROLL** = 0° if held perfectly upright; tilting the phone left or right changes roll
- **Globe view**: Looking toward the Earth's horizon from ISS altitude, in whichever compass direction the user faces. The curvature of the Earth is visible. Stars or space may appear in the upper portion. If the user tilts the phone left, the horizon line tilts (positive roll — right side drops). If the user rotates in a spinning chair, YAW tracks the rotation and the view pans around the horizon.

### 1.3 Phone held at 45° — halfway between flat and upright

- **PITCH** = ~45°
- **YAW** = compass direction of the back of the phone
- **ROLL** = 0° if not tilted sideways
- **Globe view**: Looking at the Earth at a 45° angle from ISS altitude. More ground is visible than at the horizon, but the view is not straight down. The sub-satellite point is off to one side.

### 1.4 Phone upside-down, screen facing the table

- **PITCH** = 180° (zenith — camera points straight up)
- **YAW** = compass direction of the bottom of the phone (top is now pointing down)
- **ROLL** = 0°
- **Globe view**: Looking straight up from the ISS — away from Earth into space. Stars and blackness. (This is a valid orientation: the user is "looking up" from the station.)

### 1.5 Phone upright, tilted 30° to the right

- **PITCH** = 90°
- **YAW** = compass direction the phone faces
- **ROLL** = +30° (right ear down)
- **Globe view**: Horizon view, but the horizon line is tilted 30° — the right side of the screen shows more Earth, the left side shows more space. This matches what you'd see if you tilted your head 30° to the right while looking out a window.

### 1.6 User slowly rotating in a chair, phone held upright

- **PITCH** = 90° (constant)
- **YAW** = smoothly increasing from 0° → 360° as the user completes a full rotation
- **ROLL** = ~0° (constant, assuming steady hands)
- **Globe view**: A smooth 360° panoramic sweep of the Earth's horizon from the ISS. North, East, South, West pass through the view sequentially. The horizon line stays level.

### 1.7 User walks from desk to window, tilting phone from flat to upright

- **PITCH** = smoothly transitions from 0° (flat) → 90° (upright)
- **YAW** = tracks whatever direction the user is moving/facing
- **ROLL** = ~0°
- **Globe view**: Smooth transition from looking straight down at the ground below the ISS to looking at the horizon. The ground "recedes" as the view angle changes.

---

## Scenario 2: User in Orbit (ISS), ISS Telemetry

The user is physically aboard the ISS. The phone receives the same ISS telemetry. The key difference: **the device is in microgravity**, so the accelerometer reads near-zero and cannot determine "which way is down."

### 2.1 The accelerometer problem

On the ground, the accelerometer provides a reliable gravity vector that anchors pitch and roll. In microgravity, there is no gravity vector. The accelerometer reads noise near zero. This means:

- **Pitch and roll cannot be determined from the accelerometer alone.**
- The gyroscope still works and tracks rotational changes, but it drifts over time without a correction source.
- The magnetometer still works and provides a heading reference.

### 2.2 What should replace the accelerometer?

Two options, in priority order:

1. **Horizon detection (camera)**: If the camera can see the Earth's limb (the curved bright edge against the blackness of space), image processing can determine:
   - Which direction is "down" (toward the center of the Earth disk) — this gives pitch and roll correction
   - How large the Earth disk appears — this cross-checks altitude

2. **LVLH frame (orbital telemetry)**: The ISS telemetry provides position and velocity. From these, the Local Vertical Local Horizontal frame can be computed:
   - **Nadir** (local "down") = direction from ISS toward Earth center
   - **Along-track** (local "forward") = velocity direction
   - **Cross-track** = nadir × along-track

   If the astronaut holds the phone in a "nadir-pointing" pose (screen facing Earth, top pointing along-track), the LVLH frame provides a known orientation reference. But the astronaut can freely rotate the phone, so the LVLH frame can only serve as a *drift correction* reference, not an absolute orientation — unless the astronaut deliberately aligns the phone.

### 2.3 Expected behavior in orbit

| Device state | PITCH | YAW | ROLL | Globe view |
|---|---|---|---|---|
| Phone pointed at Earth (screen facing window toward Earth) | ~0° | Compass direction toward Earth center from device's perspective | ~0° | Straight down at Earth, same as ground scenario 1.1 |
| Phone pointed at horizon (perpendicular to nadir) | ~90° | Direction along the horizon | ~0° | Earth horizon with curvature visible |
| Phone pointed away from Earth | ~180° | Direction into space | ~0° | Stars and space |
| Phone freely tumbling (astronaut lets go) | Gyro tracks rotation; drifts over time without correction | Gyro tracks; magnetometer provides slow correction | Gyro tracks; drifts | View rotates smoothly following the phone. Over time (minutes), drift accumulates unless horizon detection or manual recalibration corrects it. |

### 2.4 Sensor fusion priority in orbit

1. **Gyroscope** — always primary for short-term tracking (all three axes)
2. **Horizon detection** — highest-priority correction for pitch and roll (when the camera can see Earth)
3. **LVLH frame** — fallback correction for pitch and roll (weaker, assumes rough alignment)
4. **Magnetometer** — heading correction (works in orbit, though the ISS's magnetic environment adds noise)
5. **Accelerometer** — **ignored** in orbit (reads near-zero; only noise)

---

## Scenario 3: User in Aircraft or Suborbital Vehicle

The user is aboard an aircraft, high-altitude balloon, or suborbital rocket. They may be at altitudes from 10 km to 100+ km. They are receiving telemetry from some source (their own GPS, a flight computer, or ISS telemetry for comparison).

### 3.1 Key differences from ground use

- The accelerometer works (there is gravity, or at least apparent gravity during powered flight), but it includes acceleration artifacts from the vehicle (turns, turbulence, thrust).
- At high altitudes, the horizon is visibly curved and lower than eye-level.
- The vehicle may be banked (roll), pitched (climb/descent), or yawing (turning).

### 3.2 Expected behavior

The sensor fusion should behave identically to the ground scenario (Scenario 1), because the accelerometer still provides a usable gravity reference. The view shows what the telemetry source's position would see — if using ISS telemetry, the user sees the ISS view; if using the vehicle's own GPS, the user sees their own aerial view.

| Device state | PITCH | YAW | ROLL | Globe view |
|---|---|---|---|---|
| Phone flat on tray table | 0° | Compass heading | 0° | Straight down from telemetry altitude |
| Phone held up to window | ~90° | Direction window faces | 0° | Horizon from telemetry altitude |
| Phone held up, aircraft banking 20° | ~90° | Direction window faces | ~20° (tracks the bank if phone is held relative to aircraft; tracks gravity if hand-held freely) | Tilted horizon |

### 3.3 Vehicle acceleration filtering

During aggressive maneuvers (turns, turbulence), the accelerometer reports apparent gravity that includes centripetal and linear acceleration. This causes the pitch/roll reference to jump. The complementary filter's alpha parameter controls how much the accelerometer affects the fused output:

- **Higher alpha** (e.g., 0.98–0.99): trusts the gyro more, smoother output, but slower to correct genuine orientation changes
- **Lower alpha** (e.g., 0.90–0.95): responds faster to real changes, but more susceptible to acceleration artifacts

For aircraft use, a slightly higher alpha may be preferable. This could be a user setting in the future.

---

## Sensor Axis Mapping Summary

The phone has three sensor axes (X, Y, Z) and three orientation angles (pitch, yaw, roll). The mapping depends on whether the phone is in portrait or landscape mode.

### Portrait mode (phone upright, short edge on bottom)

| Sensor axis | Direction | Orientation angle |
|---|---|---|
| X | Points right (along short edge) | Pitch rotation axis — tilting phone forward/backward rotates around X |
| Y | Points up (along long edge) | Yaw rotation axis — spinning the phone on a table rotates around Y |
| Z | Points out of screen (toward user) | Roll rotation axis — tilting phone left/right rotates around Z |

**Accelerometer gravity mapping** (phone at rest):
- Phone flat, screen up: gravity along -Z → pitch 0° (nadir)
- Phone upright: gravity along -Y → pitch 90° (horizon)
- Phone flat, screen down: gravity along +Z → pitch 180° (zenith)

**Gyroscope mapping**:
- gyro.x = pitch rate (forward/backward tilt speed)
- gyro.y = yaw rate (compass rotation speed)
- gyro.z = roll rate (left/right tilt speed)

### Landscape mode (phone on its side, long edge on bottom)

| Sensor axis | Direction | Orientation angle |
|---|---|---|
| X | Points up (along short edge, which is now vertical) | Roll rotation axis — tilting phone left/right |
| Y | Points right (along long edge, which is now horizontal) | Yaw rotation axis — spinning the phone on a table |
| Z | Points out of screen (toward user) | Pitch rotation axis — tilting phone forward/backward |

**Accelerometer gravity mapping** (phone at rest, landscape):
- Phone flat, screen up: gravity along -Z → pitch 0° (nadir)
- Phone upright (landscape): gravity along -X → pitch 90° (horizon)
- Phone flat, screen down: gravity along +Z → pitch 180° (zenith)

**Gyroscope mapping** (landscape):
- gyro.x = roll rate
- gyro.y = yaw rate
- gyro.z = pitch rate

> **Critical note**: The axis-to-angle mapping changes between portrait and landscape. The sensor fusion must know which orientation mode is active (from the orientation lock setting) to correctly interpret raw sensor data.

---

## Complementary Filter Behavior

The complementary filter blends two signals:

1. **Gyroscope** (short-term, accurate for fast changes, drifts over time)
2. **Reference** (long-term, noisy but doesn't drift — typically accelerometer for pitch/roll, magnetometer for yaw)

The blend formula is:

```
fused = alpha × gyro_prediction + (1 - alpha) × reference
```

Where `alpha` is typically 0.98 (trust gyro 98%, reference 2%).

### What the user should experience

- **Instant response**: When the user tilts or rotates the phone, the view should respond immediately (gyro dominates).
- **No drift**: When the user holds the phone steady, the view should not slowly creep in any direction (reference corrects gyro drift).
- **No jitter**: The view should be smooth, not jittery (gyro smooths out noisy reference).
- **Correct convergence**: If the phone starts in an unknown orientation (e.g., cold start), the view should settle to the correct orientation within 2–3 seconds (reference pulls the fused value to ground truth).

### What should NOT happen

- Pitch slowly drifting to 0 when the phone is held at a non-zero angle
- View snapping or jumping when the reference correction kicks in
- Different behavior when the phone is in landscape vs portrait (after accounting for axis remapping)
- Yaw spinning when the user is stationary (magnetometer interference should be detected and suppressed)

---

## Touch Steering Override

When the user touches and drags on the screen:

1. **Sensor fusion is paused** — the gyro/accel/mag stop driving the view
2. **Drag gesture controls the view** — horizontal drag changes yaw, vertical drag changes pitch
3. **Roll stays at the last sensor value** — the user cannot drag-to-roll (this would be disorienting)
4. **On release**, the view smoothly eases back to the current sensor orientation (both pitch and yaw) over ~0.5–1 second. The ease-back uses exponential decay so it feels natural, not abrupt.

This allows the user to "look around" freely and then return to the device-tracked view.
