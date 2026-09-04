#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PBF="${1:-$ROOT/map_build/south-africa-latest.osm.pbf}"
OUT="${2:-$ROOT/map_output/south_africa_search.sqlite}"
VENV="$ROOT/tools/osm_env"
[[ -f "$PBF" ]] || { echo "PBF not found: $PBF"; exit 1; }
mkdir -p "$(dirname "$OUT")"
[[ -d "$VENV" ]] || python3 -m venv "$VENV"
source "$VENV/bin/activate"
python -m pip install --upgrade pip osmium
python "$ROOT/tools/build_sa_search.py" "$PBF" --output "$OUT"
echo "Copy this to radio: $OUT"
echo "Then MAP -> Search -> database icon -> import once."
