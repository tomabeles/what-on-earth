import fs from "fs-extra";
import path from "path";
import { fileURLToPath } from "url";
import { dirname } from "path";

const __dirname = dirname(fileURLToPath(import.meta.url));
const WORKSPACE = path.resolve(__dirname, "../workspace");

export async function readFile(name) {
  return fs.readFile(path.join(WORKSPACE, name), "utf8");
}

export async function writeFile(name, content) {
  await fs.ensureDir(WORKSPACE);
  return fs.writeFile(path.join(WORKSPACE, name), content);
}

export async function listFiles() {
  return fs.readdir(WORKSPACE);
}
