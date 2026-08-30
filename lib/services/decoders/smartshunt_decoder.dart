import '../../models/victron_live_data.dart';
import 'device_decoder.dart';

class SmartShuntDecoder extends DeviceDecoder {
  @override
  VictronLiveData decode(
    VictronLiveData current,
    String register,
    int raw,
  ) {
    switch (register.toLowerCase()) {
      // Battery voltage
      case 'ed8d':
      case 'edd5':
        final voltage = raw / 100.0;

        return current.copyWith(
          batteryVoltage: voltage,
          power: _calculatePower(
            voltage,
            current.batteryCurrent,
          ),
        );

      // Battery current
      case 'ed8c':
        final amps = raw / 1000.0;

        return current.copyWith(
          batteryCurrent: amps,
          power: _calculatePower(
            current.batteryVoltage,
            amps,
          ),
        );

      // State of charge
      case '0fff':
        return current.copyWith(
          stateOfCharge: raw / 10.0,
        );

      // Temperature
      case 'ed8f':
        return current.copyWith(
          temperature: raw / 100.0,
        );

      default:
        return current;
    }
  }

  double? _calculatePower(
    double? voltage,
    double? current,
  ) {
    if (voltage == null || current == null) {
      return null;
    }

    return voltage * current;
  }
}
