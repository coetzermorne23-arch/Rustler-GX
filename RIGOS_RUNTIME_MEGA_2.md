# RigOS Runtime Mega Batch 2

Includes:
- Main head-unit branding is RigOS; installation name remains secondary/user configurable.
- Bottom bar: HOME / MAP / DRIVE / MUSIC / SETTINGS.
- Main right column: media plus live OBD quick panel (RPM, boost, coolant, battery, load, OBD speed).
- OBD quick panel opens full customizable OBD dashboard.
- Maps search now merges saved places + offline SQLite search + live OpenStreetMap/Nominatim South Africa search when network is available.
- Existing offline map rendering remains intact.
- Head-unit app cleanup screen lists launchable installed apps and opens Android App Info for safe user-controlled Disable/Force Stop.
- RigOS can be selected as Android HOME launcher from Head Unit settings.

Why app cleanup is user-controlled:
Normal third-party Android apps cannot silently disable other packages without system/device-owner/root privileges. Chinese head units also hide MCU/CAN/BT/tuner functionality in vendor packages. RigOS therefore inventories apps and opens the exact Android App Info screen instead of blindly killing critical vehicle services.
