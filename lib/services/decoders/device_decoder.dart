import '../../models/victron_live_data.dart';

abstract class DeviceDecoder {
  VictronLiveData decode(
    VictronLiveData current,
    String registerId,
    int rawValue,
  );
}
