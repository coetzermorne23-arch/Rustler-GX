# Rustler GX

**An open-source vehicle, camping and off-grid control platform built in South Africa.**

Rustler GX is a Flutter-based platform designed to bring vehicle data, navigation, media, Bluetooth devices, off-grid power systems and custom hardware into one clean interface.

The project started as a practical system for camping and vehicle electronics and grew into something much bigger: a universal GX-style platform that can run on phones, tablets, computers, Raspberry Pi-based hubs and Android vehicle head units.

## Ranger_GX

**Ranger_GX** is the dedicated vehicle/head-unit profile inside Rustler GX.

It grew from a real-world Ford Ranger T6/T7 head-unit project and is being designed around an interface that is actually useful while driving: large GPS speed, media controls, offline navigation and vehicle information without turning the screen into a wall of gauges.

Ranger_GX and Rustler GX share the same core platform. Ranger-specific features do not replace the universal Rustler GX experience.

## Current direction

Rustler GX is under active development.

### Working / implemented

- Flutter Android and Linux foundation
- Universal device and entity architecture
- Victron Bluetooth development and live-data support
- Dedicated Ranger_GX head-unit profile
- GPS position and driving speed
- South Africa offline vector map support
- Media integration foundation
- Persistent Standard / Ranger_GX device profiles
- Head-unit runtime and immersive UI support
- Vehicle/OBD data architecture foundation
- Global vehicle-warning architecture
- Trip and fuel-computer architecture foundation

### In development

- Street labels and improved offline map rendering
- Offline address and POI search
- Offline route database and navigation improvements
- YouTube Music / steering-wheel media integration
- OBD-II Bluetooth communication
- Live engine data
- Trip fuel usage and fuel-consumption calculations
- Configurable vehicle warnings
- Destination sharing between a phone and Ranger_GX

### Planned

- Victron SmartSolar, SmartShunt, Blue Smart and Orion expansion
- Raspberry Pi hub mode
- Wi-Fi/LAN device aggregation
- Fridge monitoring
- Water and tank-level monitoring
- Relay and accessory control
- Generic ESP32 sensors and controllers
- Customisable dashboard widgets
- Trip history and telemetry
- Additional vehicle/head-unit profiles
- More offline map regions
- Android Auto-related integrations where practical

## Vehicle telemetry philosophy

Rustler GX will not invent vehicle values.

OBD-II parameters are only displayed when the connected vehicle/ECU actually provides them. Manufacturer-specific warning thresholds will only be added when they can be properly verified.

For Ranger_GX, vehicle telemetry is intended to remain secondary to driving information. The main screen keeps the large speed display and media card, with useful vehicle information below it. Navigation remains clean and OBD information should interrupt the map only when a meaningful warning needs the driver's attention.

## Off-grid and camping

Rustler GX is not only a vehicle dashboard.

The long-term goal is one platform capable of monitoring and controlling systems such as:

- Solar charging
- Battery banks
- DC/DC chargers
- AC chargers
- Fridges
- Water tanks
- Pumps
- Relays
- Temperature sensors
- GPS
- Vehicle telemetry
- Other local Bluetooth, Wi-Fi and ESP-based hardware

The aim is to keep as much functionality **local-first** as possible.

## Why Rustler GX?

This project is being built because vehicle, camping and off-grid systems often end up spread across multiple manufacturer apps and displays.

Rustler GX aims to provide one interface and one common device/entity layer while still allowing individual integrations to evolve independently.

## Support development

Rustler GX is an independent project. If you like where it is going and want to help fund development, testing hardware, OBD adapters, head units and future integrations, you can support the project on Patreon:

**[Support Rustler GX on Patreon](https://www.patreon.com/cw/MorneCoetzer)**

Supporters can receive development updates, previews, early/experimental builds and opportunities to help influence which integrations are prioritised.

See [SUPPORT.md](SUPPORT.md) for the proposed supporter structure.

## Open source and supporter features

The Rustler GX core is intended to remain open source.

Some future convenience features, experimental builds, supporter previews, hosted services or separately developed supporter extras may be offered to Patreon supporters. Any distribution of GPL-covered Rustler GX code remains subject to the GPL.

## Contributing

The project is still moving quickly, so APIs and architecture may change.

Bug reports, hardware testing, protocol research and code contributions are welcome.

Read [CONTRIBUTING.md](CONTRIBUTING.md) before submitting a pull request.

## Safety

Rustler GX is an enthusiast software project, not a replacement for factory vehicle warning systems, certified diagnostic equipment or safe driving practices.

Do not rely on Rustler GX as the sole warning mechanism for engine, electrical or safety-critical conditions. Never interact with the application in a way that distracts you while driving.

## License

Rustler GX is released under the **GNU General Public License v3.0**.

See [LICENSE](LICENSE).

---

Built in South Africa by **Morne Coetzer**.

**Project:** https://github.com/coetzermorne23-arch/Rustler-GX  
**Patreon:** https://www.patreon.com/cw/MorneCoetzer
