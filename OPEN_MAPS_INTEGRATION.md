# Rustler/Ranger GX open-source navigation direction

The core navigation requirement is offline and open-source.

## Current stable path
The existing Flutter OSM vector/MBTiles map remains enabled because it is already field-tested on the Ranger head unit.

## Organic Maps path
Organic Maps is an Apache-2.0 open-source offline navigation application powered by OpenStreetMap. It already provides offline search, POIs, routing and turn-by-turn navigation. Its Android engine is native/C++ and needs a deliberate bridge or fork integration rather than a fake Dart-only replacement.

Run:

    ./tools/setup_organic_maps_source.sh

This checks out upstream source under `vendor/organicmaps/` for native integration work. Do not commit the whole vendor checkout to Rustler GX unless intentionally vendoring it.

## Integration goals
- Offline South Africa maps
- OSM POIs and offline search
- Car routing / turn-by-turn navigation
- Ranger GX UI remains the head-unit shell
- Ranger GPS service remains the shared vehicle location source where practical
- No Google Maps dependency
- Visible Organic Maps/OpenStreetMap attribution as required

## Distribution
Review Organic Maps LICENSE, NOTICE and DATA_LICENSE before redistributing source, UI or `.mwm` data. Upstream explicitly requires visible Organic Maps Project attribution for derivative apps using its source/UI/binary map data.
