import 'dart:async';

import '../../models/victron_live_data.dart';

class DashboardRepository {
  DashboardRepository._();

  static final DashboardRepository instance =
      DashboardRepository._();

  final Map<String, VictronLiveData> _devices = {};

  final StreamController<List<VictronLiveData>> _controller =
      StreamController.broadcast();

  Stream<List<VictronLiveData>> get devices =>
      _controller.stream;

  void update(VictronLiveData data) {
    _devices[data.serial] = data;

    _controller.add(
      _devices.values.toList()
        ..sort(
          (a, b) => a.name.compareTo(b.name),
        ),
    );
  }

  void remove(String serial) {
    _devices.remove(serial);
    _controller.add(_devices.values.toList());
  }

  void clear() {
    _devices.clear();
    _controller.add([]);
  }

  List<VictronLiveData> get current =>
      _devices.values.toList();
}