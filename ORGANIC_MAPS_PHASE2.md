RANGER GX — ORGANIC MAPS PHASE 2

This patch creates the first in-process Organic Maps host for Ranger GX.

What changes:
- Android PlatformView host: rustler_gx/organic_maps_view
- Flutter embedded Organic Maps screen
- Current Ranger MBTiles map remains the fallback
- Phase 1 external Organic Maps bridge remains as fallback
- Organic Maps SDK is linked from locally-built AARs
- No compile-time Kotlin dependency on Organic Maps classes; reflection keeps
  the normal Ranger build usable before the AAR build is installed
- Visible Organic Maps / OpenStreetMap attribution is shown on the embedded view

INSTALL PATCH
  cd ~/rustler_gx
  unzip -o ~/Downloads/Rustler_GX_OrganicMaps_Phase2_PATCH.zip -d .

FIRST COMPILE CHECK (works even before OM AARs)
  dart format lib
  flutter analyze
  flutter build apk --debug

BUILD THE LOCAL ORGANIC MAPS SDK
  chmod +x tools/build_and_install_organic_maps_sdk.sh
  ./tools/build_and_install_organic_maps_sdk.sh

THEN REBUILD
  flutter clean
  flutter pub get
  flutter build apk --debug

Important:
The first embedded MapView is intentionally isolated behind a PlatformView.
The existing Ranger map is not removed. This gives us a safe runtime checkpoint
before wiring Organic Maps search/routing/download UI directly into Flutter.
