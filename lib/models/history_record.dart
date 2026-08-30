class HistoryRecord {
  final String deviceId;
  final String deviceName;
  final DateTime timestamp;

  final double? batteryVoltage;
  final double? batteryCurrent;
  final double? batteryPower;
  final double? stateOfCharge;

  final double? pvVoltage;
  final double? pvCurrent;
  final double? pvPower;

  final double? chargeCurrent;
  final String? chargeState;

  final double? inputVoltage;
  final double? outputVoltage;
  final double? outputCurrent;
  final double? outputPower;

  const HistoryRecord({
    required this.deviceId,
    required this.deviceName,
    required this.timestamp,
    this.batteryVoltage,
    this.batteryCurrent,
    this.batteryPower,
    this.stateOfCharge,
    this.pvVoltage,
    this.pvCurrent,
    this.pvPower,
    this.chargeCurrent,
    this.chargeState,
    this.inputVoltage,
    this.outputVoltage,
    this.outputCurrent,
    this.outputPower,
  });

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'timestamp': timestamp.toIso8601String(),
      'batteryVoltage': batteryVoltage,
      'batteryCurrent': batteryCurrent,
      'batteryPower': batteryPower,
      'stateOfCharge': stateOfCharge,
      'pvVoltage': pvVoltage,
      'pvCurrent': pvCurrent,
      'pvPower': pvPower,
      'chargeCurrent': chargeCurrent,
      'chargeState': chargeState,
      'inputVoltage': inputVoltage,
      'outputVoltage': outputVoltage,
      'outputCurrent': outputCurrent,
      'outputPower': outputPower,
    };
  }

  factory HistoryRecord.fromJson(
    Map<String, dynamic> json,
  ) {
    return HistoryRecord(
      deviceId: json['deviceId'] as String? ?? '',
      deviceName: json['deviceName'] as String? ?? '',
      timestamp: DateTime.parse(
        json['timestamp'] as String,
      ),
      batteryVoltage: _double(json['batteryVoltage']),
      batteryCurrent: _double(json['batteryCurrent']),
      batteryPower: _double(json['batteryPower']),
      stateOfCharge: _double(json['stateOfCharge']),
      pvVoltage: _double(json['pvVoltage']),
      pvCurrent: _double(json['pvCurrent']),
      pvPower: _double(json['pvPower']),
      chargeCurrent: _double(json['chargeCurrent']),
      chargeState: json['chargeState'] as String?,
      inputVoltage: _double(json['inputVoltage']),
      outputVoltage: _double(json['outputVoltage']),
      outputCurrent: _double(json['outputCurrent']),
      outputPower: _double(json['outputPower']),
    );
  }

  static double? _double(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return null;
  }
}
