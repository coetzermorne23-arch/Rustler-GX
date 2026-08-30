class VictronLiveData {
  final String serial;
  final String name;

  // Battery
  final double? batteryVoltage;
  final double? batteryCurrent;
  final double? power;
  final double? stateOfCharge;
  final double? temperature;

  // Battery monitor / SmartShunt
  final double? consumedAh;
  final int? remainingMinutes;
  final double? starterVoltage;
  final double? midpointVoltage;
  final int? alarmCode;
  final int? auxMode;

  // Charger output
  final double? chargeCurrent;
  final String? chargeState;
  final int? chargerError;

  // Solar / MPPT
  final double? pvVoltage;
  final double? pvCurrent;
  final double? pvPower;
  final double? yieldToday;
  final double? loadCurrent;

  // DC-DC / Orion
  final double? inputVoltage;
  final double? outputVoltage;
  final double? outputCurrent;
  final double? outputPower;

  final DateTime updatedAt;

  const VictronLiveData({
    required this.serial,
    required this.name,
    this.batteryVoltage,
    this.batteryCurrent,
    this.power,
    this.stateOfCharge,
    this.temperature,
    this.consumedAh,
    this.remainingMinutes,
    this.starterVoltage,
    this.midpointVoltage,
    this.alarmCode,
    this.auxMode,
    this.chargeCurrent,
    this.chargeState,
    this.chargerError,
    this.pvVoltage,
    this.pvCurrent,
    this.pvPower,
    this.yieldToday,
    this.loadCurrent,
    this.inputVoltage,
    this.outputVoltage,
    this.outputCurrent,
    this.outputPower,
    required this.updatedAt,
  });

  factory VictronLiveData.empty() {
    return VictronLiveData(
      serial: '',
      name: '',
      updatedAt: DateTime.now(),
    );
  }

  VictronLiveData copyWith({
    String? serial,
    String? name,
    double? batteryVoltage,
    double? batteryCurrent,
    double? power,
    double? stateOfCharge,
    double? temperature,
    double? consumedAh,
    int? remainingMinutes,
    double? starterVoltage,
    double? midpointVoltage,
    int? alarmCode,
    int? auxMode,
    double? chargeCurrent,
    String? chargeState,
    int? chargerError,
    double? pvVoltage,
    double? pvCurrent,
    double? pvPower,
    double? yieldToday,
    double? loadCurrent,
    double? inputVoltage,
    double? outputVoltage,
    double? outputCurrent,
    double? outputPower,
    DateTime? updatedAt,
  }) {
    return VictronLiveData(
      serial: serial ?? this.serial,
      name: name ?? this.name,
      batteryVoltage: batteryVoltage ?? this.batteryVoltage,
      batteryCurrent: batteryCurrent ?? this.batteryCurrent,
      power: power ?? this.power,
      stateOfCharge: stateOfCharge ?? this.stateOfCharge,
      temperature: temperature ?? this.temperature,
      consumedAh: consumedAh ?? this.consumedAh,
      remainingMinutes: remainingMinutes ?? this.remainingMinutes,
      starterVoltage: starterVoltage ?? this.starterVoltage,
      midpointVoltage: midpointVoltage ?? this.midpointVoltage,
      alarmCode: alarmCode ?? this.alarmCode,
      auxMode: auxMode ?? this.auxMode,
      chargeCurrent: chargeCurrent ?? this.chargeCurrent,
      chargeState: chargeState ?? this.chargeState,
      chargerError: chargerError ?? this.chargerError,
      pvVoltage: pvVoltage ?? this.pvVoltage,
      pvCurrent: pvCurrent ?? this.pvCurrent,
      pvPower: pvPower ?? this.pvPower,
      yieldToday: yieldToday ?? this.yieldToday,
      loadCurrent: loadCurrent ?? this.loadCurrent,
      inputVoltage: inputVoltage ?? this.inputVoltage,
      outputVoltage: outputVoltage ?? this.outputVoltage,
      outputCurrent: outputCurrent ?? this.outputCurrent,
      outputPower: outputPower ?? this.outputPower,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
