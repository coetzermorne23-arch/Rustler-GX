# Ranger GX OBD + GPS Completion Batch

This batch adds the daily-driver foundation discussed for Ranger GX:

- Fast first-frame boot: capability runtime no longer blocks `runApp`.
- Ranger splash no longer waits for GPS/media/OBD or an artificial delay.
- GPS stream starts immediately with best-for-navigation accuracy and a stale-fix watchdog.
- Bluetooth Classic SPP OBD transport implemented natively in Kotlin for ELM327-compatible adapters.
- Pair the scanner in Android first, then select it from the Ranger GX OBD dashboard.
- Generic OBD-II supported-PID discovery and live polling for RPM, speed, coolant, intake temp, MAP, load, throttle, MAF, fuel rate (when supported), adapter voltage and calculated boost.
- Oil pressure remains `--` unless a future Ford-specific PID provider supplies it. No fake oil-pressure values are generated.
- Fuel rate falls back to a clearly approximate MAF-based diesel estimate when PID 0x5E is unavailable.
- Custom OBD dashboard supports DIALS or CARDS, selected metrics and reordering.
- Main Ranger home now shows the compact vehicle status card; tap it for the full OBD dashboard.
- GPS speed remains the main Ranger speed source. OBD and GPS speed can both be added to the vehicle dashboard for comparison.
- Offline map POI labels are made visible at a lower zoom level and search gets quick category chips for fuel, food, hospital, camping and ATM.

## First test

```bash
cd ~/rustler_gx
unzip -o ~/Downloads/Rustler_GX_Ranger_OBD_GPS_COMPLETE.zip -d .
dart format lib
flutter analyze
flutter build apk --debug
```

Hardware OBD test later:
1. Pair ELM327/Vgate in Android Bluetooth settings.
2. Ranger GX -> vehicle card -> Bluetooth icon.
3. Select the paired adapter.
4. Confirm RPM/coolant/MAP/voltage first.

The OBD transport is deliberately generic ELM327 SPP. Ford-specific Mode 22 PIDs should only be added after hardware captures confirm the exact ECU/PID behaviour.
