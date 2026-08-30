#!/usr/bin/env bash

set -e

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

BUILD_DIR="$ROOT_DIR/map_build"
OUTPUT_DIR="$ROOT_DIR/map_output"

PBF_FILE="$BUILD_DIR/south-africa-latest.osm.pbf"

PBF_URL="https://download.geofabrik.de/africa/south-africa-latest.osm.pbf"

PYTHON_ENV="$ROOT_DIR/tools/osm_env"

echo
echo "=============================================="
echo " RUSTLER GX - SOUTH AFRICA NAVIGATION BUILDER"
echo "=============================================="
echo

mkdir -p "$BUILD_DIR"
mkdir -p "$OUTPUT_DIR"

if [ ! -d "$PYTHON_ENV" ]; then

    echo "[SETUP] Creating Python environment..."

    python3 -m venv "$PYTHON_ENV"

fi

source "$PYTHON_ENV/bin/activate"

echo "[SETUP] Installing/updating osmium..."

python -m pip install \
    --upgrade \
    pip

python -m pip install \
    --upgrade \
    osmium

echo

if [ ! -f "$PBF_FILE" ]; then

    echo "[DOWNLOAD] Downloading South Africa OSM..."

    wget \
        --continue \
        "$PBF_URL" \
        -O "$PBF_FILE"

else

    echo "[DOWNLOAD] Existing PBF found."
    echo "$PBF_FILE"

fi

echo
echo "[BUILD] Building Rustler GX navigation databases..."
echo

python \
    "$ROOT_DIR/tools/build_sa_navigation.py" \
    "$PBF_FILE" \
    --output "$OUTPUT_DIR"

echo
echo "=============================================="
echo " DONE"
echo "=============================================="
echo

ls -lh \
    "$OUTPUT_DIR/rustler_roads.db" \
    "$OUTPUT_DIR/rustler_navigation.db"

echo