import 'dart:async';

import '../../models/entity_sources.dart';
import '../../models/rustler_device.dart';
import '../../models/rustler_entity.dart';
import '../../models/victron_device_type.dart';
import '../../models/victron_live_data.dart';
import '../bluetooth_service.dart';
import '../device_entity_link_service.dart';

class VictronEntityBridgeService {
  VictronEntityBridgeService._();

  static final VictronEntityBridgeService instance =
      VictronEntityBridgeService._();

  final VictronBluetoothService _bluetooth = VictronBluetoothService.instance;
  final DeviceEntityLinkService _links = DeviceEntityLinkService.instance;

  bool _started = false;
  Timer? _staleTimer;

  void start() {
    if (_started) return;
    _started = true;

    _bluetooth.liveDevices.addListener(_syncAll);
    _bluetooth.connectedDevice.addListener(_syncAll);
    _staleTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _markStaleDevices(),
    );
    _syncAll();
  }

  void stop() {
    if (!_started) return;
    _bluetooth.liveDevices.removeListener(_syncAll);
    _bluetooth.connectedDevice.removeListener(_syncAll);
    _staleTimer?.cancel();
    _staleTimer = null;
    _started = false;
  }

  void _syncAll() {
    for (final MapEntry<String, VictronLiveData> entry
        in _bluetooth.liveDevices.value.entries) {
      _publish(entry.key, entry.value);
    }
  }

  void _markStaleDevices() {
    final DateTime now = DateTime.now();
    for (final MapEntry<String, VictronLiveData> entry
        in _bluetooth.liveDevices.value.entries) {
      final Duration age = now.difference(entry.value.updatedAt);
      if (age > const Duration(seconds: 15)) {
        _links.setDeviceAvailability('victron.${_slug(entry.key)}', false);
      }
    }
  }

  void _publish(String rawDeviceId, VictronLiveData data) {
    final String deviceId = 'victron.${_slug(rawDeviceId)}';
    final DateTime timestamp = data.updatedAt;
    final RustlerDeviceType type = _deviceType(rawDeviceId, data);

    _links.registerDevice(
      RustlerDevice(
        id: deviceId,
        name: data.name.isEmpty ? 'Victron Device' : data.name,
        manufacturer: 'Victron Energy',
        model: _modelName(rawDeviceId, type),
        type: type,
        source: EntitySources.victron,
        available: true,
        updatedAt: timestamp,
      ),
    );

    void number(
      String key,
      String name,
      num? value, {
      String? unit,
      RustlerEntityType entityType = RustlerEntityType.number,
    }) {
      if (value == null) return;
      _links.publishEntity(
        deviceId: deviceId,
        entity: RustlerEntity(
          id: '$deviceId.$key',
          name: name,
          type: entityType,
          value: value,
          unit: unit,
          source: EntitySources.victron,
          available: true,
          updatedAt: timestamp,
        ),
      );
    }

    void text(String key, String name, String? value) {
      if (value == null || value.isEmpty) return;
      _links.publishEntity(
        deviceId: deviceId,
        entity: RustlerEntity(
          id: '$deviceId.$key',
          name: name,
          type: RustlerEntityType.sensor,
          value: value,
          source: EntitySources.victron,
          available: true,
          updatedAt: timestamp,
        ),
      );
    }

    number(
      'battery_voltage',
      'Battery Voltage',
      data.batteryVoltage,
      unit: 'V',
      entityType: RustlerEntityType.battery,
    );
    number(
      'battery_current',
      'Battery Current',
      data.batteryCurrent,
      unit: 'A',
      entityType: RustlerEntityType.battery,
    );
    number(
      'battery_power',
      'Battery Power',
      data.power,
      unit: 'W',
      entityType: RustlerEntityType.battery,
    );
    number(
      'state_of_charge',
      'State of Charge',
      data.stateOfCharge,
      unit: '%',
      entityType: RustlerEntityType.battery,
    );
    number('temperature', 'Temperature', data.temperature, unit: '°C');
    number(
      'consumed_ah',
      'Consumed Ah',
      data.consumedAh,
      unit: 'Ah',
      entityType: RustlerEntityType.battery,
    );
    number('remaining_minutes', 'Time Remaining', data.remainingMinutes,
        unit: 'min');
    number('starter_voltage', 'Starter Voltage', data.starterVoltage,
        unit: 'V');
    number('midpoint_voltage', 'Midpoint Voltage', data.midpointVoltage,
        unit: 'V');
    number('alarm_code', 'Alarm Code', data.alarmCode);
    number('aux_mode', 'Aux Mode', data.auxMode);
    number('charge_current', 'Charge Current', data.chargeCurrent, unit: 'A');
    text('charge_state', 'Charge State', data.chargeState);
    number('charger_error', 'Charger Error', data.chargerError);
    number('pv_voltage', 'PV Voltage', data.pvVoltage, unit: 'V');
    number('pv_current', 'PV Current', data.pvCurrent, unit: 'A');
    number('pv_power', 'PV Power', data.pvPower, unit: 'W');
    number('yield_today', 'Yield Today', data.yieldToday, unit: 'kWh');
    number('load_current', 'Load Current', data.loadCurrent, unit: 'A');
    number('input_voltage', 'Input Voltage', data.inputVoltage, unit: 'V');
    number('output_voltage', 'Output Voltage', data.outputVoltage, unit: 'V');
    number('output_current', 'Output Current', data.outputCurrent, unit: 'A');
    number('output_power', 'Output Power', data.outputPower, unit: 'W');

    _links.setDeviceAvailability(deviceId, true);
  }

  RustlerDeviceType _deviceType(String rawId, VictronLiveData data) {
    final connected = _bluetooth.connectedDevice.value;
    if (connected != null && connected.device.remoteId.str == rawId) {
      switch (connected.type) {
        case VictronDeviceType.smartShunt:
          return RustlerDeviceType.batteryMonitor;
        case VictronDeviceType.smartSolar:
          return RustlerDeviceType.solarCharger;
        case VictronDeviceType.blueSmartCharger:
          return RustlerDeviceType.acCharger;
        case VictronDeviceType.orionSmart:
        case VictronDeviceType.orionXs:
          return RustlerDeviceType.dcDcCharger;
        case VictronDeviceType.unknown:
          break;
      }
    }

    if (data.pvPower != null ||
        data.pvVoltage != null ||
        data.yieldToday != null) {
      return RustlerDeviceType.solarCharger;
    }
    if (data.stateOfCharge != null || data.consumedAh != null) {
      return RustlerDeviceType.batteryMonitor;
    }
    if (data.inputVoltage != null && data.outputVoltage != null) {
      return RustlerDeviceType.dcDcCharger;
    }
    if (data.chargeCurrent != null || data.chargeState != null) {
      return RustlerDeviceType.acCharger;
    }
    return RustlerDeviceType.unknown;
  }

  String? _modelName(String rawId, RustlerDeviceType inferred) {
    final connected = _bluetooth.connectedDevice.value;
    if (connected != null && connected.device.remoteId.str == rawId) {
      switch (connected.type) {
        case VictronDeviceType.smartShunt:
          return 'SmartShunt / BMV';
        case VictronDeviceType.smartSolar:
          return 'SmartSolar MPPT';
        case VictronDeviceType.blueSmartCharger:
          return 'Blue Smart Charger';
        case VictronDeviceType.orionSmart:
          return 'Orion Smart';
        case VictronDeviceType.orionXs:
          return 'Orion XS';
        case VictronDeviceType.unknown:
          break;
      }
    }

    return switch (inferred) {
      RustlerDeviceType.batteryMonitor => 'Battery Monitor',
      RustlerDeviceType.solarCharger => 'Solar Charger',
      RustlerDeviceType.acCharger => 'AC Charger',
      RustlerDeviceType.dcDcCharger => 'DC-DC Charger',
      _ => null,
    };
  }

  String _slug(String value) {
    final String result = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return result.isEmpty ? 'device' : result;
  }
}
