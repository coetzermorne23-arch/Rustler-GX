import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/victron_device.dart';
import '../models/victron_device_type.dart';
import '../models/victron_live_data.dart';
import '../models/rustler_entity.dart';
import '../models/entity_sources.dart';
import '../models/rustler_device.dart';

import 'adapters/legacy_gatt_adapter.dart';
import 'adapters/victron_adapter.dart';

import 'instant_readout/victron_instant_readout_decoder.dart';
import 'victron_key_service.dart';

import 'history_service.dart';
import 'entity_service.dart';
import 'device_entity_link_service.dart';
import 'device_registry_service.dart';

class VictronBluetoothService {
  VictronBluetoothService._();

  static final VictronBluetoothService instance =
      VictronBluetoothService._();

  static const int victronManufacturerId = 0x02e1;

  final VictronKeyService _keyService =
      VictronKeyService.instance;

  final VictronInstantReadoutDecoder _instantDecoder =
      const VictronInstantReadoutDecoder();

  final ValueNotifier<VictronDevice?> connectedDevice =
      ValueNotifier<VictronDevice?>(null);

  final ValueNotifier<VictronLiveData> liveData =
      ValueNotifier<VictronLiveData>(
    VictronLiveData.empty(),
  );

  /// ALL live Victron devices.
  ///
  /// Key = Bluetooth remote ID.
  final ValueNotifier<Map<String, VictronLiveData>>
      liveDevices =
      ValueNotifier<Map<String, VictronLiveData>>({});

  StreamSubscription<BluetoothConnectionState>?
      _connectionSubscription;

  StreamSubscription<VictronLiveData>?
      _liveDataSubscription;

  VictronAdapter? _activeAdapter;

  // Prevent decoding the same advertisement several
  // times simultaneously.
  final Set<String> _processingInstantReadout = {};
  final Set<String> _autoConnectingDevices = {};

  final Map<String, DateTime> _lastAutoConnectAttempt = {};

  static const Duration _autoConnectRetryInterval =
    Duration(seconds: 30);

  Stream<List<VictronDevice>> get devices {
  return FlutterBluePlus.scanResults.map((results) {
    final Map<String, VictronDevice> uniqueDevices = {};

    for (final result in results) {
      final advertisement = result.advertisementData;

      final List<int> victronManufacturerData =
          advertisement.manufacturerData[
                  victronManufacturerId] ??
              const [];

      final bool hasInstantReadout =
          victronManufacturerData.isNotEmpty &&
              victronManufacturerData.first == 0x10;

      // Victron manufacturer data after the company ID:
      //
      // byte 0-1 = prefix 0x0210
      // byte 2-3 = model/product ID
      // byte 4   = Instant Readout record type
      //
      // flutter_blue_plus gives us the payload after
      // the manufacturer/company ID, hence these offsets.

      int? modelId;
      int? recordType;

      if (hasInstantReadout &&
          victronManufacturerData.length >= 5) {
        modelId =
            victronManufacturerData[2] |
                (victronManufacturerData[3] << 8);

        recordType =
            victronManufacturerData[4];
      }

      final String combinedName =
          '${result.device.platformName} '
                  '${advertisement.advName}'
              .toLowerCase();

      final VictronDeviceType type =
          _identifyDeviceType(
        combinedName: combinedName,
        hasInstantReadout: hasInstantReadout,
        modelId: modelId,
        recordType: recordType,
      );

      final bool looksLikeVictron =
          type != VictronDeviceType.unknown ||
              hasInstantReadout ||
              victronManufacturerData.isNotEmpty;

      if (!looksLikeVictron) {
        continue;
      }

      final VictronDevice victronDevice =
          VictronDevice(
        device: result.device,
        platformName: result.device.platformName,
        advertisedName: advertisement.advName,
        rssi: result.rssi,
        type: type,
        hasInstantReadout: hasInstantReadout,
        manufacturerData: victronManufacturerData,
        modelId: modelId,
        recordType: recordType,
      );

      final String deviceId =
          result.device.remoteId.str;

      uniqueDevices[deviceId] =
          victronDevice;

      if (hasInstantReadout) {
        debugPrint(
          'VICTRON ADVERTISEMENT '
          '${victronDevice.displayName} '
          '$deviceId '
          'model=${victronDevice.modelIdHex} '
          'record=${victronDevice.recordTypeHex}: '
          '${victronDevice.manufacturerDataHex}',
        );

        unawaited(
          _processInstantReadout(
            victronDevice,
          ),
        );
      }

      unawaited(
        _autoHandleKnownDevice(
          victronDevice,
        ),
      );
    }

    return uniqueDevices.values.toList()
      ..sort(
        (a, b) =>
            b.rssi.compareTo(a.rssi),
      );
  });
}

