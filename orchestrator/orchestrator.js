import "dotenv/config"; // loads .env before any other module uses process.env

/**
 * What-On-Earth Orchestrator
 *
 * Pipeline:
 *   [1] PLAN      — Derives MVP product spec from PRFAQ
 *   [2] ARCHITECT — Designs architecture + API contract (two files)
 *   [3] BACKEND   — Implements the API (runs in parallel with FRONTEND)
 *       FRONTEND  — Implements the React UI (runs in parallel with BACKEND)
 *   [4] REVIEW    — Reviews all artifacts for defects
 *   [5] GENERATE  — Copies workspace artifacts to ./generated_app/
 *
 * Human-intervention checkpoints appear between every stage. You can:
 *   - Press Enter to continue
 *   - Type "n" to abort (workspace files are preserved)
 *   - Type free-text feedback that will be appended to the next agent's prompt
 *
 * Prerequisites:
 *   Copy .env.example to .env and fill in OPENAI_API_KEY.
 *
 * Usage:
 *   npm start
 */

import readline from "readline";
import { dirname, join } from "path";
import { fileURLToPath } from "url";
import fs from "fs-extra";

import { planner } from "./agents/planner.js";
import { architect } from "./agents/architect.js";
import { backend } from "./agents/backend.js";
import { frontend } from "./agents/frontend.js";
import { reviewer } from "./agents/reviewer.js";
import { readFile } from "./core/fileStore.js";

const __dirname = dirname(fileURLToPath(import.meta.url));
const WORKSPACE = join(__dirname, "workspace");
const GENERATED_APP = join(__dirname, "../generated_app");

const PREVIEW_CHARS = 900;

// ── Helpers ──────────────────────────────────────────────────────────────────

function banner(title) {
  const line = "═".repeat(64);
  console.log(`\n${line}`);
  console.log(`  ${title}`);
  console.log(line);
}

async function previewFile(name) {
  try {
    const content = await readFile(name);
    const preview =
      content.length > PREVIEW_CHARS
        ? content.slice(0, PREVIEW_CHARS) + "\n  ... [truncated — see workspace/" + name + "]"
        : content;
    console.log(`\n  ┌── ${name} (${content.length} chars) ──`);
    preview.split("\n").forEach((line) => console.log(`  │ ${line}`));
    console.log(`  └${"─".repeat(40)}`);
  } catch {
    console.log(`  [${name}: file not found]`);
  }
}

/**
 * Pause the pipeline and let the human review output.
 * Returns feedback string (may be null if user just pressed Enter).
 */
async function checkpoint(stage, outputFiles) {
  banner(`✅  STAGE COMPLETE: ${stage}`);

  for (const f of outputFiles) {
    await previewFile(f);
  }

  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
    terminal: true,
  });

  return new Promise((resolve) => {
    rl.question(
      "\n  ▶ [Enter] continue  [n] abort  [text] feedback for next agent: ",
      (answer) => {
        rl.close();
        const trimmed = answer.trim();
        if (trimmed.toLowerCase() === "n") {
          console.log("\n  Aborted. Workspace files are preserved in orchestrator/workspace/");
          process.exit(0);
        }
        const feedback = trimmed || null;
        if (feedback) {
          console.log(`  Feedback recorded: "${feedback}"`);
        }
        resolve(feedback);
      }
    );
  });
}

async function copyToGeneratedApp() {
  await fs.ensureDir(GENERATED_APP);
  await fs.emptyDir(GENERATED_APP);
  await fs.copy(WORKSPACE, GENERATED_APP);
  const files = await fs.readdir(GENERATED_APP);
  console.log(`\n  Artifacts written to ./generated_app/:`);
  files.forEach((f) => console.log(`    ✓ ${f}`));
}

// ── Main Pipeline ─────────────────────────────────────────────────────────────

async function run() {
  if (!process.env.OPENAI_API_KEY) {
    console.error("❌  OPENAI_API_KEY is not set. Export it before running.");
    process.exit(1);
  }

  banner("🌍  What-On-Earth Orchestrator");
  console.log("  Pipeline: PLAN → ARCHITECT → BACKEND + FRONTEND → REVIEW → GENERATE");
  console.log('  Project:  "What On Earth?!" — AR Earth-viewer for astronauts');

  // ── Stage 1: PLAN ──────────────────────────────────────────────────────────
  console.log("\n🔄  [1/5] PLANNER running…");
  await planner({
    description:
      '"What On Earth?!" — an offline-first AR Earth-viewing app for astronauts in Low Earth Orbit. ' +
      "Sensor-fused camera overlay using GPS, magnetometer, IMU. " +
      "Pre-downloaded map tiles (2–4 GB). Real-time ISS telemetry with TLE fallback. " +
      "Personal pins with pass-overhead countdowns. Cross-platform iOS/Android.",
  });
  const planFeedback = await checkpoint("PLAN", ["product_spec.md"]);

  // ── Stage 2: ARCHITECT ─────────────────────────────────────────────────────
  console.log("\n🔄  [2/5] ARCHITECT running…");
  await architect({ feedback: planFeedback });
  const archFeedback = await checkpoint("ARCHITECT", ["architecture.md", "api_spec.json"]);

  // ── Stage 3: BACKEND + FRONTEND (parallel) ─────────────────────────────────
  console.log("\n🔄  [3/5] BACKEND + FRONTEND running in parallel…");
  await Promise.all([
    backend({ feedback: archFeedback }),
    frontend({ feedback: archFeedback }),
  ]);
  const implFeedback = await checkpoint("BACKEND + FRONTEND", ["backend.js", "frontend.jsx"]);

  // ── Stage 4: REVIEW ────────────────────────────────────────────────────────
  console.log("\n🔄  [4/5] REVIEWER running…");
  await reviewer({ feedback: implFeedback });
  await checkpoint("REVIEW", ["review.md"]);

  // ── Stage 5: GENERATE ──────────────────────────────────────────────────────
  console.log("\n🔄  [5/5] Copying artifacts to generated_app/…");
  await copyToGeneratedApp();

  banner("🎉  COMPLETE");
  console.log("  All artifacts are in ./generated_app/");
  console.log("  Intermediate files are preserved in orchestrator/workspace/\n");
}

run().catch((err) => {
  console.error("\n❌  Orchestrator error:", err.message);
  if (err.stack) console.error(err.stack);
  process.exit(1);
});
