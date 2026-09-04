# Ranger GX Full UI + Media + GNSS custom batch

This is a COMPLETE source snapshot based on the current Ranger GX complete batch.

Included:
- Ranger GX full head-unit UI
- existing maps / navigation / GX / OBD work retained
- YouTube Music full Activity no longer steals foreground
- MUSIC opens Ranger GX source selector:
  - YouTube Music
  - USB
  - Bluetooth
  - Radio
- YouTube Music uses the existing Android MediaSession controls
- GPS status at the top is tappable and opens GPS / SATELLITES
- GPS dashboard can show/hide and reorder fields
- GPS layout persists with SharedPreferences
- Android native GnssStatus bridge:
  - visible satellites
  - satellites used in fix
  - GPS / Galileo / GLONASS / BeiDou counts
  - SVID
  - C/N0 signal strength
  - elevation
  - azimuth
  - constellation
- current Geolocator data retained:
  - speed
  - heading
  - altitude
  - accuracy
  - coordinates
  - timestamp

Important:
USB, Bluetooth-audio source switching and FM/AM tuner switching are present in
the Ranger GX UI but are not falsely wired to unknown vendor/MCU APIs. Those
three hardware actions need the actual double-DIN vendor interface later.

Build:
  cd ~/Downloads
  unzip Ranger_GX_FULL_UI_Media_GNSS_Custom_COMPLETE.zip
  cd Ranger_GX_FULL_UI_Media_GNSS_Custom_COMPLETE
  flutter pub get
  dart format lib
  flutter analyze
  flutter build apk --debug

APK:
  build/app/outputs/flutter-apk/app-debug.apk
