import crypto from "crypto";
import fs from "fs";

export function hashFile(path) {
  if (!fs.existsSync(path)) return null;
  const content = fs.readFileSync(path);
  return crypto.createHash("sha256").update(content).digest("hex");
}
