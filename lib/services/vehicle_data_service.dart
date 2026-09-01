import 'package:flutter/foundation.dart';

import '../models/vehicle_obd_data.dart';

class VehicleDataService {
  VehicleDataService._();

  static final VehicleDataService instance = VehicleDataService._();

  final ValueNotifier<VehicleObdData> data = ValueNotifier<VehicleObdData>(
    VehicleObdData.empty(),
  );

  bool get connected => data.value.connected;

  bool get engineRunning =>
      data.value.engineState == VehicleEngineState.running;

  void setConnected(
    bool connected,
  ) {
    final VehicleObdData current = data.value;

    data.value = current.copyWith(
      connected: connected,
      engineState: connected ? current.engineState : VehicleEngineState.unknown,
      updatedAt: DateTime.now(),
    );
  }

  void publish({
    double? rpm,
    double? vehicleSpeedKmh,
    double? coolantTemperatureC,
    double? intakeTemperatureC,
    double? batteryVoltage,
    double? boostBar,
    double? manifoldAbsolutePressureKpa,
    double? engineLoadPercent,
    double? throttlePercent,
    double? massAirFlowGps,
    double? fuelRateLitresPerHour,
    double? oilPressureKpa,
  }) {
    final VehicleObdData current = data.value;

    final double? resolvedRpm = rpm ?? current.rpm;

    final VehicleEngineState state;

    if (!current.connected) {
      state = VehicleEngineState.unknown;
    } else if (resolvedRpm == null) {
      state = current.engineState;
    } else if (resolvedRpm > 0) {
      state = VehicleEngineState.running;
    } else {
      state = VehicleEngineState.ignitionOnEngineOff;
    }

    data.value = current.copyWith(
      engineState: state,
      rpm: rpm,
      vehicleSpeedKmh: vehicleSpeedKmh,
      coolantTemperatureC: coolantTemperatureC,
      intakeTemperatureC: intakeTemperatureC,
      batteryVoltage: batteryVoltage,
      boostBar: boostBar,
      manifoldAbsolutePressureKpa: manifoldAbsolutePressureKpa,
      engineLoadPercent: engineLoadPercent,
      throttlePercent: throttlePercent,
      massAirFlowGps: massAirFlowGps,
      fuelRateLitresPerHour: fuelRateLitresPerHour,
      oilPressureKpa: oilPressureKpa,
      updatedAt: DateTime.now(),
    );
  }

  void clear() {
    data.value = VehicleObdData.empty();
  }
}
