import { readFile as readFsFile } from "fs/promises";
import { fileURLToPath } from "url";
import { dirname, join } from "path";
import { writeFile } from "../core/fileStore.js";
import { runAgent } from "../core/agentRunner.js";

const __dirname = dirname(fileURLToPath(import.meta.url));

export async function planner({ description, feedback } = {}) {
  const [promptTemplate, prfaq] = await Promise.all([
    readFsFile(join(__dirname, "prompts/PLANNER.txt"), "utf-8"),
    readFsFile(join(__dirname, "../workspace/PRFAQ.md"), "utf-8"),
  ]);

  let prompt = `${promptTemplate}\n\nPRFAQ (SOURCE OF TRUTH — READ ONLY):\n${prfaq}\n\nUSER INPUT:\n${description}`;

  if (feedback) {
    prompt += `\n\nHUMAN REVIEWER FEEDBACK (incorporate into your output):\n${feedback}`;
  }

  const output = await runAgent(prompt);
  await writeFile("product_spec.md", output);
}