  static VictronDeviceType _identifyDeviceType({
  required String combinedName,
  required bool hasInstantReadout,
  int? modelId,
  int? recordType,
}) {
  // =========================================================
  // INSTANT READOUT RECORD TYPE
  // =========================================================
  //
  // This is preferred over the Bluetooth name because
  // Victron devices can be renamed by the user.

  if (hasInstantReadout &&
      recordType != null) {
    switch (recordType) {
      // Battery Monitor:
      // SmartShunt / BMV family
      case 0x02:
        return VictronDeviceType.smartShunt;

      // Solar Charger:
      // SmartSolar MPPT family
      case 0x01:
        return VictronDeviceType.smartSolar;

      // DC/DC converter family.
      //
      // Exact Orion Smart vs Orion XS identification
      // can later be refined using modelId.
      case 0x04:
        if (combinedName.contains('orion xs')) {
          return VictronDeviceType.orionXs;
        }

        return VictronDeviceType.orionSmart;

      // AC Charger:
      // Blue Smart Charger family
      case 0x08:
        return VictronDeviceType.blueSmartCharger;
    }
  }

  // =========================================================
  // NAME FALLBACK
  // =========================================================
  //
  // Used for legacy devices or advertisements where the
  // Instant Readout record type is unavailable.

  if (combinedName.contains('smartshunt') ||
      combinedName.contains('smart shunt') ||
      combinedName.contains('bmv')) {
    return VictronDeviceType.smartShunt;
  }

  if (combinedName.contains('smartsolar') ||
      combinedName.contains('smart solar') ||
      combinedName.contains('mppt')) {
    return VictronDeviceType.smartSolar;
  }

  if (combinedName.contains('orion xs')) {
    return VictronDeviceType.orionXs;
  }

  if (combinedName.contains('orion')) {
    return VictronDeviceType.orionSmart;
  }

  if (combinedName.contains('bsc') ||
      combinedName.contains('blue smart') ||
      combinedName.contains('charger')) {
    return VictronDeviceType.blueSmartCharger;
  }

  return VictronDeviceType.unknown;
}
  Future<void> _processInstantReadout(
    VictronDevice device,
  ) async {
    final String deviceId =
        device.device.remoteId.str;

    if (_processingInstantReadout.contains(deviceId)) {
      return;
    }

    _processingInstantReadout.add(deviceId);

    try {
      final String? encryptionKey =
          await _keyService.getKey(deviceId);

      if (encryptionKey == null ||
          encryptionKey.isEmpty) {
        return;
      }

      if (device.manufacturerData.isEmpty) {
        return;
      }

      final VictronInstantReadoutResult result =
          _instantDecoder.decode(
        manufacturerData: device.manufacturerData,
        encryptionKey: encryptionKey,
        deviceType: device.type,
      );

      final VictronLiveData current =
          liveDevices.value[deviceId] ??
              VictronLiveData(
                serial: deviceId,
                name: device.displayName,
                updatedAt: DateTime.now(),
              );

      final VictronLiveData decoded =
          _resultToLiveData(
        current: current,
        device: device,
        result: result,
      );

      _updateLiveDevice(
        deviceId,
        decoded,
        device: device,
      );

      debugPrint(
        'INSTANT READOUT ${device.displayName}: '
        '${result.values}',
      );
    } on FormatException catch (error) {
      debugPrint(
        'Instant Readout decode failed '
        '${device.displayName}: $error',
      );
    } catch (error) {
      debugPrint(
        'Instant Readout error '
        '${device.displayName}: $error',
      );
    } finally {
      _processingInstantReadout.remove(deviceId);
    }
  }

