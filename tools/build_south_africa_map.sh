#!/usr/bin/env bash

set -e

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

BUILD_DIR="$ROOT_DIR/map_build"
OUTPUT_DIR="$ROOT_DIR/map_output"

PBF_FILE="$BUILD_DIR/south-africa-latest.osm.pbf"
MBTILES_FILE="$OUTPUT_DIR/south_africa.mbtiles"

PBF_URL="https://download.geofabrik.de/africa/south-africa-latest.osm.pbf"

echo
echo "========================================="
echo " Rustler GX - South Africa Map Builder"
echo "========================================="
echo

mkdir -p "$BUILD_DIR"
mkdir -p "$OUTPUT_DIR"

echo "[1/4] Installing required packages..."

sudo apt update

sudo apt install -y \
    wget \
    git \
    build-essential \
    cmake \
    libboost-program-options-dev \
    libboost-filesystem-dev \
    libboost-system-dev \
    libboost-iostreams-dev \
    libshp-dev \
    liblua5.4-dev \
    rapidjson-dev \
    libsqlite3-dev \
    zlib1g-dev

echo
echo "[2/4] Downloading South Africa OSM data..."

if [ ! -f "$PBF_FILE" ]; then
    wget \
        --continue \
        "$PBF_URL" \
        -O "$PBF_FILE"
else
    echo "PBF already exists:"
    echo "$PBF_FILE"
fi

echo
echo "[3/4] Preparing tilemaker..."

TILEMAKER_DIR="$BUILD_DIR/tilemaker"

if [ ! -d "$TILEMAKER_DIR" ]; then
    git clone \
        https://github.com/systemed/tilemaker.git \
        "$TILEMAKER_DIR"
fi

cd "$TILEMAKER_DIR"

git pull

mkdir -p build

cd build

cmake ..

make -j"$(nproc)"

echo
echo "[4/4] Building South Africa vector MBTiles..."
echo
echo "THIS CAN TAKE A LONG TIME."
echo

"$TILEMAKER_DIR/build/tilemaker" \
    --input "$PBF_FILE" \
    --output "$MBTILES_FILE" \
    --config "$TILEMAKER_DIR/resources/config-openmaptiles.json" \
    --process "$TILEMAKER_DIR/resources/process-openmaptiles.lua" \
    --store "$BUILD_DIR/tilemaker_store" \
    --threads 0 \
    --verbose

echo
echo "========================================="
echo " DONE"
echo "========================================="
echo
echo "Map:"
echo "$MBTILES_FILE"
echo
du -h "$MBTILES_FILE"
echo