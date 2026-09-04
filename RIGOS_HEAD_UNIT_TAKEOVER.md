# RigOS Head Unit Takeover — FULL batch

Included in this full source snapshot:
- RigOS Android HOME intent/launcher role
- boot receiver reduced from 5 s delay to 250 ms
- existing immersive mode + keep-screen-on retained
- Android app label renamed to RigOS
- Head Unit → Performance settings
- installed launcher/HOME package diagnostics
- classifications: SAFE TO DISABLE / VENDOR-HARDWARE KEEP / UNKNOWN
- protection list for MCU/CAN/SWC/Bluetooth/FM/radio/audio/DSP/USB/GPS/GNSS/core Android
- root/privileged package-control detection
- direct `pm disable-user --user 0` when root is available
- direct `pm enable` restore
- RigOS remembers packages it disabled using SharedPreferences
- RESTORE ALL
- DISABLE SAFE BLOAT
- DISABLE STOCK HOME is blocked until RigOS is confirmed as Android HOME
- non-root radios fall back to Android App Info rather than pretending disable worked
- current map-search Icons.camping compile error fixed

IMPORTANT:
Android does not allow an ordinary third-party APK to silently disable other apps.
Direct package disable therefore works only when the head unit grants root/privileged
access. RigOS detects that at runtime. This batch does not fake success.

Workflow:
  cd ~/rustler_gx
  unzip -o ~/Downloads/RigOS_HeadUnit_Takeover_FULL.zip -d .
  flutter clean
  flutter pub get
  dart format lib
  flutter analyze

WHEN ANALYZE IS CLEAN:
  git add -A
  git commit -m "RigOS head unit takeover clean baseline"
  git push
  git tag -a rigos-headunit-takeover-01 -m "RigOS head unit takeover clean baseline"
  git push origin rigos-headunit-takeover-01

ONLY THEN:
  flutter build apk --debug
