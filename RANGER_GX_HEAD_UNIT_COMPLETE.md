# Ranger GX Head Unit completion batch

This batch builds on the current Maps V2 source.

Implemented foundations:
- Optional Android HOME/launcher role for dedicated head-unit use.
- Existing boot receiver retained; HOME role is the reliable path for cold boot/home return.
- YouTube Music remains the preferred media session.
- Bluetooth/stock media sessions are fallback sources when exposed by Android.
- Steering-wheel media keys are intercepted in MainActivity when the firmware sends them to Android.
- Bluetooth/phone call notifications can overlay Ranger GX; answer/decline uses notification actions when exposed by the head unit.
- Removable USB storage detection is exposed to Flutter; USB presence does not replace YouTube Music as default.
- Head-unit runtime refreshes media, GPS, USB/call state after resume.

Hardware/firmware limitation:
Some Chinese Android head units bind SWC keys directly to a vendor BT Music app below the normal Android activity/media-session layer. If NEXT launches BT Music before Ranger GX receives the KeyEvent, Android app code cannot cancel that earlier firmware action. Disable/re-map the vendor SWC action in the head unit's factory/SWC settings if available.

Test order:
1. flutter analyze
2. flutter build apk --debug
3. Install update over existing app.
4. Enable Notification Access for Rustler GX if not already enabled.
5. On the radio only, choose Ranger GX as the HOME app when Android prompts / from head-unit settings.
6. Test cold boot, sleep/wake, Home key, YT Music controls, SWC NEXT/PREV, incoming BT call, USB insertion.
