RANGER_GX PHASE 2 - FULL REPLACEMENT FILE BATCH
================================================

WHAT THIS BATCH DOES
--------------------
1. Keeps the selected device profile persistent.
   - Existing "ranger_head_unit" preference from the previous batch is preserved.
2. Adds proper Standard <-> Ranger_GX switching in Settings.
3. Adds one central HeadUnitRuntimeService.
   - GPS starts.
   - Media session starts.
   - Head unit UI is restored.
4. Re-applies immersive/head-unit UI whenever Rustler GX resumes.
5. Media notification access now refreshes automatically after returning from Android settings.
6. GX button in Ranger_GX opens the normal Rustler dashboard instead of trying to pop the root route.
7. Head unit top branding says RANGER_GX.

IMPORTANT ABOUT RADIO AUTOSTART
-------------------------------
The current BootReceiver can launch Rustler GX after a real Android boot / quick-boot event.
A Chinese Android radio that is switched off for a few minutes often does NOT perform a real
Android reboot. It suspends and resumes its own launcher, so BOOT_COMPLETED is never fired.

That is why the radio can return to its launcher even though Rustler GX's saved Ranger mode works
when the app itself is opened.

We should solve that separately with either:
- the radio's OEM Auto Start setting, or
- an optional Ranger_GX launcher/home mode that is enabled ONLY on the dedicated radio.

I deliberately did NOT globally turn Rustler GX into an Android launcher in this batch because
that would also affect phone/tablet installs.

INSTALL
-------
Extract this ZIP directly over the Rustler GX repo root so these paths merge into your existing:
  lib/services/
  lib/features/

Then run:

  cd ~/rustler_gx
  dart format lib
  flutter analyze
  flutter build apk --debug

No new pub packages are required in this batch.
