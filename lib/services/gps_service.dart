import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class GpsService {
  GpsService._();

  static final GpsService instance = GpsService._();

  final ValueNotifier<Position?> position = ValueNotifier<Position?>(
    null,
  );

  final ValueNotifier<String?> error = ValueNotifier<String?>(
    null,
  );

  final ValueNotifier<bool> starting = ValueNotifier<bool>(
    false,
  );

  StreamSubscription<Position>? _subscription;

  bool get isRunning => _subscription != null;

  Future<void> start() async {
    if (_subscription != null || starting.value) {
      return;
    }

    starting.value = true;

    try {
      final bool enabled = await Geolocator.isLocationServiceEnabled();

      if (!enabled) {
        error.value = 'GPS / Location is disabled.';

        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        error.value = 'Location permission denied.';

        return;
      }

      if (permission == LocationPermission.deniedForever) {
        error.value = 'Location permission permanently denied.';

        return;
      }

      error.value = null;

      try {
        final Position initial = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            timeLimit: Duration(
              seconds: 15,
            ),
          ),
        );

        position.value = initial;
      } catch (exception) {
        debugPrint(
          'Initial GPS position failed: '
          '$exception',
        );
      }

      _subscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 1,
        ),
      ).listen(
        (
          Position newPosition,
        ) {
          position.value = newPosition;

          error.value = null;
        },
        onError: (
          Object value,
        ) {
          error.value = value.toString();
        },
        cancelOnError: false,
      );
    } catch (exception) {
      error.value = 'GPS error: $exception';

      debugPrint(
        error.value,
      );
    } finally {
      starting.value = false;
    }
  }

  Future<void> restart() async {
    await stop();

    error.value = null;

    await start();
  }

  Future<void> stop() async {
    await _subscription?.cancel();

    _subscription = null;
  }

  Future<bool> openLocationSettings() {
    return Geolocator.openLocationSettings();
  }

  Future<bool> openAppSettings() {
    return Geolocator.openAppSettings();
  }

  void clearPosition() {
    position.value = null;
  }
}