  VictronLiveData _resultToLiveData({
    required VictronLiveData current,
    required VictronDevice device,
    required VictronInstantReadoutResult result,
  }) {
    final Map<String, dynamic> values =
        result.values;

    switch (device.type) {
      // =========================================================
      // SMARTSHUNT / BMV
      // =========================================================
      case VictronDeviceType.smartShunt:
        return current.copyWith(
          serial: device.device.remoteId.str,
          name: device.displayName,

          batteryVoltage:
              _doubleValue(
            values['batteryVoltage'],
          ),

          batteryCurrent:
              _doubleValue(
            values['batteryCurrent'],
          ),

          power:
              _doubleValue(
            values['batteryPower'],
          ),

          stateOfCharge:
              _doubleValue(
            values['stateOfCharge'],
          ),

          temperature:
              _doubleValue(
            values['temperature'],
          ),

          consumedAh:
              _doubleValue(
            values['consumedAh'],
          ),

          remainingMinutes:
              _intValue(
            values['remainingMinutes'],
          ),

          starterVoltage:
              _doubleValue(
            values['starterVoltage'],
          ),

          midpointVoltage:
              _doubleValue(
            values['midpointVoltage'],
          ),

          alarmCode:
              _intValue(
            values['alarmCode'],
          ),

          auxMode:
              _intValue(
            values['auxMode'],
          ),

          updatedAt: DateTime.now(),
        );

      // =========================================================
      // SMARTSOLAR MPPT
      // =========================================================
      case VictronDeviceType.smartSolar:
        final double? batteryVoltage =
            _doubleValue(
          values['batteryVoltage'],
        );

        final double? chargeCurrent =
            _doubleValue(
          values['chargeCurrent'],
        );

        final double? solarPower =
            _doubleValue(
          values['solarPower'],
        );

        /*
         * Instant Readout gives solar power directly.
         *
         * PV current is therefore calculated:
         *
         *      I = P / V
         *
         * ONLY when PV voltage is available.
         */
        final double? pvVoltage =
            _doubleValue(
          values['pvVoltage'],
        );

        final double? pvCurrent =
            pvVoltage != null &&
                    pvVoltage > 0 &&
                    solarPower != null
                ? solarPower / pvVoltage
                : current.pvCurrent;

        final double? outputPower =
            batteryVoltage != null &&
                    chargeCurrent != null
                ? batteryVoltage *
                    chargeCurrent
                : current.power;

        return current.copyWith(
          serial:
              device.device.remoteId.str,

          name:
              device.displayName,

          batteryVoltage:
              batteryVoltage,

          batteryCurrent:
              chargeCurrent,

          chargeCurrent:
              chargeCurrent,

          power:
              outputPower,

          pvVoltage:
              pvVoltage,

          pvCurrent:
              pvCurrent,

          pvPower:
              solarPower,

          yieldToday:
              _yieldWhToKwh(
            values['yieldTodayWh'],
          ),

          loadCurrent:
              _doubleValue(
            values['loadCurrent'],
          ),

          chargerError:
              _intValue(
            values['chargerError'],
          ),

          chargeState:
              values['chargeState']
                  ?.toString(),

          updatedAt:
              DateTime.now(),
        );

      // =========================================================
      // ORION SMART / ORION XS
      // =========================================================
      case VictronDeviceType.orionSmart:
      case VictronDeviceType.orionXs:
        /*
         * Orion Instant Readout is being decrypted,
         * but exact payload mapping is still pending.
         *
         * Keep the device alive on the dashboard
         * without inventing measurements.
         */
        return current.copyWith(
          serial:
              device.device.remoteId.str,

          name:
              device.displayName,

          updatedAt:
              DateTime.now(),
        );

      // =========================================================
      // BLUE SMART CHARGER
      // =========================================================
      case VictronDeviceType.blueSmartCharger:
        final double? batteryVoltage =
            _doubleValue(
          values['batteryVoltage'],
        );

        final double? chargeCurrent =
            _doubleValue(
          values['chargeCurrent'],
        );

        final double? calculatedPower =
            batteryVoltage != null &&
                    chargeCurrent != null
                ? batteryVoltage *
                    chargeCurrent
                : null;

        return current.copyWith(
          serial:
              device.device.remoteId.str,

          name:
              device.displayName,

          batteryVoltage:
              batteryVoltage,

          batteryCurrent:
              chargeCurrent,

          chargeCurrent:
              chargeCurrent,

          power:
              _doubleValue(
                values['power'],
              ) ??
              calculatedPower ??
              current.power,

          temperature:
              _doubleValue(
            values['temperature'],
          ),

          chargeState:
              values['chargeState']
                  ?.toString(),

          chargerError:
              _intValue(
            values['chargerError'],
          ),

          updatedAt:
              DateTime.now(),
        );

      // =========================================================
      // UNKNOWN VICTRON
      // =========================================================
      case VictronDeviceType.unknown:
        return current.copyWith(
          serial:
              device.device.remoteId.str,

          name:
              device.displayName,

          updatedAt:
              DateTime.now(),
        );
    }
  }
  double? _doubleValue(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    if (value is num) {
      return value.toDouble();
    }

    return null;
  }
    int? _intValue(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return null;
  }

