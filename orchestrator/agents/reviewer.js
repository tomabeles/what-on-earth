import { readFile as readFsFile } from "fs/promises";
import { fileURLToPath } from "url";
import { dirname, join } from "path";
import { readFile, writeFile } from "../core/fileStore.js";
import { runAgent } from "../core/agentRunner.js";

const __dirname = dirname(fileURLToPath(import.meta.url));

export async function reviewer({ feedback } = {}) {
  const [promptTemplate, apiSpec, backendCode, frontendCode, architecture] =
    await Promise.all([
      readFsFile(join(__dirname, "prompts/REVIEWER.txt"), "utf-8"),
      readFile("api_spec.json").catch(() => "Not provided"),
      readFile("backend.js"),
      readFile("frontend.jsx").catch(() => "Not provided"),
      readFile("architecture.md").catch(() => "Not provided"),
    ]);

  let prompt = promptTemplate
    .replace("{api_spec.json}", apiSpec)
    .replace("{backend.js}", backendCode)
    .replace("{frontend.jsx}", frontendCode)
    .replace("{architecture.md}", architecture);

  if (feedback) {
    prompt += `\n\nHUMAN REVIEWER FEEDBACK (focus your review on these concerns):\n${feedback}`;
  }

  const output = await runAgent(prompt);
  await writeFile("review.md", output);
}
