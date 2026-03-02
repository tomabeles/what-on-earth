import { readFile as readFsFile } from "fs/promises";
import { fileURLToPath } from "url";
import { dirname, join } from "path";
import { readFile, writeFile } from "../core/fileStore.js";
import { runAgent } from "../core/agentRunner.js";

const __dirname = dirname(fileURLToPath(import.meta.url));

// Parse the LLM output into two separate files.
// The architect prompt instructs the model to delimit output with:
//   ---architecture.md---   and   ---api_spec.json---
// Falls back to splitting on a bare --- separator.
function parseOutput(output) {
  const archMarker = "---architecture.md---";
  const apiMarker = "---api_spec.json---";
  const archIdx = output.indexOf(archMarker);
  const apiIdx = output.indexOf(apiMarker);

  if (archIdx !== -1 && apiIdx !== -1) {
    const architecture = output.slice(archIdx + archMarker.length, apiIdx).trim();
    const apiRaw = output.slice(apiIdx + apiMarker.length).trim();
    // Strip ```json fences if the model wrapped the JSON
    const apiSpec = apiRaw.replace(/^```json\s*/i, "").replace(/\s*```$/, "").trim();
    return { architecture, apiSpec };
  }

  // Fallback: split on first bare --- separator
  const parts = output.split(/\n---\n/);
  const architecture = parts[0].trim();
  const apiRaw = (parts[1] ?? "{}").trim();
  const apiSpec = apiRaw.replace(/^```json\s*/i, "").replace(/\s*```$/, "").trim();
  return { architecture, apiSpec };
}

export async function architect({ feedback } = {}) {
  const [promptTemplate, spec, constraints] = await Promise.all([
    readFsFile(join(__dirname, "prompts/ARCHITECT.txt"), "utf-8"),
    readFile("product_spec.md"),
    readFile("constraints.json").catch(() => "Not provided"),
  ]);

  let prompt = promptTemplate
    .replace("{product_spec.md}", spec)
    .replace("{constraints.json}", constraints);

  if (feedback) {
    prompt += `\n\nHUMAN REVIEWER FEEDBACK (incorporate into your output):\n${feedback}`;
  }

  const output = await runAgent(prompt);
  const { architecture, apiSpec } = parseOutput(output);

  await Promise.all([
    writeFile("architecture.md", architecture),
    writeFile("api_spec.json", apiSpec),
  ]);
}