  double? _yieldWhToKwh(dynamic value) {
    final double? wh =
        _doubleValue(value);

    if (wh == null) {
      return null;
    }

    return wh / 1000.0;
  }

  void _updateLiveDevice(
    String deviceId,
    VictronLiveData data, {
    VictronDevice? device,
  }) {
    final Map<String, VictronLiveData> updated =
        Map<String, VictronLiveData>.from(
      liveDevices.value,
    );

    updated[deviceId] = data;

    liveDevices.value = updated;
    liveData.value = data;

    unawaited(
      HistoryService.instance.record(data),
    );

    _publishEntities(
      deviceId,
      data,
      device: device,
    );
  }

  void _publishEntities(
    String deviceId,
    VictronLiveData data, {
    VictronDevice? device,
  }) {
    final EntityService entityService =
        EntityService.instance;

    final DeviceEntityLinkService linkService =
        DeviceEntityLinkService.instance;

    final DeviceRegistryService registry =
        DeviceRegistryService.instance;

    // Device identity is based on Bluetooth ID, not the user-renamed
    // Victron device name. Renaming a SmartShunt therefore does not
    // create a new Rustler GX device or new entity IDs.
    final String deviceKey =
        _entitySlug(deviceId);

    final String registryDeviceId =
        'victron:$deviceKey';

    final String sourcePrefix =
        'victron.$deviceKey';

    final RustlerDevice? existingDevice =
        registry.getDevice(registryDeviceId);

    linkService.registerDevice(
      RustlerDevice(
        id: registryDeviceId,
        name: data.name.isNotEmpty
            ? data.name
            : device?.displayName ?? 'Victron Device',
        manufacturer: 'Victron Energy',
        model: _victronModelLabel(device),
        type: _rustlerDeviceType(
          device?.type,
          data,
        ),
        source: EntitySources.victron,
        available: true,
        updatedAt: data.updatedAt,
        entityIds: existingDevice?.entityIds ??
            const <String>[],
      ),
    );

    void publishEntity(
      RustlerEntity entity,
    ) {
      // Keep EntityService directly available for legacy callers while
      // also attaching the entity to the universal device registry.
      entityService.upsert(entity);

      linkService.publishEntity(
        deviceId: registryDeviceId,
        entity: entity,
      );
    }

    void publishDouble({
      required String key,
      required String name,
      required double? value,
      String? unit,
      RustlerEntityType type =
          RustlerEntityType.sensor,
    }) {
      if (value == null) {
        return;
      }

      publishEntity(
        RustlerEntity(
          id: '$sourcePrefix.$key',
          name: name,
          type: type,
          value: value,
          unit: unit,
          source: EntitySources.victron,
          available: true,
          updatedAt: data.updatedAt,
        ),
      );
    }

    void publishInt({
      required String key,
      required String name,
      required int? value,
      String? unit,
    }) {
      if (value == null) {
        return;
      }

      publishEntity(
        RustlerEntity(
          id: '$sourcePrefix.$key',
          name: name,
          type: RustlerEntityType.sensor,
          value: value,
          unit: unit,
          source: EntitySources.victron,
          available: true,
          updatedAt: data.updatedAt,
        ),
      );
    }

    void publishText({
      required String key,
      required String name,
      required String? value,
    }) {
      if (value == null || value.isEmpty) {
        return;
      }

      publishEntity(
        RustlerEntity(
          id: '$sourcePrefix.$key',
          name: name,
          type: RustlerEntityType.sensor,
          value: value,
          source: EntitySources.victron,
          available: true,
          updatedAt: data.updatedAt,
        ),
      );
    }

    publishDouble(
      key: 'battery_voltage',
      name: 'Battery Voltage',
      value: data.batteryVoltage,
      unit: 'V',
      type: RustlerEntityType.battery,
    );

    publishDouble(
      key: 'battery_current',
      name: 'Battery Current',
      value: data.batteryCurrent,
      unit: 'A',
      type: RustlerEntityType.battery,
    );

    publishDouble(
      key: 'battery_power',
      name: 'Battery Power',
      value: data.power,
      unit: 'W',
      type: RustlerEntityType.battery,
    );

    publishDouble(
      key: 'state_of_charge',
      name: 'State of Charge',
      value: data.stateOfCharge,
      unit: '%',
      type: RustlerEntityType.battery,
    );

    publishDouble(
      key: 'temperature',
      name: 'Temperature',
      value: data.temperature,
      unit: '°C',
    );

    publishDouble(
      key: 'consumed_ah',
      name: 'Consumed Ah',
      value: data.consumedAh,
      unit: 'Ah',
      type: RustlerEntityType.battery,
    );

    publishInt(
      key: 'remaining_minutes',
      name: 'Time Remaining',
      value: data.remainingMinutes,
      unit: 'min',
    );

    publishDouble(
      key: 'starter_voltage',
      name: 'Starter Voltage',
      value: data.starterVoltage,
      unit: 'V',
    );

    publishDouble(
      key: 'midpoint_voltage',
      name: 'Midpoint Voltage',
      value: data.midpointVoltage,
      unit: 'V',
    );

    publishInt(
      key: 'alarm_code',
      name: 'Alarm Code',
      value: data.alarmCode,
    );

    publishInt(
      key: 'aux_mode',
      name: 'Aux Mode',
      value: data.auxMode,
    );

    publishDouble(
      key: 'charge_current',
      name: 'Charge Current',
      value: data.chargeCurrent,
      unit: 'A',
    );

    publishText(
      key: 'charge_state',
      name: 'Charge State',
      value: data.chargeState,
    );

    publishInt(
      key: 'charger_error',
      name: 'Charger Error',
      value: data.chargerError,
    );

    publishDouble(
      key: 'pv_voltage',
      name: 'PV Voltage',
      value: data.pvVoltage,
      unit: 'V',
    );

    publishDouble(
      key: 'pv_current',
      name: 'PV Current',
      value: data.pvCurrent,
      unit: 'A',
    );

    publishDouble(
      key: 'pv_power',
      name: 'PV Power',
      value: data.pvPower,
      unit: 'W',
    );

    publishDouble(
      key: 'yield_today',
      name: 'Yield Today',
      value: data.yieldToday,
      unit: 'kWh',
    );

    publishDouble(
      key: 'load_current',
      name: 'Load Current',
      value: data.loadCurrent,
      unit: 'A',
    );

    publishDouble(
      key: 'input_voltage',
      name: 'Input Voltage',
      value: data.inputVoltage,
      unit: 'V',
    );

    publishDouble(
      key: 'output_voltage',
      name: 'Output Voltage',
      value: data.outputVoltage,
      unit: 'V',
    );

    publishDouble(
      key: 'output_current',
      name: 'Output Current',
      value: data.outputCurrent,
      unit: 'A',
    );

    publishDouble(
      key: 'output_power',
      name: 'Output Power',
      value: data.outputPower,
      unit: 'W',
    );
  }

