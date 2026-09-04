RigOS MEGA ALL-IN-ONE BATCH

Built from the user's uploaded working RigOS_Source_Only source snapshot.

Major additions in this batch:
- Platform branding changed toward RigOS while preserving existing internal Dart class/package names for compatibility.
- Rig identity/profile layer: Vehicle, Caravan, Camper, Portable Power, Custom.
- User-editable installation name (default Ranger Rango on a fresh install).
- Main RigOS Settings UI.
- Universal pairing registry: Bluetooth entry point, local integrations, IP/hostname, QR payload import, network protocol/port storage.
- Local-first SRNE endpoint settings with IP/hostname, Modbus TCP port, unit ID and TCP reachability test.
- Universal normalized-entity Energy Flow screen for solar, battery/SOC, DC/DC and inverter/load.
- Existing Victron, entity registry, ESP/Sonoff/Tuya, OBD, GNSS, maps, media, trips and warnings retained.
- Head-unit home shows the user-defined rig name plus RigOS and adds a Settings shortcut.
- Existing MEDIA source selector retained.
- Offline map search improved with strict + forgiving token matching, direct coordinate entry and quick POI categories (fuel, supermarket, hospital, restaurant, campsite, ATM).
- Startup no longer waits synchronously for the entire capability runtime before runApp; initialization starts in the background.

Important boundaries:
- USB/BT/FM source switching still requires the specific Chinese head-unit vendor/MCU API. It is not faked.
- SRNE exact register decoding is intentionally adapter-specific. This batch creates the persistent local endpoint and connectivity foundation rather than guessing register maps.
- QR import accepts a RigOS pairing payload. Camera QR scanning can be added once a scanner dependency is selected; pasted/scanned payload import works without another dependency.
- Offline search quality is limited by the imported south_africa_search.sqlite dataset. The query engine is more forgiving now, but a place absent from the DB cannot be invented offline.

INSTALL OVER CURRENT PROJECT:
cd ~/rustler_gx
cp -a lib ~/rustler_gx_lib_backup_pre_rigos_mega
unzip -o ~/Downloads/RigOS_Mega_All_In_One_Batch.zip -d .
flutter clean
flutter pub get
dart format lib
flutter analyze

If analyze has no errors:
flutter build apk --debug

APK:
build/app/outputs/flutter-apk/app-debug.apk
