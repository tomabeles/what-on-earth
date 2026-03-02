#!/usr/bin/env bash
set -euo pipefail

# Build the CesiumJS Vite bundle and output it to assets/globe/.
# Run this from the repo root before `flutter run` or `flutter build`.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT/web_globe"
npm ci
npx vite build --outDir ../assets/globe

echo "Globe bundle written to assets/globe/"