  RustlerDeviceType _rustlerDeviceType(
    VictronDeviceType? type,
    VictronLiveData data,
  ) {
    switch (type) {
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
      case null:
        break;
    }

    // Fallback for legacy data where advertisement metadata may be absent.
    if (data.stateOfCharge != null ||
        data.consumedAh != null ||
        data.remainingMinutes != null) {
      return RustlerDeviceType.batteryMonitor;
    }

    if (data.pvPower != null ||
        data.pvVoltage != null ||
        data.yieldToday != null) {
      return RustlerDeviceType.solarCharger;
    }

    if (data.inputVoltage != null ||
        data.outputVoltage != null ||
        data.outputCurrent != null) {
      return RustlerDeviceType.dcDcCharger;
    }

    if (data.chargeCurrent != null ||
        data.chargeState != null ||
        data.chargerError != null) {
      return RustlerDeviceType.acCharger;
    }

    return RustlerDeviceType.unknown;
  }

  String? _victronModelLabel(
    VictronDevice? device,
  ) {
    if (device == null) {
      return null;
    }

    switch (device.type) {
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
        return device.modelId == null
            ? null
            : device.modelIdHex;
    }
  }

  String _entitySlug(String value) {
    final String normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    if (normalized.isNotEmpty) {
      return normalized;
    }

    return 'device';
  }

