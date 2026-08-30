import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'victron_device_type.dart';

class VictronDevice {
  final BluetoothDevice device;

  final String platformName;
  final String advertisedName;

  final int rssi;

  final VictronDeviceType type;

  final bool hasInstantReadout;

  final List<int> manufacturerData;

  /// Victron product/model ID extracted from the
  /// Instant Readout manufacturer advertisement.
  final int? modelId;

  /// Victron Instant Readout record type.
  ///
  /// Examples:
  /// 0x01 = Solar Charger
  /// 0x02 = Battery Monitor
  /// 0x04 = DC/DC Converter
  /// 0x08 = AC Charger
  final int? recordType;

  const VictronDevice({
    required this.device,
    required this.platformName,
    required this.advertisedName,
    required this.rssi,
    required this.type,
    required this.hasInstantReadout,
    required this.manufacturerData,
    this.modelId,
    this.recordType,
  });

  String get displayName {
    if (advertisedName.isNotEmpty) {
      return advertisedName;
    }

    if (platformName.isNotEmpty) {
      return platformName;
    }

    return 'Unknown BLE device';
  }

  String get manufacturerDataHex {
    if (manufacturerData.isEmpty) {
      return 'None';
    }

    return manufacturerData
        .map(
          (byte) => byte.toRadixString(16).padLeft(2, '0'),
        )
        .join(' ');
  }

  String get modelIdHex {
    if (modelId == null) {
      return 'Unknown';
    }

    return '0x${modelId!.toRadixString(16).padLeft(4, '0')}';
  }

  String get recordTypeHex {
    if (recordType == null) {
      return 'Unknown';
    }

    return '0x${recordType!.toRadixString(16).padLeft(2, '0')}';
  }
}
