import '../../models/victron_live_data.dart';
import 'device_decoder.dart';

class BlueSmartDecoder extends DeviceDecoder {
  @override
  VictronLiveData decode(
    VictronLiveData current,
    String register,
    int raw,
  ) {
    switch (register) {
      case 'ed8d':
      case 'edd5':
        return current.copyWith(
          batteryVoltage: raw / 100,
        );

      case 'ed8c':
        final currentA = raw / 1000;

        return current.copyWith(
          chargeCurrent: currentA,
          power: current.batteryVoltage == null
              ? null
              : current.batteryVoltage! * currentA,
        );

      case 'ed8f':
      case 'edd7':
        return current.copyWith(
          temperature: raw.toDouble(),
        );

      default:
        return current;
    }
  }
}