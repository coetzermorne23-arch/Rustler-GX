enum VehicleEngineState {
  unknown,
  ignitionOnEngineOff,
  running,
}

class VehicleObdData {
  final bool connected;
  final VehicleEngineState engineState;

  final double? rpm;
  final double? vehicleSpeedKmh;
  final double? coolantTemperatureC;
  final double? intakeTemperatureC;
  final double? batteryVoltage;
  final double? boostBar;
  final double? manifoldAbsolutePressureKpa;
  final double? engineLoadPercent;
  final double? throttlePercent;
  final double? massAirFlowGps;
  final double? fuelRateLitresPerHour;
  final double? oilPressureKpa;

  final DateTime updatedAt;

  const VehicleObdData({
    required this.connected,
    required this.engineState,
    required this.updatedAt,
    this.rpm,
    this.vehicleSpeedKmh,
    this.coolantTemperatureC,
    this.intakeTemperatureC,
    this.batteryVoltage,
    this.boostBar,
    this.manifoldAbsolutePressureKpa,
    this.engineLoadPercent,
    this.throttlePercent,
    this.massAirFlowGps,
    this.fuelRateLitresPerHour,
    this.oilPressureKpa,
  });

  factory VehicleObdData.empty() {
    return VehicleObdData(
      connected: false,
      engineState: VehicleEngineState.unknown,
      updatedAt: DateTime.now(),
    );
  }

  VehicleObdData copyWith({
    bool? connected,
    VehicleEngineState? engineState,
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
    DateTime? updatedAt,
    bool clearRpm = false,
    bool clearVehicleSpeed = false,
    bool clearCoolantTemperature = false,
    bool clearIntakeTemperature = false,
    bool clearBatteryVoltage = false,
    bool clearBoost = false,
    bool clearMap = false,
    bool clearEngineLoad = false,
    bool clearThrottle = false,
    bool clearMaf = false,
    bool clearFuelRate = false,
    bool clearOilPressure = false,
  }) {
    return VehicleObdData(
      connected: connected ?? this.connected,
      engineState: engineState ?? this.engineState,
      rpm: clearRpm ? null : rpm ?? this.rpm,
      vehicleSpeedKmh:
          clearVehicleSpeed ? null : vehicleSpeedKmh ?? this.vehicleSpeedKmh,
      coolantTemperatureC: clearCoolantTemperature
          ? null
          : coolantTemperatureC ?? this.coolantTemperatureC,
      intakeTemperatureC: clearIntakeTemperature
          ? null
          : intakeTemperatureC ?? this.intakeTemperatureC,
      batteryVoltage:
          clearBatteryVoltage ? null : batteryVoltage ?? this.batteryVoltage,
      boostBar: clearBoost ? null : boostBar ?? this.boostBar,
      manifoldAbsolutePressureKpa: clearMap
          ? null
          : manifoldAbsolutePressureKpa ?? this.manifoldAbsolutePressureKpa,
      engineLoadPercent:
          clearEngineLoad ? null : engineLoadPercent ?? this.engineLoadPercent,
      throttlePercent:
          clearThrottle ? null : throttlePercent ?? this.throttlePercent,
      massAirFlowGps: clearMaf ? null : massAirFlowGps ?? this.massAirFlowGps,
      fuelRateLitresPerHour: clearFuelRate
          ? null
          : fuelRateLitresPerHour ?? this.fuelRateLitresPerHour,
      oilPressureKpa:
          clearOilPressure ? null : oilPressureKpa ?? this.oilPressureKpa,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
