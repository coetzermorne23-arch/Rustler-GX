import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/local_http_device.dart';
import 'esp_http_service.dart';
import 'local_device_config_service.dart';
import 'sonoff_diy_service.dart';
import 'tuya_bridge_service.dart';
import 'victron_entity_bridge_service.dart';

class IntegrationManagerService {
  IntegrationManagerService._();

  static final IntegrationManagerService instance =
      IntegrationManagerService._();

  final LocalDeviceConfigService configs = LocalDeviceConfigService.instance;
  final ValueNotifier<bool> running = ValueNotifier<bool>(false);
  final ValueNotifier<DateTime?> lastRestart = ValueNotifier<DateTime?>(null);

  final Map<String, Timer> _pollers = <String, Timer>{};
  bool _starting = false;

  Future<void> start() async {
    if (running.value || _starting) return;
    _starting = true;

    try {
      await configs.load();
      VictronEntityBridgeService.instance.start();

      configs.devices.removeListener(_restartLocalPollers);
      configs.devices.addListener(_restartLocalPollers);
      _restartLocalPollers();

      lastRestart.value = DateTime.now();
      running.value = true;
    } finally {
      _starting = false;
    }
  }

  Future<void> restart() async {
    stop();
    await start();
  }

  Future<void> refreshAll() async {
    await start();

    final List<Future<void>> jobs = <Future<void>>[];
    for (final LocalHttpDevice device in configs.devices.value) {
      if (!device.enabled) continue;
      jobs.add(_pollOnce(device));
    }
    await Future.wait(jobs);
  }

  void stop() {
    configs.devices.removeListener(_restartLocalPollers);

    for (final Timer timer in _pollers.values) {
      timer.cancel();
    }
    _pollers.clear();

    EspHttpService.instance.stopAll();
    VictronEntityBridgeService.instance.stop();
    running.value = false;
  }

  void _restartLocalPollers() {
    for (final Timer timer in _pollers.values) {
      timer.cancel();
    }
    _pollers.clear();
    EspHttpService.instance.stopAll();

    for (final LocalHttpDevice device in configs.devices.value) {
      if (!device.enabled) continue;

      switch (device.kind) {
        case LocalHttpDeviceKind.espJson:
        case LocalHttpDeviceKind.customJson:
          EspHttpService.instance.start(device);
          break;

        case LocalHttpDeviceKind.sonoffDiy:
        case LocalHttpDeviceKind.tuyaBridge:
          unawaited(_pollOnce(device));
          _pollers[device.id] = Timer.periodic(
            device.pollInterval,
            (_) => unawaited(_pollOnce(device)),
          );
          break;
      }
    }
  }

  Future<void> _pollOnce(LocalHttpDevice device) async {
    try {
      switch (device.kind) {
        case LocalHttpDeviceKind.espJson:
        case LocalHttpDeviceKind.customJson:
          await EspHttpService.instance.poll(device);
          break;
        case LocalHttpDeviceKind.sonoffDiy:
          await SonoffDiyService.instance.readSwitch(device);
          break;
        case LocalHttpDeviceKind.tuyaBridge:
          await TuyaBridgeService.instance.poll(device);
          break;
      }
    } catch (_) {
      // Individual integrations expose their own error notifiers. A failed
      // device must not stop the rest of the RigOS integration runtime.
    }
  }
}
