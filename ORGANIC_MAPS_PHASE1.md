# Ranger GX — Organic Maps Phase 1

This batch adds a real Android bridge to the official Organic Maps `om://` API while preserving the current in-app South Africa offline map as a fallback.

## What works now
- Ranger GX detects installed Organic Maps release/beta/debug/web variants.
- The map screen can send the current Ranger position or selected destination to Organic Maps.
- No Google Maps dependency.
- Existing Ranger GX GPS, MBTiles map, search, routing and OBD code remains intact.
- `tools/setup_organic_maps_source.sh` prepares a shallow Organic Maps source checkout for the embedded phase.

## Why this is Phase 1
Organic Maps does not currently ship a drop-in Android map SDK. Its official Android API is a deep-link/Activity API. The full map renderer/search/routing stack lives in a large C++/JNI Android source tree. Embedding that engine means maintaining an Organic Maps fork/SDK module, not adding a normal Flutter package.

## Phase 2
- Build the Organic Maps F-Droid/debug Android core from source.
- Extract/maintain the required SDK/JNI modules.
- Add a native Android map host view/activity for Ranger GX.
- Bridge destination, GPS, routing state and POI/search results back to Flutter.
- Keep Ranger GX's current map as a fallback until the embedded engine is field-tested.

## Attribution
If Organic Maps source/UI/binary map data is used in a derivative product, keep the required visible Organic Maps Project attribution and link in the app.
