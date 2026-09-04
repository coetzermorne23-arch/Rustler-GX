#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OM_ROOT="${OM_ROOT:-$ROOT_DIR/external/organicmaps}"
OM_ANDROID="$OM_ROOT/android"
DEST="$ROOT_DIR/android/app/libs"

if [[ ! -d "$OM_ANDROID/sdk" ]]; then
  echo "Organic Maps checkout not found at:"
  echo "  $OM_ROOT"
  exit 1
fi

mkdir -p "$DEST"

SDK_DIR="${ANDROID_HOME:-$HOME/Android/Sdk}"
if [[ -x "$OM_ROOT/tools/android/set_up_android.py" ]]; then
  python3 "$OM_ROOT/tools/android/set_up_android.py" --sdk "$SDK_DIR"
fi

if [[ -d "$SDK_DIR/cmake" ]]; then
  CMAKE_BIN="$(
    find "$SDK_DIR/cmake" -mindepth 2 -maxdepth 2 -type f -name cmake \
      -path '*/bin/cmake' \
      | sort -V \
      | tail -1
  )"
  if [[ -n "${CMAKE_BIN:-}" ]]; then
    export PATH="$(dirname "$CMAKE_BIN"):$PATH"
  fi
fi

echo "Building Organic Maps SDK from:"
echo "  $(cd "$OM_ROOT" && git rev-parse HEAD)"
echo

cd "$OM_ANDROID"

./gradlew \
  :sdk:assembleDebug \
  :sdk:location:core:assembleDebug \
  -Parm64

SDK_AAR="$OM_ANDROID/sdk/build/outputs/aar/sdk-debug.aar"
CORE_AAR="$OM_ANDROID/sdk/location/core/build/outputs/aar/core-debug.aar"

if [[ ! -f "$SDK_AAR" ]]; then
  SDK_AAR="$(find "$OM_ANDROID/sdk/build/outputs/aar" -type f -name '*.aar' | head -1)"
fi

if [[ ! -f "$CORE_AAR" ]]; then
  CORE_AAR="$(find "$OM_ANDROID/sdk/location/core/build/outputs/aar" -type f -name '*.aar' | head -1)"
fi

if [[ -z "${SDK_AAR:-}" || ! -f "$SDK_AAR" ]]; then
  echo "Organic Maps SDK AAR was not produced."
  exit 2
fi

rm -f "$DEST/organicmaps-"*.aar

cp "$SDK_AAR" "$DEST/organicmaps-sdk-debug.aar"

if [[ -n "${CORE_AAR:-}" && -f "$CORE_AAR" ]]; then
  cp "$CORE_AAR" "$DEST/organicmaps-location-core-debug.aar"
fi

echo
echo "Installed:"
ls -lh "$DEST"/organicmaps-*.aar

echo
echo "Now build Ranger GX:"
echo "  cd $ROOT_DIR"
echo "  flutter clean"
echo "  flutter pub get"
echo "  flutter build apk --debug"
