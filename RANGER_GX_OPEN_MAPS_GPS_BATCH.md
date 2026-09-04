# Ranger GX Open Maps + High-Rate GPS batch

## Included now
- High-priority GNSS service using Android best-for-navigation accuracy and zero distance filter.
- Faster stale-fix watchdog/reacquisition.
- Responsive GPS speed output with minimal jitter smoothing; large acceleration/deceleration changes are not averaged away.
- Existing Ranger GX offline OSM/MBTiles navigation remains the active map engine, so the current working map is preserved.
- Organic Maps integration plan and helper tooling are included without replacing the working map stack yet.

## Why Organic Maps is staged instead of blindly copied into Flutter
Organic Maps is a large native C++/Android application, not a drop-in Dart package. Replacing the current Flutter map engine in one patch without building/testing its native engine would risk breaking the daily-driver map. This batch keeps the working OSM map and adds reproducible helper tooling for the next native integration step.

Organic Maps source: https://github.com/organicmaps/organicmaps

The Organic Maps project requires attribution for derivative apps. If its source/UI/binary map data is integrated into Rustler/Ranger GX, add the required visible attribution before distribution.

## GPS hardware note
The app requests every navigation-quality fix Android supplies. A 1 Hz (or faster) real fix rate cannot be forced if the head unit GNSS chipset/firmware only publishes slower fixes. `GpsService.fixInterval` exposes the measured interval so the hardware can be diagnosed on the radio.
