import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/vehicle_obd_data.dart';
import 'vehicle_data_service.dart';

class VehicleTripData {
  final double distanceKm;
  final double fuelUsedLitres;
  final Duration engineRuntime;

  const VehicleTripData({
    required this.distanceKm,
    required this.fuelUsedLitres,
    required this.engineRuntime,
  });

  double? get averageLitresPer100Km {
    if (distanceKm <= 0.05) {
      return null;
    }

    return fuelUsedLitres / distanceKm * 100.0;
  }

  VehicleTripData copyWith({
    double? distanceKm,
    double? fuelUsedLitres,
    Duration? engineRuntime,
  }) {
    return VehicleTripData(
      distanceKm: distanceKm ?? this.distanceKm,
      fuelUsedLitres: fuelUsedLitres ?? this.fuelUsedLitres,
      engineRuntime: engineRuntime ?? this.engineRuntime,
    );
  }

  static const VehicleTripData empty = VehicleTripData(
    distanceKm: 0,
    fuelUsedLitres: 0,
    engineRuntime: Duration.zero,
  );
}

class VehicleTripService {
  VehicleTripService._();

  static final VehicleTripService instance = VehicleTripService._();

  final VehicleDataService vehicle = VehicleDataService.instance;

  final ValueNotifier<VehicleTripData> trip = ValueNotifier<VehicleTripData>(
    VehicleTripData.empty,
  );

  Timer? _timer;
  DateTime? _lastTick;

  void start() {
    if (_timer != null) {
      return;
    }

    _lastTick = DateTime.now();

    _timer = Timer.periodic(
      const Duration(
        seconds: 1,
      ),
      (_) {
        _tick();
      },
    );
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _lastTick = null;
  }

  void reset() {
    trip.value = VehicleTripData.empty;

    _lastTick = DateTime.now();
  }

  void _tick() {
    final DateTime now = DateTime.now();

    final DateTime previous = _lastTick ?? now;

    _lastTick = now;

    final double seconds = now.difference(previous).inMilliseconds / 1000.0;

    if (seconds <= 0) {
      return;
    }

    final VehicleObdData data = vehicle.data.value;

    if (!data.connected || data.engineState != VehicleEngineState.running) {
      return;
    }

    final VehicleTripData current = trip.value;

    final double speedKmh = data.vehicleSpeedKmh ?? 0;

    final double distanceAddedKm = speedKmh * (seconds / 3600.0);

    final double fuelRate = data.fuelRateLitresPerHour ?? 0;

    final double fuelAddedLitres = fuelRate * (seconds / 3600.0);

    trip.value = current.copyWith(
      distanceKm: current.distanceKm + distanceAddedKm,
      fuelUsedLitres: current.fuelUsedLitres + fuelAddedLitres,
      engineRuntime: current.engineRuntime +
          Duration(
            milliseconds: (seconds * 1000).round(),
          ),
    );
  }
}
