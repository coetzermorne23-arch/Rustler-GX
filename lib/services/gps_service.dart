import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class GpsService {
  GpsService._();

  static final GpsService instance =
      GpsService._();

  final ValueNotifier<Position?> position =
      ValueNotifier<Position?>(null);

  final ValueNotifier<String?> error =
      ValueNotifier<String?>(null);

  StreamSubscription<Position>? _subscription;

  bool get isRunning =>
      _subscription != null;

  Future<void> start() async {
    if (_subscription != null) {
      return;
    }

    final bool enabled =
        await Geolocator.isLocationServiceEnabled();

    if (!enabled) {
      error.value =
          'GPS / Location is disabled.';
      return;
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission ==
        LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (permission ==
            LocationPermission.denied ||
        permission ==
            LocationPermission.deniedForever) {
      error.value =
          'Location permission denied.';
      return;
    }

    error.value = null;

    try {
      position.value =
          await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
        ),
      );
    } catch (_) {}

    _subscription =
        Geolocator.getPositionStream(
      locationSettings:
          const LocationSettings(
        accuracy:
            LocationAccuracy.bestForNavigation,
        distanceFilter: 1,
      ),
    ).listen(
      (Position newPosition) {
        position.value =
            newPosition;

        error.value = null;
      },
      onError: (Object value) {
        error.value =
            value.toString();
      },
    );
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}