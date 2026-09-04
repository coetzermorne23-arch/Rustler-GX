RUSTLER / RANGER GX - NO YOUTUBE MUSIC FOREGROUND PATCH

This patch changes only:
  lib/services/media_launcher_service.dart

Result:
- Ranger GX stays in the foreground.
- Any existing openYouTubeMusic() call becomes a harmless no-op.
- MediaSessionService, steering controls, maps, GPS, OBD, IoT and Victron code
  are not changed.

Apply:
cd ~/rustler_gx
unzip -o ~/Downloads/Rustler_GX_No_YTM_Foreground_PATCH.zip -d .
dart format lib
flutter analyze
flutter build apk --debug

APK:
build/app/outputs/flutter-apk/app-debug.apk
