import { loadState, saveState } from "./buildState.js";
import { graph } from "./dag.js";
import { hashFile } from "./hash.js";

export async function runDAG(executors) {
  const oldState = loadState();
  const newState = {};

  for (const node of Object.keys(graph)) {
    let dirty = false;

    if (!oldState[node]) dirty = true;

    for (const output of graph[node].outputs) {
      const currentHash = hashFile(`./workspace/${output}`);
      if (!oldState[node] || oldState[node]?.[output] !== currentHash) {
        dirty = true;
      }
    }

    if (dirty) {
      console.log(`Rebuilding ${node}`);
      await executors[node]();
    } else {
      console.log(`Skipping ${node}`);
    }

    newState[node] = {};
    for (const output of graph[node].outputs) {
      newState[node][output] = hashFile(`./workspace/${output}`);
    }
  }

  saveState(newState);
}
