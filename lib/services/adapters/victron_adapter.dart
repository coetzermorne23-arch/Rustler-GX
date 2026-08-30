import '../../models/victron_live_data.dart';

abstract class VictronAdapter {
  Stream<VictronLiveData> get liveData;

  Future<void> connect();

  Future<void> disconnect();

  Future<void> dispose();
}