  Future<void> _autoHandleKnownDevice(
  VictronDevice device,
) async {
  final String deviceId =
      device.device.remoteId.str;

  final bool known =
      await _keyService.isKnownDevice(
    deviceId,
  );

  if (!known) {
    return;
  }

  // =========================================================
  // INSTANT READOUT
  // =========================================================
  //
  // Devices with a stored key don't need a permanent GATT
  // connection. _processInstantReadout() already handles
  // their advertisements automatically.

  if (device.hasInstantReadout) {
    final String? key =
        await _keyService.getKey(
      deviceId,
    );

    if (key != null &&
        key.isNotEmpty) {
      return;
    }
  }

  // =========================================================
  // LEGACY / GATT AUTO CONNECT
  // =========================================================

  final VictronDevice? currentlyConnected =
      connectedDevice.value;

  if (currentlyConnected != null) {
    final String currentId =
        currentlyConnected.device.remoteId.str;

    if (currentId == deviceId) {
      return;
    }

    // The current adapter architecture supports one active
    // GATT device at a time. Do not kick another known
    // device off just because another advertisement arrived.
    return;
  }

  if (_autoConnectingDevices.contains(
    deviceId,
  )) {
    return;
  }

  final DateTime now =
      DateTime.now();

  final DateTime? lastAttempt =
      _lastAutoConnectAttempt[
    deviceId
  ];

  if (lastAttempt != null &&
      now.difference(lastAttempt) <
          _autoConnectRetryInterval) {
    return;
  }

  _lastAutoConnectAttempt[deviceId] =
      now;

  _autoConnectingDevices.add(
    deviceId,
  );

  try {
    debugPrint(
      'AUTO CONNECT known device: '
      '${device.displayName}',
    );

    await connect(
      device,
    );

    debugPrint(
      'AUTO CONNECT success: '
      '${device.displayName}',
    );
  } catch (error) {
    debugPrint(
      'AUTO CONNECT failed '
      '${device.displayName}: $error',
    );
  } finally {
    _autoConnectingDevices.remove(
      deviceId,
    );
  }
}
   
  Future<void> _ensureBluetoothPermissions() async {
    if (!Platform.isAndroid) {
      return;
    }

    final Map<Permission, PermissionStatus> statuses =
        await <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    final PermissionStatus scanStatus =
        statuses[Permission.bluetoothScan] ??
            PermissionStatus.denied;

    final PermissionStatus connectStatus =
        statuses[Permission.bluetoothConnect] ??
            PermissionStatus.denied;

    if (scanStatus.isPermanentlyDenied ||
        connectStatus.isPermanentlyDenied) {
      throw Exception(
        'Bluetooth permission is permanently denied. '
        'Open Android Settings > Apps > Rustler GX > '
        'Permissions and allow Nearby devices.',
      );
    }

    if (!scanStatus.isGranted ||
        !connectStatus.isGranted) {
      throw Exception(
        'Bluetooth permission is required to scan '
        'and connect to nearby devices.',
      );
    }
  }

