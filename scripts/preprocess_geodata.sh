#!/usr/bin/env bash
# preprocess_geodata.sh — Download Natural Earth 10m GeoJSON files and simplify
# them for orbital-altitude viewing. Output goes to assets/geodata/.
#
# Requirements: mapshaper (npm install -g mapshaper), curl
#
# Usage: ./scripts/preprocess_geodata.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="$PROJECT_ROOT/assets/geodata"
TEMP_DIR="$(mktemp -d)"

trap 'rm -rf "$TEMP_DIR"' EXIT

mkdir -p "$OUTPUT_DIR"

BASE_URL="https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson"

echo "==> Downloading Natural Earth 10m GeoJSON files..."

curl -fSL "$BASE_URL/ne_10m_admin_0_countries.geojson" -o "$TEMP_DIR/countries.geojson"
curl -fSL "$BASE_URL/ne_10m_coastline.geojson" -o "$TEMP_DIR/coastline.geojson"
curl -fSL "$BASE_URL/ne_10m_lakes.geojson" -o "$TEMP_DIR/lakes.geojson"
curl -fSL "$BASE_URL/ne_10m_populated_places.geojson" -o "$TEMP_DIR/places.geojson"
curl -fSL "$BASE_URL/ne_10m_geography_marine_polys.geojson" -o "$TEMP_DIR/marine.geojson"
curl -fSL "$BASE_URL/ne_10m_rivers_lake_centerlines.geojson" -o "$TEMP_DIR/rivers.geojson"

echo "==> Simplifying and reducing precision..."

# Countries: simplify to 10%, keep only NAME and SOV_A3 properties, 2 decimal places
mapshaper "$TEMP_DIR/countries.geojson" \
  -simplify 10% \
  -filter-fields NAME,SOV_A3 \
  -o "$OUTPUT_DIR/ne_10m_admin_0_countries.geojson" precision=0.01 format=geojson

# Coastlines: simplify to 15%, no extra properties needed
mapshaper "$TEMP_DIR/coastline.geojson" \
  -simplify 15% \
  -o "$OUTPUT_DIR/ne_10m_coastline.geojson" precision=0.01 format=geojson

# Lakes: simplify to 10%, keep name
mapshaper "$TEMP_DIR/lakes.geojson" \
  -simplify 10% \
  -filter-fields name \
  -rename-fields NAME=name \
  -o "$OUTPUT_DIR/ne_10m_lakes.geojson" precision=0.01 format=geojson

# Populated places: filter to POP_MAX > 100000, keep NAME and POP_MAX
mapshaper "$TEMP_DIR/places.geojson" \
  -filter 'POP_MAX > 100000' \
  -filter-fields NAME,POP_MAX \
  -o "$OUTPUT_DIR/ne_10m_populated_places.geojson" precision=0.01 format=geojson

# Marine polys (oceans, seas): simplify to 10%, keep name and scalerank
mapshaper "$TEMP_DIR/marine.geojson" \
  -simplify 10% \
  -filter-fields name,scalerank \
  -rename-fields NAME=name \
  -o "$OUTPUT_DIR/ne_10m_geography_marine_polys.geojson" precision=0.01 format=geojson

# Rivers: simplify to 10%, keep name and scalerank, filter to major rivers (scalerank <= 4)
mapshaper "$TEMP_DIR/rivers.geojson" \
  -simplify 10% \
  -filter 'scalerank <= 4' \
  -filter-fields name,scalerank \
  -rename-fields NAME=name \
  -o "$OUTPUT_DIR/ne_10m_rivers.geojson" precision=0.01 format=geojson

echo "==> Output files:"
ls -lh "$OUTPUT_DIR"/*.geojson

TOTAL=$(du -sh "$OUTPUT_DIR" | awk '{print $1}')
echo "==> Total size: $TOTAL"
echo "==> Done."
