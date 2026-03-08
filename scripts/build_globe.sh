#!/usr/bin/env bash
set -euo pipefail

# Build the CesiumJS Vite bundle and output it to assets/globe/.
# Run this from the repo root before `flutter run` or `flutter build`.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT/web_globe"
npm ci
npx vite build --outDir ../assets/globe

# vite-plugin-cesium copies CesiumJS's static "Assets/" directory with an
# uppercase A.  Our pubspec.yaml and shelf handler expect lowercase "assets/".
# Two-step rename handles both case-sensitive (Linux CI) and case-insensitive
# (macOS) filesystems.
if [ -d "$REPO_ROOT/assets/globe/Assets" ]; then
  mv "$REPO_ROOT/assets/globe/Assets" "$REPO_ROOT/assets/globe/_assets_tmp"
  mv "$REPO_ROOT/assets/globe/_assets_tmp" "$REPO_ROOT/assets/globe/assets"
fi

echo "Globe bundle written to assets/globe/"
