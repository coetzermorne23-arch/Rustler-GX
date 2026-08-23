import '../../models/victron_live_data.dart';
import 'device_decoder.dart';

class OrionDecoder extends DeviceDecoder {
  @override
  VictronLiveData decode(
    VictronLiveData current,
    String register,
    int raw,
  ) {
    switch (register.toLowerCase()) {
      // Input / starter battery voltage
      case 'edbb':
        return current.copyWith(
          inputVoltage: raw / 100.0,
        );

      // Output / service battery voltage
      case 'ed8d':
      case 'edd5':
        final voltage = raw / 100.0;

        return current.copyWith(
          batteryVoltage: voltage,
          outputVoltage: voltage,
          outputPower: _calculatePower(
            voltage,
            current.outputCurrent,
          ),
        );

      // Output current
      case 'ed8c':
        final amps = raw / 1000.0;

        return current.copyWith(
          batteryCurrent: amps,
          chargeCurrent: amps,
          outputCurrent: amps,
          outputPower: _calculatePower(
            current.outputVoltage ??
                current.batteryVoltage,
            amps,
          ),
        );

      // Temperature
      case 'ed8f':
        return current.copyWith(
          temperature: raw / 100.0,
        );

      // Operating / charge state
      case 'edb3':
        return current.copyWith(
          chargeState: _stateFromCode(raw),
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

  String _stateFromCode(int code) {
    switch (code) {
      case 0:
        return 'Off';

      case 2:
        return 'Fault';

      case 3:
        return 'Bulk';

      case 4:
        return 'Absorption';

      case 5:
        return 'Float';

      case 6:
        return 'Storage';

      case 7:
        return 'Equalize';

      case 252:
        return 'External control';

      default:
        return 'Unknown ($code)';
    }
  }
}