  Future<void> startScan() async {
    if (!await FlutterBluePlus.isSupported) {
      throw Exception(
        'Bluetooth is not supported on this device.',
      );
    }

    await _ensureBluetoothPermissions();

    final BluetoothAdapterState adapterState =
        await FlutterBluePlus.adapterState.first;

    if (adapterState != BluetoothAdapterState.on) {
      throw Exception(
        'Bluetooth is turned off. Turn Bluetooth on '
        'and try again.',
      );
    }

    await FlutterBluePlus.stopScan();

    debugPrint('Rustler GX Bluetooth scan started');

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 15),
    );
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Future<void> connect(
    VictronDevice victronDevice,
  ) async {
  final String deviceId =
      victronDevice.device.remoteId.str;

  // If this exact GATT device is already connected,
  // there is nothing to do.
  if (connectedDevice
          .value
          ?.device
          .remoteId
          .str ==
      deviceId) {
    return;
  }

  await disconnect();
  await stopScan();

  // =========================================================
  // INSTANT READOUT
  // =========================================================

  if (victronDevice.hasInstantReadout) {
    final String? key =
        await _keyService.getKey(
      deviceId,
    );

    if (key != null &&
        key.isNotEmpty) {
      debugPrint(
        'Using Instant Readout for '
        '${victronDevice.displayName}',
      );

      await _keyService.rememberDevice(
        deviceId,
      );

      await _processInstantReadout(
        victronDevice,
      );

      connectedDevice.value =
          victronDevice;

      return;
    }

    // MPPT / SmartShunt / Orion need the Instant Readout
    // key. Don't attempt the Legacy Blue Smart adapter.
    if (victronDevice.type !=
        VictronDeviceType.blueSmartCharger) {
      throw UnsupportedError(
        'Encryption key required for '
        '${victronDevice.displayName}',
      );
    }

    // Blue Smart can still use our Legacy GATT path
    // when no Instant Readout key is stored.
    debugPrint(
      'No Instant Readout key for '
      '${victronDevice.displayName}; '
      'using Legacy GATT',
    );
  }

  // =========================================================
  // LEGACY GATT
  // =========================================================

  debugPrint(
    'Connecting to '
    '${victronDevice.displayName}',
  );

  _activeAdapter =
      _createAdapter(
    victronDevice,
  );

  _liveDataSubscription =
      _activeAdapter!.liveData.listen(
    (data) {
      final VictronLiveData identified =
          data.copyWith(
        serial: deviceId,
        name: victronDevice.displayName,
        updatedAt: DateTime.now(),
      );

      _updateLiveDevice(
        deviceId,
        identified,
        device: victronDevice,
      );
    },
  );

  _connectionSubscription =
      victronDevice
          .device
          .connectionState
          .listen(
    (state) {
      debugPrint(
        'Connection state: $state',
      );

      if (state ==
          BluetoothConnectionState.connected) {
        connectedDevice.value =
            victronDevice;
      }

      if (state ==
          BluetoothConnectionState.disconnected) {
        if (connectedDevice
                .value
                ?.device
                .remoteId
                .str ==
            deviceId) {
          connectedDevice.value =
              null;
        }
      }
    },
  );

  await _activeAdapter!.connect();

  // Only remember it once setup actually succeeded.
  await _keyService.rememberDevice(
    deviceId,
  );

  connectedDevice.value =
      victronDevice;

  debugPrint(
    'Device remembered: '
    '${victronDevice.displayName}',
  );
}
  VictronAdapter _createAdapter(
    VictronDevice victronDevice,
  ) {
    switch (victronDevice.type) {
      case VictronDeviceType.blueSmartCharger:
        return LegacyGattAdapter(
          device: victronDevice.device,
          deviceType: victronDevice.type,
        );

      case VictronDeviceType.smartSolar:
      case VictronDeviceType.smartShunt:
      case VictronDeviceType.orionSmart:
      case VictronDeviceType.orionXs:
        throw UnsupportedError(
          'Instant Readout device does not '
          'require Legacy GATT adapter',
        );

      case VictronDeviceType.unknown:
        throw UnsupportedError(
          'Unknown Victron device type',
        );
    }
  }

  Future<void> disconnect() async {
    await _liveDataSubscription?.cancel();
    _liveDataSubscription = null;

    await _connectionSubscription?.cancel();
    _connectionSubscription = null;

    if (_activeAdapter != null) {
      await _activeAdapter!.dispose();
      _activeAdapter = null;
    }

    connectedDevice.value = null;
  }

  void clearLiveDevices() {
    liveDevices.value = {};
    liveData.value = VictronLiveData.empty();

    final DeviceEntityLinkService linkService =
        DeviceEntityLinkService.instance;

    final List<RustlerDevice> victronDevices =
        DeviceRegistryService.instance.devices.value.values
            .where(
              (device) =>
                  device.source == EntitySources.victron,
            )
            .toList();

    for (final RustlerDevice device in victronDevices) {
      linkService.setDeviceAvailability(
        device.id,
        false,
      );
    }
  }
}
