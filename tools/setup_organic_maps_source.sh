#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="${1:-$ROOT_DIR/external/organicmaps}"
mkdir -p "$(dirname "$TARGET")"
if [ -d "$TARGET/.git" ]; then
  echo "[UPDATE] Organic Maps source already exists: $TARGET"
  git -C "$TARGET" pull --ff-only
  git -C "$TARGET" submodule update --init --recursive --depth=1
else
  echo "[CLONE] Organic Maps shallow source checkout"
  git clone --depth=1 --filter=blob:limit=128k --recurse-submodules --shallow-submodules \
    https://github.com/organicmaps/organicmaps.git "$TARGET"
fi
echo
echo "Organic Maps source ready at: $TARGET"
echo "Expect the full Android build toolchain to need tens of GB of free disk."
