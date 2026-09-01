# Rustler GX Roadmap

This roadmap describes the current direction of the project. It is not a promise of release dates.

## Phase 1 — Core platform

- [x] Flutter application foundation
- [x] Android/Linux development targets
- [x] Universal device model
- [x] Universal entity model
- [x] Device/entity registry
- [x] Victron Bluetooth development foundation
- [x] Standard Rustler GX interface

## Phase 2 — Ranger_GX

- [x] Dedicated head-unit profile
- [x] Persistent device-profile selection
- [x] GPS driving data
- [x] Large driving-speed interface
- [x] Media card foundation
- [x] Offline South Africa map import
- [x] Head-unit runtime/immersive mode
- [ ] Street labels
- [ ] Offline address/POI search
- [ ] Offline routing database
- [ ] Improved navigation instructions
- [ ] Destination handoff from phone
- [ ] Steering-wheel media control
- [ ] Reliable head-unit resume/autostart

## Phase 3 — Vehicle / OBD-II

- [x] Generic vehicle-data architecture
- [x] Engine-state architecture
- [x] Warning architecture
- [x] Trip/fuel-computer architecture
- [ ] Bluetooth OBD-II transport
- [ ] Adapter discovery and pairing
- [ ] Supported PID discovery
- [ ] RPM
- [ ] Coolant temperature
- [ ] MAP/boost where available
- [ ] Intake temperature
- [ ] Vehicle/charging voltage
- [ ] MAF where available
- [ ] Fuel-rate acquisition/calculation
- [ ] Trip fuel integration
- [ ] Fuel-consumption calibration
- [ ] Verified Ranger warning profiles
- [ ] Vehicle telemetry/history

## Phase 4 — Camping and off-grid

- [ ] Expanded Victron device support
- [ ] Bluetooth fridge integrations
- [ ] Water/tank sensors
- [ ] Pump and relay control
- [ ] ESP32 device protocol
- [ ] Temperature/environment sensors
- [ ] Configurable dashboard widgets
- [ ] History and charts

## Phase 5 — Rustler GX Hub

- [ ] Raspberry Pi hub runtime
- [ ] Local network API
- [ ] BLE aggregation
- [ ] Wi-Fi device aggregation
- [ ] Multi-client dashboards
- [ ] Head-unit ↔ hub communication
- [ ] Local-first persistence

## Long-term

Rustler GX should become a hardware-agnostic platform rather than a collection of hard-coded screens. New integrations should publish into the same device/entity architecture so vehicle, camping and energy data can coexist cleanly.
