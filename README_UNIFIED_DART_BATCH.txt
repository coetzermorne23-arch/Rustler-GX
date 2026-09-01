RUSTLER GX + RANGER GX UNIFIED DART BATCH
============================================

Extract this ZIP directly into:
  ~/rustler_gx

Everything in this ZIP is a COMPLETE Dart file, not a patch.

Included:
- Standard Rustler GX / Ranger_GX profile persistence
- Ranger head-unit runtime
- GPS/media startup
- Settings profile switching
- Media access refresh
- Global vehicle warning overlay
- Generic OBD data model/service foundation
- Engine-running vs ignition-on state foundation
- Trip/fuel integration foundation
- Reusable Ranger vehicle status card for below the media card

No Ford-specific warning limits are invented here.
No fake oil-pressure value is generated.
No OBD Bluetooth transport is included yet; we will bind the selected scanner later.

No new pub packages are required for this batch.

After extract:
  cd ~/rustler_gx
  dart format lib
  flutter analyze

Then, only if analyze is clean:
  flutter build apk --debug
