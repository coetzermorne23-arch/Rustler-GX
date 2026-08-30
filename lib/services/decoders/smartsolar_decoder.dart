import '../../models/victron_live_data.dart';
import 'device_decoder.dart';

class SmartSolarDecoder extends DeviceDecoder {
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
          power: _batteryPower(
            voltage,
            current.chargeCurrent,
          ),
        );

      // Charger / battery output current
      case 'ed8c':
        final amps = raw / 1000.0;

        return current.copyWith(
          chargeCurrent: amps,
          batteryCurrent: amps,
          power: _batteryPower(
            current.batteryVoltage,
            amps,
          ),
        );

      // PV voltage
      case 'edbb':
        final voltage = raw / 100.0;

        return current.copyWith(
          pvVoltage: voltage,
          pvPower: _pvPower(
            voltage,
            current.pvCurrent,
          ),
        );

      // PV current
      case 'edbc':
        final amps = raw / 1000.0;

        return current.copyWith(
          pvCurrent: amps,
          pvPower: _pvPower(
            current.pvVoltage,
            amps,
          ),
        );

      // PV power - direct value where available
      case 'edbd':
        final watts = raw.toDouble();

        return current.copyWith(
          pvPower: watts,
        );

      // Charger state
      case 'edb3':
        return current.copyWith(
          chargeState: _chargeState(raw),
        );

      // Temperature
      case 'ed8f':
        return current.copyWith(
          temperature: raw.toDouble(),
        );

      default:
        return current;
    }
  }

  double? _batteryPower(
    double? voltage,
    double? current,
  ) {
    if (voltage == null || current == null) {
      return null;
    }

    return voltage * current;
  }

  double? _pvPower(
    double? voltage,
    double? current,
  ) {
    if (voltage == null || current == null) {
      return null;
    }

    return voltage * current;
  }

  String _chargeState(int code) {
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

      case 11:
        return 'Other';

      case 245:
        return 'Wake-up';

      case 252:
        return 'External control';

      default:
        return 'Unknown ($code)';
    }
  }
}
