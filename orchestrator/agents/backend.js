import { readFile as readFsFile } from "fs/promises";
import { fileURLToPath } from "url";
import { dirname, join } from "path";
import { readFile, writeFile } from "../core/fileStore.js";
import { runAgent } from "../core/agentRunner.js";

const __dirname = dirname(fileURLToPath(import.meta.url));

export async function backend({ feedback } = {}) {
  const [promptTemplate, apiSpec, architecture, schema, constraints] =
    await Promise.all([
      readFsFile(join(__dirname, "prompts/BACKEND.txt"), "utf-8"),
      readFile("api_spec.json"),
      readFile("architecture.md"),
      readFile("schema.sql").catch(() => "Not provided"),
      readFile("constraints.json").catch(() => "Not provided"),
    ]);

  let prompt = promptTemplate
    .replace("{api_spec.json}", apiSpec)
    .replace("{architecture.md}", architecture)
    .replace("{schema.sql}", schema)
    .replace("{constraints.json}", constraints);

  if (feedback) {
    prompt += `\n\nHUMAN REVIEWER FEEDBACK (incorporate into your output):\n${feedback}`;
  }

  const output = await runAgent(prompt);
  await writeFile("backend.js", output);
}
