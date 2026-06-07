# Patent Filing Guide: *What On Earth?!* (Beginner Edition)

**Status:** Draft
**Date:** 2026-03-09

This guide walks you through every step of patenting the *What On Earth?!* app, from scratch. It assumes no prior knowledge of patents, patent law, or the patent system. Every term is explained when first introduced.

---

## Table of Contents

**Part I: Understanding Patents**
1. [What Is a Patent and Why File One?](#1-what-is-a-patent-and-why-file-one)
2. [Key Vocabulary](#2-key-vocabulary)
3. [What Makes Something Patentable?](#3-what-makes-something-patentable)
4. [Types of Patents](#4-types-of-patents)
5. [The Patent Office and How It Works](#5-the-patent-office-and-how-it-works)
6. [Should You Hire a Patent Attorney?](#6-should-you-hire-a-patent-attorney)

**Part II: What Is Patentable in *What On Earth?!***
7. [Summary of the Invention](#7-summary-of-the-invention)
8. [The Parts That May Be Patentable](#8-the-parts-that-may-be-patentable)
9. [The Parts That Probably Are Not Patentable](#9-the-parts-that-probably-are-not-patentable)
10. [What Already Exists (Prior Art)](#10-what-already-exists-prior-art)
11. [Overall Assessment](#11-overall-assessment)

**Part III: The Process, Step by Step**
12. [Phase 1: Research What Already Exists](#phase-1-research-what-already-exists)
13. [Phase 2: Decide What to Protect](#phase-2-decide-what-to-protect)
14. [Phase 3: Write the Patent Application](#phase-3-write-the-patent-application)
15. [Phase 4: File a Provisional Application](#phase-4-file-a-provisional-application)
16. [Phase 5: Use the 12-Month Window](#phase-5-use-the-12-month-window)
17. [Phase 6: File the Full (Non-Provisional) Application](#phase-6-file-the-full-non-provisional-application)
18. [Phase 7: Decide About International Protection](#phase-7-decide-about-international-protection)
19. [Phase 8: The Patent Office Reviews Your Application](#phase-8-the-patent-office-reviews-your-application)
20. [Phase 9: Responding to Rejections](#phase-9-responding-to-rejections)
21. [Phase 10: Getting Your Patent Granted](#phase-10-getting-your-patent-granted)

**Part IV: Reference Material**
22. [Budget Summary](#budget-summary)
23. [Complete Timeline](#complete-timeline)
24. [Glossary](#glossary)
25. [Prior Art Reference Table](#prior-art-reference-table)

---

# Part I: Understanding Patents

## 1. What Is a Patent and Why File One?

### What Is a Patent?

A patent is a legal right granted by a government that gives you, the inventor, the exclusive right to make, use, sell, or license your invention for a limited time (20 years from the filing date in the United States). In exchange, you publicly disclose how your invention works, so that after the patent expires, anyone can use it.

Think of it as a deal: you share your invention with the world, and in return, the government gives you a temporary monopoly on it.

### What Does a Patent Actually Protect?

A patent does **not** protect an idea. It protects a specific, concrete implementation of an idea. You cannot patent "an app that helps astronauts identify geography." You *can* patent "a method for providing augmented-reality geographic identification to an observer aboard an orbiting spacecraft by combining orbital position data with device sensor fusion to render a correctly-oriented 3D globe over a live camera feed."

The difference is specificity. Patents protect *how* you do something, not *what* you want to do.

### Why File a Patent for This App?

There are several reasons you might want to patent *What On Earth?!*:

- **Prevent copying.** If a competitor (say, another company selling tools to space agencies) builds the same thing, a patent lets you stop them or require them to license your technology.
- **Licensing revenue.** Space agencies, commercial station operators, or other companies might pay to use your patented technology.
- **Business value.** Patents are assets. They increase the value of your company or project if you ever seek investment or acquisition.
- **Defensive protection.** If someone else patents something similar, having your own patent gives you a stronger position in any dispute.

### When Not to File

Patents cost money and take years to obtain. They may not be worth it if:

- Your invention is not meaningfully different from what already exists.
- You have no intention of commercializing the technology or licensing it.
- The market is too small to justify the cost.

For *What On Earth?!*, the commercial LEO station market is growing, and the technology has genuine novel aspects, so filing is likely worthwhile.

---

## 2. Key Vocabulary

Before going further, here are the essential terms you will encounter throughout this guide. A more complete glossary is in [Section 24](#glossary).

| Term | Plain-English Definition |
|---|---|
| **Patent** | A government-granted right to exclusively use your invention for 20 years. |
| **Inventor** | The person who actually conceived the invention. This must be a real person (not a company). |
| **USPTO** | The United States Patent and Trademark Office. The government agency that reviews and grants patents. |
| **Claims** | The legal sentences at the end of a patent that define exactly what is protected. Everything else in the patent exists to support and explain the claims. Claims are the most important part. |
| **Specification** | The written description of your invention. It explains how the invention works in enough detail that someone skilled in the field could build it. |
| **Prior art** | Everything that was publicly known before your invention. This includes existing patents, published papers, products, apps, websites, and more. If your invention already exists in the prior art, you cannot patent it. |
| **Provisional application** | A lightweight, cheaper filing that establishes your "priority date" (the date you officially staked your claim). It gives you 12 months to file the full application. |
| **Non-provisional application** | The full, formal patent application that gets examined by the patent office. |
| **Office action** | A letter from the patent examiner explaining why they are rejecting (or allowing) your claims, and what you need to do next. |
| **Prosecution** | The back-and-forth process between you and the patent examiner, where you argue for your claims and potentially modify them until the patent is granted or finally rejected. (This has nothing to do with criminal prosecution.) |
| **Examiner** | The USPTO employee who reviews your application and decides whether to grant your patent. |

---

## 3. What Makes Something Patentable?

To receive a patent in the United States, your invention must pass four tests. These are defined by federal law (Title 35 of the United States Code). Here is what each test means:

### Test 1: Eligible Subject Matter (35 USC 101)

Your invention must be a "process, machine, manufacture, or composition of matter." Software and apps *can* be patented, but they face extra scrutiny. The patent office will ask: "Is this just an abstract idea implemented on a computer?" If the answer is yes, it fails this test.

**For *What On Earth?!*:** The invention involves specific technical processes (sensor fusion, real-time 3D rendering, AR compositing) solving a specific technical problem (geographic identification in microgravity without GPS). This is more than an abstract idea, so it likely passes this test.

### Test 2: Novelty (35 USC 102)

Your invention must be new. If anyone, anywhere in the world, has already publicly described, built, or sold the exact same thing, your invention is not novel and cannot be patented.

**For *What On Earth?!*:** No existing product or publication combines orbital position data + device sensor fusion + 3D globe AR overlay on a camera feed for a spacecraft observer. The invention appears to be novel.

### Test 3: Non-Obviousness (35 USC 103)

Even if your invention is new, it must also be non-obvious. This means that a hypothetical "person having ordinary skill in the art" (a competent engineer familiar with AR, sensor fusion, and orbital mechanics) would not have been able to arrive at your invention simply by combining existing, known technologies in a straightforward way.

This is the hardest test and the most common reason patents are rejected. The patent examiner will often find two or three existing references and argue: "It would have been obvious to combine Reference A with Reference B to arrive at your invention."

**For *What On Earth?!*:** This is the main challenge. Each individual component (AR overlays, sensor fusion, 3D globes, tile caching, orbital tracking) exists separately. The examiner will likely argue the combination is obvious. However, there are strong arguments that it is not obvious, because the orbital environment creates unique technical problems (no GPS, no gravity vector for sensors, severe magnetic interference) that existing technologies do not address. More on this in [Section 11](#11-overall-assessment).

### Test 4: Enablement (35 USC 112)

Your patent application must describe the invention in enough detail that someone skilled in the field could actually build it. You cannot patent a vague concept. You must explain *how* it works.

**For *What On Earth?!*:** The detailed technical specification (`docs/TECH_SPEC.md`) and working codebase would easily satisfy this requirement.

---

## 4. Types of Patents

There are three types of patents in the US. Only one is relevant here:

| Type | What It Protects | Relevant? |
|---|---|---|
| **Utility patent** | How something works (processes, machines, systems) | **Yes. This is what we are filing.** |
| **Design patent** | How something looks (ornamental appearance) | No. The app's visual design could theoretically be design-patented, but that is not the focus here. |
| **Plant patent** | New plant varieties | No. |

A utility patent lasts 20 years from the filing date of the non-provisional application.

---

## 5. The Patent Office and How It Works

### The USPTO

The United States Patent and Trademark Office (USPTO) is the federal agency that grants US patents. It is located in Alexandria, Virginia, but all interaction is done electronically through their website, [Patent Center](https://patentcenter.uspto.gov/).

### How the Process Works (Big Picture)

Here is the lifecycle of a patent application, simplified:

```
You file an application
        |
        v
USPTO assigns an examiner
        |
        v
Examiner searches for prior art
        |
        v
Examiner sends you an "office action"
(usually a rejection explaining why your claims are not patentable)
        |
        v
You respond (argue why the examiner is wrong, or modify your claims)
        |
        v
This back-and-forth may repeat 1-3 times
        |
        v
Either: Patent is GRANTED (you win)
   or: Patent is finally REJECTED (you can appeal or give up)
```

The entire process typically takes **2-4 years** from the date you file the full (non-provisional) application.

### Examiner Expectations

Patent examiners are specialized. Your application will be assigned to an examiner who handles AR, computer graphics, or navigation technology. They are generally thorough and will find prior art you may not have found yourself. Their job is to reject claims that do not meet the legal standards, and to allow claims that do.

It is extremely common — even expected — for your first filing to be rejected. This does not mean your invention is not patentable. It means the examiner wants you to narrow or clarify your claims. The back-and-forth process of responding to rejections is called **prosecution**, and it is a normal part of getting a patent.

---

## 6. Should You Hire a Patent Attorney?

### What a Patent Attorney Does

A patent attorney (or patent agent) is a professional licensed to represent inventors before the USPTO. They have passed the patent bar exam and typically have a technical background (engineering, science, or computer science).

They can help with:
- Searching for prior art
- Drafting the specification and claims (this is a specialized form of legal writing)
- Filing the application
- Responding to office actions
- Appealing rejections

### Cost If You Hire One

Patent attorneys typically charge:
- **$8,000-15,000** to draft and file a utility patent application (software/app inventions)
- **$2,000-5,000** per office action response
- **Total through grant: $15,000-30,000+**

### Filing Without an Attorney (Pro Se)

You are legally allowed to file a patent application yourself, without an attorney. This is called filing **pro se**. The USPTO will accept your application regardless.

However, be aware:
- Patent claims are written in a highly specific legal style. Poorly drafted claims may be too narrow (protecting very little), too broad (easily rejected), or ambiguous (unenforceable).
- Responding to office actions requires understanding patent law and examiner procedure.
- Mistakes can permanently limit or destroy your patent rights.

If you choose to file pro se, this guide provides the structure and substance you need, but consider having a patent attorney review your claims before filing, even if they do not handle the rest of the process. A one-time review typically costs $1,000-3,000 and can prevent costly mistakes.

### Recommendation for This Invention

The core technology in *What On Earth?!* has moderate-to-strong patentability in its strongest claim areas. The investment in at least a claim review by a patent attorney is likely worthwhile, given the potential commercial value of the invention in the growing commercial space sector.

---

# Part II: What Is Patentable in *What On Earth?!*

## 7. Summary of the Invention

*What On Earth?!* is an augmented reality (AR) mobile app designed for astronauts aboard the International Space Station (ISS) and future orbital platforms. It solves a specific problem: astronauts looking out a window at Earth often cannot tell what geography they are seeing.

The app works by:

1. **Knowing where the spacecraft is.** It gets the spacecraft's position (latitude, longitude, altitude) from a live internet feed. If the internet is unavailable (which is common in orbit), it automatically switches to calculating the position itself using the spacecraft's known orbit.

2. **Knowing which way the device is pointing.** It uses the phone's built-in sensors (compass/magnetometer, accelerometer, and gyroscope) to figure out the device's orientation: which direction it faces, how it is tilted, and how it is rotated.

3. **Rendering a 3D globe.** It draws a three-dimensional model of Earth, oriented so that it matches what the astronaut would see out the window.

4. **Overlaying the globe on the camera.** The camera shows the real view. The 3D globe is drawn on top of the camera feed, semi-transparently, so that countries, borders, cities, and coastlines are labeled right where the astronaut sees the actual Earth.

The result: hold up the phone toward a window, and instantly see which country, city, or ocean you are looking at.

---

## 8. The Parts That May Be Patentable

After researching what already exists (prior art), the following aspects of the invention appear to be novel and potentially non-obvious:

### Claim Area A: Orbital AR Earth Identification (Strongest Candidate)

**What it is:** The overall method of combining orbital position data with device sensor data to render a correctly-oriented 3D globe overlay on a live camera feed, specifically for someone aboard an orbiting spacecraft looking down at Earth.

**Why it may be patentable:** No existing product or patent combines all of these elements. Ground-based AR map apps exist, but they rely on GPS (which does not work reliably in orbit) and are designed for someone standing on Earth's surface. ISS tracking apps exist, but they are designed for people on the ground looking *up* at the space station, not astronauts looking *down* at Earth. NASA's "Windows on Earth" tool helps astronauts identify geography, but it is a desktop simulation — not augmented reality, not sensor-driven, and not overlaid on a camera feed.

**Strength: Moderate-Strong.**

### Claim Area B: Sensor Fusion in Microgravity (Most Defensible)

**What it is:** The way the app combines data from the phone's compass, accelerometer, and gyroscope to determine device orientation, specifically adapted for the unique challenges of the space environment.

**Why it may be patentable:** Every existing AR app on Earth uses the accelerometer to detect gravity (which way is "down"). This gives the app a reliable reference for the device's pitch and roll. But in orbit, the spacecraft and everything inside it are in continuous free-fall — a state called microgravity. The accelerometer reads near-zero because there is no net gravitational pull to measure. This means every standard sensor fusion algorithm fails in orbit.

Additionally, the inside of a metal-hulled spacecraft like the ISS is full of electrical equipment that creates severe magnetic interference, distorting the compass readings far more than on Earth's surface. The app must detect this interference and compensate for it.

These are genuine, non-trivial technical challenges that no prior art addresses.

**Strength: Strong.**

### Claim Area C: Cascading Position Source (Moderate)

**What it is:** The system that automatically switches between three ways of knowing the spacecraft's position: (1) a live internet feed, (2) calculating the position from the spacecraft's known orbit using an algorithm called SGP4, or (3) a manually entered fixed position for training. The switching happens automatically when the internet is lost, with no user intervention.

**Why it may be patentable:** While "fallback" systems are common in software, the specific combination of a live orbital API falling back to onboard TLE/SGP4 propagation, with automatic switching and a user-visible status indicator, is not found in existing prior art as a unified system.

**Strength: Moderate.**

---

## 9. The Parts That Probably Are Not Patentable

The following aspects of the app, while technically impressive, are too well-covered by existing technology to be patentable on their own:

### Offline Map Tile Caching

Pre-downloading map tiles to a device for offline use and serving them from a local server is a well-established technique. Google has a patent on tile caching from 2007 (US7315259B2). Mapbox, Apple Maps, and many other apps do this. While the specific architecture (a Dart `shelf` HTTP server in a background isolate) is a clever implementation, it is not novel enough for a patent.

### Personal Pins with Orbital Pass Prediction

Marking locations and calculating when a satellite will pass overhead is standard orbital mechanics. Tools like PREDICT (open source, 1991) and dozens of satellite tracking apps and websites have done this for decades. The pass prediction algorithm uses publicly available formulas.

### Transparent WebView Over Camera

Displaying a web-based 3D rendering (CesiumJS in a WebView) over a camera feed is an implementation technique, not a novel invention. WebView transparency is a documented feature of the `flutter_inappwebview` library.

These components can still be described in the patent specification (and should be, for completeness), but they should not be the basis of your primary patent claims.

---

## 10. What Already Exists (Prior Art)

Before you can patent something, you need to know what already exists. Here are the most important existing technologies, products, and patents related to *What On Earth?!*:

### Closest Existing Product: Windows on Earth

**What it is:** A software tool developed by TERC, Inc. and the Association of Space Explorers, selected by NASA in 2012 to help ISS astronauts identify photography targets. It renders a simulated view of Earth from the ISS using a digital Earth visualization system, complete with terrain, satellite imagery, clouds, day/night cycles, and city lights.

**How it is different from *What On Earth?!*:**
- It is a desktop simulation, not augmented reality
- It does not use device sensors for orientation
- It does not overlay on a camera feed
- It is not a mobile app
- It does not update in real-time as you move the device

This is the closest prior art, but it has major differences from our invention.

### Closest Existing Patent: US10565798B2 (AR Globe)

**What it is:** A patent granted to Mobilizar Technologies in 2018 for "a method and system for enabling augmented reality interactions with a globe." It uses a phone camera to recognize a physical desk globe, identifies which geographic region is visible, and overlays AR information on the screen.

**How it is different from *What On Earth?!*:**
- It interacts with a *physical* globe sitting on a table, not a virtual 3D globe
- It uses camera image recognition (computer vision), not orbital position data or sensor fusion
- It is an educational toy, not a spacecraft tool
- It has no concept of orbital position, microgravity, or real-time orientation

### Ground-Based ISS Tracking Apps

Apps like **ISS Real-Time Tracker 3D**, **Spot the Station** (NASA), and **Orbitrack** show the ISS position on a globe or overlay AR trajectory lines in the sky.

**How they are different from *What On Earth?!*:**
- They are designed for people *on the ground* looking *up* at the space station
- Our app is designed for people *aboard the space station* looking *down* at Earth
- They use GPS for the user's position; our app uses orbital position data for the spacecraft's position
- They do not face microgravity sensor challenges

### ESA's AR for Astronaut Maintenance

The European Space Agency developed HoloLens-based AR systems to help astronauts with equipment maintenance aboard the ISS — overlaying step-by-step repair instructions on physical hardware.

**How it is different from *What On Earth?!*:**
- Completely different purpose (equipment repair, not Earth observation)
- Uses a HoloLens headset, not a smartphone
- Does not involve a globe, geographic data, or orbital position

### Other Relevant Patents

| Patent Number | What It Covers | Why It Matters |
|---|---|---|
| US9488488B2 (Google) | AR maps using GPS, compass, and accelerometer | Shows that sensor-fused AR overlays are known — but GPS-dependent and ground-based |
| US20200126265A1 | General AR system using position and orientation data | Shows general AR compositing is known — but no orbital context |
| US7315259B2 (Google) | Offline map tile caching on mobile devices | Shows tile caching is well-established prior art |
| US7693702B1 | AR visualization of satellite system data for military situational awareness | Combines "space" and "AR" — but visualizes satellite *systems*, not Earth geography from orbit |

A complete reference table is in [Section 25](#prior-art-reference-table).

---

## 11. Overall Assessment

### Can This Invention Be Patented?

**Most likely yes, but with important caveats.**

The strongest path to a patent is through **Claim Area A** (the overall method of orbital AR Earth identification) combined with **Claim Area B** (sensor fusion adapted for microgravity). These represent a genuinely novel combination of technologies applied to a problem that no one has solved before in this way.

### The Main Risk: Obviousness

The biggest challenge will be the "non-obviousness" test. The patent examiner will almost certainly argue:

> "An engineer could have taken an existing AR map app (which uses sensors to orient a map over a camera feed) and simply applied it to the orbital context (using ISS position data instead of GPS). This combination would have been obvious."

### Why It Is Actually Not Obvious

The strongest counter-arguments are:

1. **Standard sensor fusion breaks in microgravity.** Every ground-based AR app uses the accelerometer to find "down" (the gravity vector). In orbit, there is no detectable gravity. An engineer could not simply take an existing AR app to orbit — they would need to fundamentally rethink how orientation works. The prior art teaches *toward* using gravity for sensor fusion, which means it teaches *away from* the orbital use case.

2. **GPS does not work in orbit.** Every ground-based AR map relies on GPS for positioning. At 400 km altitude, GPS geometry is unreliable. The cascading position source (live API to TLE propagation) is a non-trivial solution to a problem that ground-based apps do not face.

3. **Magnetic interference is extreme inside a spacecraft.** The metal hull and electrical systems distort compass readings far beyond what any ground-based app encounters. The interference detection and calibration system addresses a unique problem.

4. **No one has done it before.** Astronauts have been photographing Earth from orbit for over 60 years and have documented the difficulty of identifying geography. Despite this, no one has built a mobile AR tool that solves this problem. If the solution were obvious, someone would have built it already.

### What to Expect

- The patent application will likely be **initially rejected** (this is normal for ~90% of patent applications).
- You will need to **respond to 1-3 rejections** by arguing your case and potentially narrowing your claims.
- The process will take **2-4 years** and cost **$2,000-10,000** in government fees (more if you hire an attorney).
- There is a reasonable chance of success if the claims are well-drafted and focused on the orbital/microgravity aspects.

---

# Part III: The Process, Step by Step

## Phase 1: Research What Already Exists

**Timeline:** 1-2 weeks
**Cost:** $0 (just your time)

### What You Are Doing and Why

Before you write a patent application, you need to thoroughly search for "prior art" — anything that already exists that is similar to your invention. This serves two purposes:

1. **It helps you write better claims.** If you know what already exists, you can write claims that clearly distinguish your invention from everything else.
2. **It is a legal obligation.** When you file a patent, you are required to tell the patent office about any relevant prior art you are aware of. Deliberately hiding relevant prior art can make your patent unenforceable, even after it is granted.

### Where to Search

#### Patent Databases

These databases let you search existing patents and published patent applications:

- **Google Patents** (patents.google.com) — The easiest to use. Covers US and international patents. Start here.
- **USPTO Patent Full-Text Database** (patft.uspto.gov) — Official US patent database. Covers granted patents.
- **USPTO Application Full-Text Database** (appft.uspto.gov) — Official US database for published applications (not yet granted).
- **Espacenet** (worldwide.espacenet.com) — European Patent Office database. Good for international coverage.

#### Academic / Non-Patent Literature

Published research papers, articles, and technical reports also count as prior art:

- **Google Scholar** (scholar.google.com) — Academic papers
- **IEEE Xplore** (ieeexplore.ieee.org) — Engineering and computer science papers

#### Product / App Research

Existing apps and products also count as prior art, even if they are not patented:

- Search the App Store and Google Play for ISS trackers, AR globe apps, etc.
- Search for NASA and ESA tools for astronaut Earth observation

### What to Search For

Use combinations of these keywords in the databases listed above:

**For the overall concept:**
```
(orbital OR spacecraft OR "space station") AND "augmented reality" AND (globe OR earth OR geographic)
```

**For the sensor fusion aspect:**
```
"sensor fusion" AND (magnetometer OR IMU) AND ("zero gravity" OR microgravity OR "free fall")
```

**For the position cascading aspect:**
```
"position source" AND (TLE OR "two-line element" OR SGP4) AND (fallback OR cascade)
```

#### Patent Classification Codes

Patents are organized into categories called CPC (Cooperative Patent Classification) codes. Searching by these codes can surface relevant patents that keyword searches miss:

| Code | What It Covers |
|---|---|
| `G06T19/006` | Augmented reality with 3D objects |
| `G01C21/20` | Navigation using satellite position |
| `G01C21/26` | Navigation by magnetometer |
| `G02B27/0172` | AR display systems |
| `B64G1/10` | Crew accommodation in spacecraft |
| `G09B29/10` | Globe-based teaching and display |
| `H04N7/18` | Camera with overlay systems |

On Google Patents, you can search by CPC code by entering, for example, `CPC:G06T19/006` in the search bar.

### What to Do with What You Find

For every relevant reference you find, write down:

1. What it is (patent number, product name, paper title)
2. What it teaches (what aspects of the technology does it describe?)
3. How it is different from your invention (what does it *not* do?)

Organize this in a table (a "prior art matrix"). See [Section 25](#prior-art-reference-table) for the references already identified in the initial search. Store your completed matrix in `docs/patent/PRIOR_ART_MATRIX.md`.

---

## Phase 2: Decide What to Protect

**Timeline:** 1 week (can overlap with Phase 1)
**Cost:** $0

### What You Are Doing and Why

A patent does not protect "the app." It protects specific **claims** — precisely worded sentences that define the boundaries of your invention. You need to decide which aspects of your technology you want to claim.

Think of claims like a property deed for a piece of land. The deed does not say "I own the land." It says "I own the land bounded by Oak Street to the north, the river to the south, the fence line to the east, and the highway to the west." Patent claims work the same way — they define the exact boundaries of what you own.

### The Claim Hierarchy

Patent claims come in two flavors:

**Independent claims** stand on their own. They define your invention in broad terms. You typically have 2-3 independent claims.

**Dependent claims** add specific details to an independent claim. They start with "The method of Claim 1, further comprising..." or "The method of Claim 1, wherein..." You typically have 15-18 dependent claims.

Why both? Independent claims cast a wide net. If someone copies your basic concept, even with a different implementation, they infringe the independent claim. Dependent claims are narrower but harder to challenge — they describe specific technical details that the prior art is less likely to cover.

If the patent examiner rejects your broad independent claim, you can "fall back" to a dependent claim. This is like negotiation: you start broad and narrow only if forced to.

### Recommended Claims for *What On Earth?!*

#### Independent Claim 1: The Method

This is the broadest and most important claim. In plain English, it says:

> "A method for helping someone aboard an orbiting spacecraft identify geography by: (1) getting the spacecraft's position, (2) getting the device's orientation from its sensors, (3) rendering a 3D globe aligned to that position and orientation, and (4) overlaying the globe on the camera feed so that features on the globe line up with what the person sees through the window."

In formal patent language (this is approximately how it would be written):

> A method for providing augmented-reality geographic identification to an observer aboard an orbiting spacecraft, comprising:
> - receiving orbital position data of the spacecraft from a position source;
> - receiving orientation data of a handheld device from a sensor fusion engine that combines magnetometer and inertial measurement unit data;
> - rendering a three-dimensional globe model oriented according to the orbital position data and the orientation data; and
> - compositing the rendered globe model over a live camera feed from the handheld device such that geographic features on the globe model are aligned with corresponding features visible through a viewport of the spacecraft.

Notice that this claim does not mention the ISS, CesiumJS, Flutter, specific APIs, or any other implementation detail. It is deliberately broad. Anyone who builds *any* system that performs these four steps aboard *any* orbiting spacecraft would infringe this claim.

#### Independent Claim 2: The System

This describes the same invention as a physical system rather than a method:

> A system comprising: a handheld computing device aboard an orbiting spacecraft, the device including a camera, a magnetometer, and an inertial measurement unit; a position module configured to provide orbital position data of the spacecraft; a sensor fusion engine configured to produce orientation data from the magnetometer and the inertial measurement unit; a rendering engine configured to generate a three-dimensional globe model; and a display configured to composite the globe model over a live feed from the camera.

#### Independent Claim 3: Computer-Readable Medium

This claims the software itself (as stored on a device):

> A non-transitory computer-readable medium storing instructions that, when executed by a processor of a handheld computing device aboard an orbiting spacecraft, cause the device to perform: [same steps as Claim 1].

#### Dependent Claims

These add specific details. Each one starts with "The method of Claim 1, wherein..." Here are the recommended dependent claims:

1. **...the sensor fusion engine operates without a gravity-derived reference vector.** (Covers the microgravity adaptation — the fact that the accelerometer cannot detect gravity in free-fall.)

2. **...the position source cascades from a live telemetry feed to TLE-based SGP4 orbital propagation upon loss of connectivity.** (Covers the automatic fallback system.)

3. **...the method further comprises detecting magnetometer interference exceeding a threshold angular rate and prompting recalibration.** (Covers the interference detection algorithm.)

4. **...hard-iron and soft-iron calibration parameters specific to the spacecraft electromagnetic environment are applied to magnetometer readings.** (Covers the magnetic calibration system.)

5. **...map tile data is pre-cached on the device and served by a local HTTP server to the rendering engine.** (Covers the offline tile architecture.)

6. **...the rendering engine is a WebGL-based globe renderer executing in a transparent browser view layer.** (Covers the specific CesiumJS-in-WebView implementation.)

7. **...the user can mark a geographic location as a personal pin, and the system calculates a next overhead pass using orbital propagation.** (Covers the pin + pass prediction feature.)

8. **...the three-dimensional globe model includes selectively toggleable layers comprising one or more of: borders, terrain, cloud cover, and city labels.** (Covers the layer system.)

9. **...the position source status is persistently displayed to the observer.** (Covers the status indicator.)

10. **...the sensor fusion update rate is at least 50 Hz and the globe rendering rate is at least 30 fps.** (Covers the performance requirements.)

11. **...the orbital position data is received from a public ISS position API as a default, configurable to an operator-provided telemetry feed.** (Covers the configurable position source.)

12. **...pin data is stored locally and synced to a cloud backend using differential last-write-wins conflict resolution when connectivity is available.** (Covers the sync system.)

### Why This Claim Structure Matters

If someone builds an orbital AR Earth-viewing app using a completely different technology stack (not Flutter, not CesiumJS, not Supabase), they would still infringe Independent Claim 1 if they perform the same four fundamental steps.

If the patent examiner rejects Claim 1 as too broad, you can fall back to a dependent claim like #1 (microgravity sensor fusion) or #2 (cascading position source), which are narrower but harder for the examiner to reject because they address problems that no prior art solves.

---

## Phase 3: Write the Patent Application

**Timeline:** 2-4 weeks
**Cost:** $0 (your time only)

### What You Are Writing

A patent application has several required parts. Here is what each one is and what it should contain:

### Part 1: Title

A concise description of the invention. Example:

> "Method and System for Augmented-Reality Geographic Identification from an Orbiting Spacecraft"

Keep it under 15 words. It should be descriptive but not limiting.

### Part 2: Field of the Invention

One or two sentences identifying the general technical area. Example:

> "The present invention relates to augmented reality systems, and more particularly to methods and systems for geographic identification using sensor fusion and orbital position data aboard spacecraft in low Earth orbit."

### Part 3: Background of the Invention

This section describes:

1. **The problem your invention solves.** Astronauts orbit Earth at ~400 km altitude, completing an orbit every 90 minutes. Earth's curvature and the absence of familiar ground-level references make it difficult to identify geography. Cite real NASA/ESA documentation of this problem.

2. **What exists today and why it is insufficient.** Describe:
   - Windows on Earth (TERC, 2012): desktop simulation, not AR, not real-time, not mobile
   - Ground-based ISS tracker apps: designed for ground observers, rely on GPS
   - Standard sensor fusion: relies on gravity vector from accelerometer, which is unavailable in microgravity
   - General AR map patents: GPS-dependent, assume 1G environment

**Important rule:** Do not insult or belittle the prior art. The patent office requires you to describe it neutrally. Say "this approach does not address the microgravity environment," not "this approach is inferior."

### Part 4: Summary of the Invention

A brief (1-2 paragraph) summary of what your invention does and how it solves the problem described in the background. This is a high-level overview, not a detailed technical description.

### Part 5: Brief Description of the Drawings

A numbered list of the figures (drawings) included with your application. Example:

> FIG. 1 is a block diagram illustrating the overall system architecture.
> FIG. 2 is a diagram illustrating the AR compositing stack.
> ...

### Part 6: Detailed Description of Preferred Embodiments

This is the longest and most important part (besides the claims). It is a complete technical description of how the invention works. It must be detailed enough that a skilled engineer could build the invention from this description alone.

For *What On Earth?!*, the project's `docs/TECH_SPEC.md` is essentially a draft of this section. It should be converted into patent prose and organized into these subsections:

1. **System overview** — the device, its sensors, and how the components fit together
2. **Position module** — the three position sources (live API, TLE propagation, static) and the cascading logic
3. **Sensor fusion engine** — how magnetometer, accelerometer, and gyroscope data are combined; the complementary filter; microgravity adaptations; calibration; interference detection
4. **Globe rendering and AR compositing** — how the 3D globe is rendered and overlaid on the camera feed
5. **Tile cache architecture** — how map data is pre-downloaded and served locally
6. **Pin store and pass prediction** — how users mark locations and how overhead passes are calculated
7. **Bridge protocol** — how the native app and the web-based globe renderer communicate
8. **Onboarding and calibration** — the guided setup flow

**Critical tips for this section:**

- **Describe multiple ways to implement each component.** Do not limit yourself to the specific technologies used in the current app. For example:
  > "In one embodiment, the globe renderer is a WebGL-based engine executing in a browser view. In another embodiment, the globe renderer is a native GPU pipeline using Metal or Vulkan."
  This prevents competitors from getting around your patent by using a different technology stack.

- **Include pseudocode** for the key algorithms (sensor fusion, position cascading, pass prediction).

- **Include specific sentences that will help you during prosecution** (when arguing with the examiner). For example:
  > "Unlike terrestrial AR applications that rely on GPS for positioning and gravitational acceleration for determining device pitch and roll, the present invention operates in an environment where neither GPS signals nor a reliable gravity vector is available."

### Part 7: Claims

The claims you drafted in Phase 2. These go at the end of the specification, before the abstract.

### Part 8: Abstract

A single paragraph of 150 words or fewer summarizing the invention. This is the "elevator pitch" of the patent.

### Part 9: Drawings

Black-and-white line drawings illustrating the key aspects of the invention. You will need approximately 8-12 figures:

| Figure | What It Shows |
|---|---|
| 1 | System overview: the device, position sources, sensor fusion engine, renderer, and display |
| 2 | The AR compositing stack: camera layer on bottom, globe layer on top, UI layer above |
| 3 | Flowchart: how the position source cascades from live to TLE to static |
| 4 | Block diagram: sensor fusion engine (magnetometer + accelerometer + gyroscope data flow) |
| 5 | Flowchart: magnetometer calibration and interference detection |
| 6 | Pipeline: position + orientation data flowing into the globe renderer |
| 7 | Tile cache architecture: local HTTP server, LRU eviction, background sync |
| 8 | Pin workflow: tap location, create pin, store, sync, calculate pass |
| 9 | UI mockup: AR view showing status indicators and layer toggles |
| 10 | Sequence diagram: messages between the native app and the globe renderer |
| 11 | Geometry diagram: spacecraft, Earth, elevation angle for pass prediction |
| 12 | Onboarding flow: position confirmation, tile download, calibration steps |

**Drawing requirements:**
- Must be black-and-white line drawings (no photographs, no color)
- Each figure must be numbered (FIG. 1, FIG. 2, etc.)
- Key components must be labeled with reference numerals (e.g., "102" for the sensor fusion engine) that match the written description
- You can create these yourself using free tools like draw.io and export as PDF
- For the provisional application (Phase 4), informal sketches are acceptable. For the full application (Phase 6), they must meet the USPTO's formal requirements.

---

## Phase 4: File a Provisional Application

**Timeline:** Target 4-6 weeks from project start
**Cost:** $320 (micro entity) or $640 (small entity)

### What Is a Provisional Application?

A provisional application is a simplified, less expensive way to establish your "priority date" — the date that counts as the official date of your invention. It gives you 12 months to file the full (non-provisional) application.

Think of it as planting a flag. You are saying: "As of this date, I invented this." If someone else files a patent for something similar after your priority date, your earlier date wins.

### Why File a Provisional First?

- **It is cheaper.** The filing fee is $320 (micro entity) or $640 (small entity), compared to ~$800-1,600 for a full application.
- **It is simpler.** No formal claims are required (though you should include them). The specification can be rough.
- **It buys you time.** You have 12 months to refine your application, continue development, and assess whether the patent is commercially worth pursuing.
- **It does not start the 20-year clock.** The 20-year patent term starts from the non-provisional filing date, not the provisional date.

### Entity Status: How Much You Pay

The USPTO charges different fees based on your entity size. You qualify for one of these:

| Entity Type | Who Qualifies | Fee Discount |
|---|---|---|
| **Micro entity** | Individuals with gross income below ~$228,000/year AND who have not been named on more than 4 previous US patent applications | 75% discount on most fees |
| **Small entity** | Individuals or companies with fewer than 500 employees | 50% discount on most fees |
| **Large entity** | Everyone else | Full fees |

Most independent inventors qualify as micro entity. You must certify your status when filing.

### What to Include in the Provisional Application

- [ ] **Specification** — Your full written description from Phase 3. It does not need to be perfectly polished, but the more complete it is, the stronger your priority date. If you later try to claim something that was not described in the provisional, it will not get the benefit of the early filing date.
- [ ] **Draft claims** — Not legally required for a provisional, but strongly recommended. Including them ensures continuity when you file the full application.
- [ ] **Drawings** — Informal sketches are acceptable for the provisional. Use your formal drawings if they are ready.
- [ ] **Cover sheet** — A standard form (PTO/SB/16) identifying the application as provisional, listing the inventor(s), and providing contact information.
- [ ] **Filing fee** — $320 micro / $640 small entity.
- [ ] **Micro entity certification** — Form PTO/SB/15A, if applicable.

### How to File

1. Go to [USPTO Patent Center](https://patentcenter.uspto.gov/)
2. Create an account if you do not have one
3. Select "File a new application" and choose "Provisional"
4. Upload your documents (specification, claims, drawings, cover sheet)
5. Pay the filing fee
6. You will receive a confirmation with your provisional application number and filing date

**Keep this confirmation safe.** The filing date is your priority date — the single most important date in the entire patent process.

### What Happens After Filing

Nothing, from the USPTO's perspective. Provisional applications are not examined. They sit in the system for 12 months. If you do not file a non-provisional application within those 12 months, the provisional simply expires and is as if it never existed.

---

## Phase 5: Use the 12-Month Window

**Timeline:** Months 1-12 after provisional filing
**Cost:** $0 (development and planning time)

### What You Should Do During This Period

#### Continue Building the App

- Test the app on actual hardware
- **Critically important:** Test whether the sensor fusion algorithm actually works in microgravity (or simulated microgravity). If the accelerometer-based approach fails and you need to redesign it, document the new approach. This strengthens the patent because it demonstrates the non-obvious technical challenge.
- Document any new solutions you discover during development

#### Assess Commercial Viability

- Talk to potential customers (space agencies, commercial station operators like Axiom or Starlab)
- Gauge interest in licensing the technology
- Decide whether the patent is worth the additional investment of the full filing

#### Prepare for the Full Filing

- Refine the specification based on what you learn during development
- Polish the claims based on further prior art research
- Prepare formal drawings

#### Consider Additional Filings

If you invent something significantly new during development (for example, a camera-based horizon detection system that replaces the magnetometer entirely), you have two options:
- File a new provisional application covering the new invention
- Plan to include the new material in a "Continuation-in-Part" (CIP) application

Be aware: any new material added after your original provisional filing will only get the priority date of the later filing, not the original one.

### Decision Point: Month 10

By month 10, you should decide:

- **File the full application?** If the technology is viable and commercially valuable, proceed to Phase 6.
- **Abandon?** If the technology does not work as expected or has no commercial potential, you can let the provisional expire. You will lose the $320-640 filing fee but nothing else.
- **File internationally?** See Phase 7.

---

## Phase 6: File the Full (Non-Provisional) Application

**Timeline:** Month 11-12 of the provisional period (must be filed within 12 months)
**Cost:** ~$800 (micro entity) or ~$1,600 (small entity) for filing + search + examination fees

### What Is a Non-Provisional Application?

This is the real, formal patent application that will be examined by the USPTO. Unlike the provisional, this one gets assigned to a patent examiner who will review it, search for prior art, and decide whether to grant your patent.

### How to File

You file a new application at [USPTO Patent Center](https://patentcenter.uspto.gov/) that references (claims priority to) your earlier provisional application. This way, your effective filing date is the date of the provisional, even though the full application is filed up to 12 months later.

### What to Include

- [ ] **Final specification** — Refined and polished version of what you filed with the provisional, updated with anything you learned during development
- [ ] **Formal claims** — Your ~20-claim set from Phase 2, refined
- [ ] **Formal drawings** — Must now meet the USPTO's formal requirements: black-and-white line drawings, proper margins (top 2.5 cm, left 2.5 cm, right 1.5 cm, bottom 1 cm), reference numerals, figure numbers
- [ ] **Abstract** — 150 words or fewer
- [ ] **Application Data Sheet (ADS)** — A form providing bibliographic information (inventor name, address, etc.) and the priority claim to the provisional
- [ ] **Inventor's oath or declaration** — A form (PTO/AIA/01) where you swear that you are the true inventor
- [ ] **Priority claim** — In the ADS, you reference your provisional application number and filing date
- [ ] **Information Disclosure Statement (IDS)** — See below
- [ ] **Filing fee** — ~$800 micro / ~$1,600 small entity (covers filing, search, and examination fees)

### The Information Disclosure Statement (IDS)

This is a critical and legally required document. You must list every piece of prior art you are aware of that is relevant to your invention. This includes:

- Every patent and published patent application you found in Phase 1
- The "Windows on Earth" tool (as non-patent literature)
- Any academic papers about sensor fusion in microgravity
- Any ISS tracker apps you found
- Your own TECH_SPEC if it was publicly visible online before your filing date

**Why this matters:** You have a legal "duty of candor" — an obligation to be honest with the patent office. If you know about a relevant piece of prior art and deliberately do not disclose it, and the patent office later finds out, your entire patent can be declared unenforceable. This is true even if the hidden reference would not have changed the outcome.

The rule is simple: when in doubt, disclose it. It is always safer to over-disclose than to under-disclose.

---

## Phase 7: Decide About International Protection

**Timeline:** Month 12 (same deadline as the non-provisional)
**Cost:** ~$2,000-4,000 for a PCT application

### Understanding Geographic Scope

A US patent only protects you in the United States. If a European company builds the same app and sells it only in Europe, your US patent cannot stop them.

If you want protection in other countries, you must file patent applications in those countries. You can do this in two ways:

### Option A: PCT Application (Recommended if You Want International Protection)

The **Patent Cooperation Treaty (PCT)** is an international agreement that lets you file a single application that preserves your option to seek patent protection in over 150 countries. It does not give you an international patent (there is no such thing), but it buys you time to decide which countries to file in.

Key facts about PCT:
- Must be filed within 12 months of your priority date (the provisional filing date)
- You can delay the decision of which specific countries to enter until **30 months** from the priority date
- The PCT office conducts an international search and provides a preliminary opinion on patentability — this is useful feedback before you spend money on individual countries
- Cost: approximately $2,000-4,000

### Option B: Skip International Filing

If you only care about US protection, or if the cost is not justified, you can skip this entirely. Be aware that once the 12-month deadline passes, you lose the ability to claim your early priority date in most foreign countries.

### For *What On Earth?!*

Consider PCT if:
- Commercial space station operators are based outside the US (ESA partners are European)
- You want to license the technology to international space agencies
- The commercial potential justifies the additional investment

---

## Phase 8: The Patent Office Reviews Your Application

**Timeline:** 12-30 months after filing the non-provisional
**Cost:** $0 (waiting period — no fees until you receive an office action)

### What Happens Behind the Scenes

After you file the non-provisional application:

1. **Filing receipt** — You receive a confirmation immediately.

2. **Application published** — At 18 months after your priority date (the provisional filing date), your application is published publicly. Anyone can read it. This happens automatically; you cannot prevent it.

3. **Examiner assigned** — Your application is assigned to a patent examiner who specializes in the relevant technology area (likely AR, computer graphics, or navigation).

4. **Examiner searches** — The examiner searches patent databases, academic literature, and other sources for prior art relevant to your claims.

5. **First office action** — The examiner sends you a written letter (the "office action") explaining their findings. This typically arrives **12-24 months** after filing.

### Speeding Things Up

If 12-24 months is too long to wait, you can pay for accelerated examination:

**Track One (Prioritized Examination):**
- Additional fee: ~$1,000 micro / ~$2,000 small entity
- Guarantees a first office action within 6 months
- Worth considering if you need the patent quickly (e.g., for licensing negotiations)

---

## Phase 9: Responding to Rejections

**Timeline:** 1-12 months per round (you will likely go through 1-3 rounds)
**Cost:** $0-960 per round in government fees (plus your time, or attorney fees if you hire one)

### What Is an Office Action?

An office action is a letter from the patent examiner. It explains, for each of your claims, whether the examiner thinks the claim is patentable, and if not, why not.

There are two kinds:

- **Non-final office action:** The examiner's first rejection. You have the right to respond by arguing, amending claims, or both.
- **Final office action:** If the examiner still disagrees after your response, they issue a "final" rejection. You can still respond, but your options are more limited (see below).

### What the Examiner Will Likely Say

Based on the prior art landscape for *What On Earth?!*, here is what you should expect:

#### Rejection Type 1: "Your Invention Is Obvious" (35 USC 103)

This is the most likely rejection. The examiner will find 2-3 existing references and argue:

> "Reference 1 (a ground-based AR map patent) teaches using sensor fusion to overlay augmented reality on a camera feed. Reference 2 (Windows on Earth or similar) teaches viewing Earth from orbital altitude for astronauts. It would have been obvious to one of ordinary skill in the art to combine the AR overlay of Reference 1 with the orbital context of Reference 2."

**How to respond:**

*Argument 1 — The prior art actually teaches away from this combination:*
- Ground-based AR patents rely on GPS for positioning. GPS does not work in orbit. A skilled engineer would not look to a GPS-dependent system to solve an orbital positioning problem.
- Ground-based sensor fusion relies on the accelerometer detecting gravity. In microgravity, there is no detectable gravity. The prior art teaches *toward* using gravity, which means it teaches *away from* the orbital use case. An engineer following the prior art's teachings would conclude that standard sensor fusion cannot work in orbit.

*Argument 2 — The combination produces unexpected results:*
- The specific combination of orbital position + microgravity-adapted sensor fusion + real-time 3D globe rendering produces a qualitatively different result than any existing system. No prior art system allows an orbital observer to hold up a device and instantly identify geography through a viewport.

*Argument 3 (fallback) — Narrow the claims:*
- If the broad claims are rejected, you can add limitations from your dependent claims. For example, adding "wherein the sensor fusion engine operates without a gravity-derived reference vector" narrows the claim to specifically cover the microgravity adaptation, which no prior art addresses.

#### Rejection Type 2: "Your Invention Is Just an Abstract Idea" (35 USC 101)

The examiner may argue that your claims amount to "displaying geographic information," which is an abstract idea that cannot be patented.

**How to respond:**

- The invention solves a specific technical problem (geographic identification in microgravity without GPS) with a specific technical solution (adapted sensor fusion + cascading position source + real-time compositing).
- The claims are not directed to an abstract idea but to a concrete technical system that improves the functioning of the device in a novel operating environment.
- Cite relevant court cases where similar technical inventions were found to be patent-eligible. (If working with a patent attorney, they will identify the most current and relevant cases.)

### Response Deadlines

When you receive an office action, you have **3 months** to respond. You can request extensions of up to 3 additional months (for a total of 6 months), but each extension costs money:

| Extension | Micro Entity Fee | Small Entity Fee |
|---|---|---|
| 1st month | $60 | $120 |
| 2nd month | $175 | $350 |
| 3rd month | $400 | $800 |

### What If You Get a "Final" Rejection?

A "final" office action does not mean your patent is dead. You have three main options:

**Option A: Request for Continued Examination (RCE)**

This is the most common path. You pay a fee ($480 micro / $960 small entity), and prosecution reopens as if the final rejection never happened. You get to submit new arguments and amended claims, and the examiner issues a new (non-final) office action.

Most successful patents go through 1-2 RCEs. It adds time and money but is a normal part of the process.

**Option B: Appeal to the Patent Trial and Appeal Board (PTAB)**

If you believe the examiner is wrong about the law (not just the facts), you can appeal to a panel of administrative judges within the USPTO. This is more formal: you write an appeal brief explaining your legal arguments, the examiner writes a response, and the judges decide.

- Timeline: 12-18 months for a decision
- The PTAB overturns examiners approximately 30-40% of the time for obviousness rejections
- No additional fee beyond the Notice of Appeal fee (~$200-400)

**Option C: After-Final Consideration Pilot (AFCP 2.0)**

This is a lighter option. You submit amended claims with a request for the examiner to take another look. The examiner gets extra time to search and consider. If the amendment resolves the issues, the patent can be allowed without an RCE.

- No additional government fee
- Not guaranteed to work, but worth trying before paying for an RCE

---

## Phase 10: Getting Your Patent Granted

**Timeline:** Typically 2-4 years from non-provisional filing
**Cost:** $300 (micro entity) or $600 (small entity) issue fee

### Notice of Allowance

When the examiner is satisfied that your claims are patentable, they send a **Notice of Allowance**. This is the letter that says your patent will be granted.

### Paying the Issue Fee

You must pay the issue fee within **3 months** of the Notice of Allowance:
- Micro entity: $300
- Small entity: $600

After payment, the patent is typically granted (the "patent issues") within about 4 weeks. You will receive a patent number and a grant date.

### After the Patent Is Granted

#### Maintenance Fees

A US patent lasts 20 years from the non-provisional filing date, but only if you pay maintenance fees at three intervals:

| When | Micro Entity | Small Entity | What Happens If You Miss It |
|---|---|---|---|
| 3.5 years after grant | $400 | $800 | Patent expires (can be revived within 6 months for an extra fee) |
| 7.5 years after grant | $900 | $1,800 | Patent expires |
| 11.5 years after grant | $1,850 | $3,700 | Patent expires |

**Put these dates in your calendar immediately after the patent is granted.** Missing a maintenance fee deadline is one of the most common ways patents are lost.

#### Patent Marking

Once your patent is granted, you should add the patent number to your app (for example, in the "About" or "Settings" screen). This is called "patent marking." It is not legally required, but if you ever need to enforce the patent (sue someone for infringement), marking ensures you can collect damages from the date the infringer had notice of the patent.

Example marking text:
> "Protected by U.S. Patent No. X,XXX,XXX"

#### Continuation Applications

Before or shortly after your patent is granted, you can file a **continuation application**. This is a new patent application that uses the same specification (description) as the original but with different claims. It lets you seek additional patents covering different aspects of the same invention.

For example, your first patent might cover the overall AR method, and a continuation might cover the specific sensor fusion algorithm in more detail.

---

# Part IV: Reference Material

## Budget Summary

### If You File Everything Yourself (Pro Se)

| Item | Micro Entity | Small Entity | When |
|---|---|---|---|
| Provisional filing fee | $320 | $640 | Phase 4 |
| Non-provisional filing + search + examination fees | ~$800 | ~$1,600 | Phase 6 |
| Drawings (self-prepared with free tools) | $0 | $0 | Phase 3-4 |
| 1-2 office action responses (your time only) | $0 | $0 | Phase 9 |
| 1 RCE if needed | $480 | $960 | Phase 9 |
| Issue fee | $300 | $600 | Phase 10 |
| PCT filing (optional, for international) | ~$2,000-4,000 | ~$2,000-4,000 | Phase 7 |
| **Total (US only)** | **~$1,900** | **~$3,800** | |
| **Total (US + PCT)** | **~$4,000-6,000** | **~$6,000-8,000** | |

### If You Hire a Patent Attorney

| Item | Typical Cost | When |
|---|---|---|
| Prior art search (professional) | $1,500-3,000 | Phase 1 |
| Drafting the application | $8,000-15,000 | Phase 3 |
| Filing fees (same as above) | $1,900-3,800 | Phases 4, 6 |
| Each office action response | $2,000-5,000 | Phase 9 |
| Appeal (if needed) | $5,000-10,000 | Phase 9 |
| **Total (US only, through grant)** | **$15,000-30,000+** | |

### Hybrid Approach (Recommended for Beginners)

| Item | Cost | What You Do vs. What the Attorney Does |
|---|---|---|
| Prior art search | $0 | You do it yourself (Phase 1) |
| Draft specification | $0 | You write it yourself using this guide |
| Attorney claim review | $1,000-3,000 | Attorney reviews and refines your claims before filing |
| Filing fees | $1,900-3,800 | You file yourself |
| Attorney office action help | $2,000-5,000 per response | Consider hiring for complex rejections |
| **Total (US only)** | **$5,000-12,000** | |

---

## Complete Timeline

| Phase | Activity | When | Duration |
|---|---|---|---|
| 1 | Research prior art | Weeks 1-2 | 1-2 weeks |
| 2 | Decide what to protect (claim strategy) | Week 2-3 | 1 week |
| 3 | Write the patent application | Weeks 3-6 | 2-4 weeks |
| 4 | File provisional application | Week 5-7 | 1 day |
| 5 | Use the 12-month window (develop, refine, assess) | Months 2-12 | 10 months |
| 6 | File non-provisional application | Month 11-12 | 1 day |
| 7 | Decide on international filing (PCT) | Month 12 | 1 day |
| 8 | Wait for USPTO examination | Months 12-36 | 12-24 months |
| 9 | Respond to office actions (1-3 rounds) | Months 24-48 | 3-12 months per round |
| 10 | Patent granted | Month 30-60 | — |
| — | **Total: priority date to grant** | — | **~2.5-5 years** |

---

## Glossary

| Term | Definition |
|---|---|
| **35 USC** | Title 35 of the United States Code. The federal law governing patents. |
| **Abstract** | A 150-word summary of the invention, published with the patent. |
| **ADS (Application Data Sheet)** | A form providing bibliographic data (inventor, title, priority claims). |
| **AFCP 2.0** | After-Final Consideration Pilot. A program that gives the examiner extra time to consider amendments after a final rejection. |
| **Alice (Alice Corp. v. CLS Bank)** | A 2014 Supreme Court case that made it harder to patent abstract ideas implemented on computers. |
| **Claims** | The numbered sentences at the end of a patent that legally define what is protected. |
| **Complementary filter** | A sensor fusion algorithm that combines fast, noisy data (gyroscope) with slow, stable data (magnetometer/accelerometer). |
| **Continuation** | A new patent application based on the same specification as a parent application, but with different claims. |
| **CIP (Continuation-in-Part)** | A new patent application that adds new material to a parent application's specification. |
| **CPC (Cooperative Patent Classification)** | An international system for categorizing patents by technology area. |
| **CRM (Computer-Readable Medium)** | A type of patent claim that covers software stored on a device. |
| **Dependent claim** | A claim that references and narrows an independent claim. |
| **Duty of candor** | Your legal obligation to disclose all known relevant prior art to the patent office. |
| **Enablement** | The requirement that the patent specification describes the invention well enough for someone to build it. |
| **Entity status** | Your classification for fee purposes: micro, small, or large entity. |
| **Examiner** | The USPTO employee who reviews your application. |
| **IDS (Information Disclosure Statement)** | A form listing all prior art you know about, filed with your application. |
| **IMU (Inertial Measurement Unit)** | A sensor combining accelerometer and gyroscope to measure motion and orientation. |
| **Independent claim** | A claim that stands on its own and does not reference another claim. |
| **Means-plus-function** | A claim drafting style ("means for doing X") that the patent office interprets narrowly. Generally avoided. |
| **Micro entity** | An individual with low income and few prior patents, who qualifies for 75% fee discounts. |
| **Non-final office action** | The examiner's initial rejection or allowance of your claims. |
| **Non-obvious** | The requirement that the invention is not a straightforward combination of existing technology. |
| **Non-provisional application** | The full, formal patent application that gets examined. |
| **Notice of Allowance** | The letter from the USPTO saying your patent will be granted. |
| **Novelty** | The requirement that the invention is new — not previously disclosed anywhere. |
| **NPL (Non-Patent Literature)** | Prior art that is not a patent (papers, products, websites, etc.). |
| **Office action** | A letter from the examiner explaining their findings about your claims. |
| **PCT (Patent Cooperation Treaty)** | An international agreement for filing patent applications in multiple countries. |
| **PHOSITA** | Person Having Ordinary Skill In The Art. A hypothetical average engineer in the field. |
| **PPH (Patent Prosecution Highway)** | A program that speeds up examination based on favorable international search results. |
| **Prior art** | Everything publicly known before your invention. |
| **Priority date** | The effective filing date of your invention. Earlier is better. |
| **Pro se** | Filing without an attorney. |
| **Prosecution** | The back-and-forth between you and the examiner. Not criminal prosecution. |
| **Provisional application** | A simplified filing that establishes your priority date and gives you 12 months. |
| **PTAB (Patent Trial and Appeal Board)** | The body within the USPTO that hears appeals of examiner decisions. |
| **RCE (Request for Continued Examination)** | A fee-based request to reopen prosecution after a final rejection. |
| **SGP4** | Simplified General Perturbations 4. An algorithm for predicting satellite orbits from TLE data. |
| **Small entity** | A company with fewer than 500 employees, qualifying for 50% fee discounts. |
| **Specification** | The written description of the invention in the patent application. |
| **TLE (Two-Line Element set)** | A standardized format describing a satellite's orbit, used for position prediction. |
| **Track One** | A paid program for faster USPTO examination (first action within 6 months). |
| **USPTO** | United States Patent and Trademark Office. The agency that grants patents. |
| **Utility patent** | A patent protecting how something works. Lasts 20 years. |

---

## Prior Art Reference Table

### Directly Relevant References

| Reference | What It Is | What It Teaches | How It Differs from *What On Earth?!* |
|---|---|---|---|
| **Windows on Earth** (NASA/TERC, 2012) | Desktop software simulating the view of Earth from the ISS. Selected by NASA to help astronauts identify photography targets. | Viewing Earth from orbital altitude. Terrain, imagery, clouds, day/night. | Not augmented reality. Not real-time sensor-fused. Not overlaid on a camera feed. Not a mobile app. A pre-rendered desktop simulation. |
| **US10565798B2** (Mobilizar Technologies, 2018) | Patent for AR interactions with a physical globe. Camera recognizes geography on a globe's surface and overlays AR content. | AR + globe + geographic identification | Interacts with a physical desk globe, not a virtual 3D globe. Uses image recognition, not orbital position data or device sensor fusion. Educational context, not orbital. |
| **ISS Real-Time Tracker 3D** (app) | Ground-based app showing ISS position on a 3D globe with planned AR sky-viewing feature. | 3D globe + ISS position tracking | Designed for ground observers looking UP at ISS, not astronauts looking DOWN at Earth. Uses user's GPS, not orbital position for the observer. |
| **Spot the Station** (NASA app) | Ground-based ISS spotting app with AR trajectory overlay in the sky. | AR + ISS tracking | For ground users. No 3D globe overlay. No orbital observer perspective. No sensor fusion for orbital orientation. |
| **ESA AR for Astronauts** | HoloLens-based AR for equipment maintenance aboard ISS (step-by-step repair instructions). | AR used in space environment | Completely different purpose (equipment repair, not Earth observation). Different hardware (HoloLens headset, not smartphone). |

### Partially Relevant References

| Reference | What It Teaches | How It Differs |
|---|---|---|
| **US9488488B2** (Google — AR Maps) | Using GPS, compass, and accelerometer for AR map overlay on camera | Ground-based, requires GPS, assumes 1G gravity environment |
| **US20200126265A1** (AR System) | General method for AR overlay using position and orientation data | Generic AR framework with no orbital, globe, or spacecraft context |
| **US20110141254A1** (Mobile AR) | Using 3D orientation data for AR display on mobile device | General mobile AR for ground use |
| **US7315259B2** (Google — Tile Caching) | Pre-computed map tile caching and serving on mobile devices | Well-established technique from 2007; the tile caching in *What On Earth?!* is not novel |
| **US7693702B1** (Space Systems AR) | AR visualization of satellite system data for military situational awareness | Visualizes satellite systems and status, not Earth geography from the perspective of an orbital observer |
| **US9824495B2** (AR Scene Compositing) | Methods for compositing semi-transparent AR overlays | General compositing technique applicable to any AR system |
