RANGER GX FULL HEAD-UNIT UI BATCH

This batch:
- makes Ranger GX itself the root/full radio UI
- removes the normal splash delay from startup
- moves heavy CapabilityRuntimeService initialization behind first frame
- starts GPS/media after first frame
- stops all existing MediaLauncherService calls from opening full YouTube Music
- keeps native Ranger GX media controls in foreground
- gives HOME: speed/GPS, media, Ranger Live OBD area, clock/status
- keeps MAP and DRIVE screens
- keeps the existing full GX Dashboard reachable
- adds OBD gauge positions now; live ELM327 values come when scanner hardware is available

APPLY:
cd ~/rustler_gx
cp -a lib ~/rustler_gx_lib_backup_before_full_ui
unzip -o ~/Downloads/Rustler_GX_Ranger_Full_UI_Batch.zip -d .
dart format lib
flutter analyze
flutter build apk --debug

APK:
build/app/outputs/flutter-apk/app-debug.apk
