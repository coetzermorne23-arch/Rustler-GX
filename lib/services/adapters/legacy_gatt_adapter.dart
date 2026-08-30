import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../models/victron_live_data.dart';
import '../../models/victron_device_type.dart';

import 'victron_adapter.dart';

import '../decoders/device_decoder.dart';
import '../decoders/blue_smart_decoder.dart';
import '../decoders/smartsolar_decoder.dart';
import '../decoders/smartshunt_decoder.dart';
import '../decoders/orion_decoder.dart';

class LegacyGattAdapter implements VictronAdapter {
  LegacyGattAdapter({
    required this.device,
    required this.deviceType,
  }) {
    switch (deviceType) {
      case VictronDeviceType.blueSmartCharger:
        _decoder = BlueSmartDecoder();
        break;

      case VictronDeviceType.smartSolar:
        _decoder = SmartSolarDecoder();
        break;

      case VictronDeviceType.smartShunt:
        _decoder = SmartShuntDecoder();
        break;

      case VictronDeviceType.orionSmart:
      case VictronDeviceType.orionXs:
        _decoder = OrionDecoder();
        break;

      default:
        _decoder = BlueSmartDecoder();
    }
  }

  static const String _singleValueUuid = '306b0002-b081-4037-83dc-e59fcc3cdfd0';

  static const String _commandUuid = '306b0003-b081-4037-83dc-e59fcc3cdfd0';

  static const String _bulkValueUuid = '306b0004-b081-4037-83dc-e59fcc3cdfd0';

  final BluetoothDevice device;
  late final DeviceDecoder _decoder;

  final VictronDeviceType deviceType;

  final StreamController<VictronLiveData> _liveDataController =
      StreamController<VictronLiveData>.broadcast();

  final List<StreamSubscription<List<int>>> _subscriptions = [];

  final Map<String, BluetoothCharacteristic> _characteristics = {};

  final List<int> _protocolBuffer = [];

  Timer? _requestTimer;

  VictronLiveData _latestData = VictronLiveData.empty();

  @override
  Stream<VictronLiveData> get liveData => _liveDataController.stream;

  @override
  Future<void> connect() async {
    await device.connect(
      license: License.nonprofit,
      timeout: const Duration(seconds: 100),
    );

    final services = await device.discoverServices();

    for (final service in services) {
      for (final characteristic in service.characteristics) {
        final uuid = characteristic.uuid.str.toLowerCase();

        _characteristics[uuid] = characteristic;

        final canSubscribe = characteristic.properties.notify ||
            characteristic.properties.indicate;

        if (canSubscribe) {
          await _subscribe(characteristic);
        }

        if (characteristic.properties.read) {
          await _read(characteristic);
        }
      }
    }

    await Future<void>.delayed(const Duration(seconds: 1));

    await _sendInitSequence();

    await Future<void>.delayed(
      const Duration(milliseconds: 800),
    );

    await _requestLiveRegisters();

    _requestTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        unawaited(_requestLiveRegisters());
      },
    );

    debugPrint('Legacy register polling started');
  }

  Future<void> _subscribe(
    BluetoothCharacteristic characteristic,
  ) async {
    try {
      final uuid = characteristic.uuid.str.toLowerCase();

      final subscription = characteristic.onValueReceived.listen(
        (value) {
          _handlePacket(uuid, value);
        },
        onError: (Object error) {
          debugPrint('RX ERROR $uuid: $error');
        },
      );

      _subscriptions.add(subscription);

      await characteristic.setNotifyValue(true);

      debugPrint('SUBSCRIBED: $uuid');
    } catch (error) {
      debugPrint(
        'SUBSCRIBE FAILED ${characteristic.uuid}: $error',
      );
    }
  }

  Future<void> _read(
    BluetoothCharacteristic characteristic,
  ) async {
    try {
      final value = await characteristic.read();

      debugPrint(
        'READ ${characteristic.uuid}: ${_toHex(value)}',
      );
    } catch (error) {
      debugPrint(
        'READ FAILED ${characteristic.uuid}: $error',
      );
    }
  }

  Future<void> _sendInitSequence() async {
    debugPrint('Sending legacy Victron init sequence');

    await _write(
      _singleValueUuid,
      const [0xfa, 0x80, 0xff],
    );

    await Future<void>.delayed(
      const Duration(milliseconds: 500),
    );

    await _write(
      _singleValueUuid,
      const [0xf9, 0x80],
    );

    await Future<void>.delayed(
      const Duration(milliseconds: 500),
    );

    await _write(
      _commandUuid,
      const [0x01],
    );

    await Future<void>.delayed(
      const Duration(milliseconds: 500),
    );

    await _write(
      _commandUuid,
      const [0x03, 0x00],
    );

    debugPrint('Legacy Victron init sequence sent');
  }

  Future<void> _requestLiveRegisters() async {
    if (_characteristics[_bulkValueUuid] == null ||
        _characteristics[_singleValueUuid] == null) {
      debugPrint('Register request skipped: characteristics missing');
      return;
    }

    debugPrint(
      'Requesting ed8c current, ed8d voltage, '
      'ed8f temperature',
    );

    // Three read-only register requests:
    // ed8c = charge current
    // ed8d = battery voltage
    // ed8f = temperature/status-related value
    await _write(
      _bulkValueUuid,
      const [
        0x05,
        0x03,
        0x81,
        0x19,
        0xed,
        0x8c,
        0x05,
        0x03,
        0x81,
        0x19,
        0xed,
        0x8d,
        0x05,
        0x03,
        0x81,
        0x19,
        0xed,
        0x8f,
      ],
    );

    await Future<void>.delayed(
      const Duration(milliseconds: 200),
    );

    // Tell the single-value channel to return the requested values.
    await _write(
      _singleValueUuid,
      const [0xf9, 0x41],
    );

    await Future<void>.delayed(
      const Duration(milliseconds: 200),
    );

    // Keep the legacy notification session active.
    await _write(
      _commandUuid,
      const [0x03, 0x00],
    );
  }

  Future<void> _write(
    String uuid,
    List<int> bytes,
  ) async {
    final characteristic = _characteristics[uuid];

    if (characteristic == null) {
      debugPrint('TX SKIPPED: $uuid missing');
      return;
    }

    try {
      await characteristic.write(
        bytes,
        withoutResponse: true,
      );

      debugPrint(
        'TX SUCCESS $uuid: ${_toHex(bytes)}',
      );
    } catch (error) {
      debugPrint(
        'TX FAILED $uuid: $error',
      );
    }
  }

  void _handlePacket(
    String characteristicUuid,
    List<int> bytes,
  ) {
    debugPrint(
      'RX $characteristicUuid: ${_toHex(bytes)}',
    );

    if (characteristicUuid == _commandUuid ||
        characteristicUuid == _bulkValueUuid) {
      _protocolBuffer.addAll(bytes);
      _decodeProtocolBuffer();
    }
  }

  void _decodeProtocolBuffer() {
    while (true) {
      final start = _findRecordStart();

      if (start < 0) {
        if (_protocolBuffer.length > 5) {
          _protocolBuffer.removeRange(
            0,
            _protocolBuffer.length - 5,
          );
        }

        return;
      }

      if (start > 0) {
        _protocolBuffer.removeRange(0, start);
      }

      if (_protocolBuffer.length < 6) {
        return;
      }

      final valueType = _protocolBuffer[5];
      final valueLength = _valueLength(valueType);

      if (valueLength == null) {
        _protocolBuffer.removeAt(0);
        continue;
      }

      final recordLength = 6 + valueLength;

      if (_protocolBuffer.length < recordLength) {
        return;
      }

      final record = List<int>.from(
        _protocolBuffer.take(recordLength),
      );

      _protocolBuffer.removeRange(0, recordLength);

      _decodeRecord(record);
    }
  }

  int _findRecordStart() {
    for (int index = 0; index <= _protocolBuffer.length - 4; index++) {
      final first = _protocolBuffer[index];
      final third = _protocolBuffer[index + 2];

      if ((first == 0x08 || first == 0x09) && third == 0x19) {
        return index;
      }
    }

    return -1;
  }

  int? _valueLength(int valueType) {
    switch (valueType) {
      case 0x41:
        return 1;

      case 0x42:
        return 2;

      case 0x44:
        return 4;

      default:
        return null;
    }
  }

  void _decodeRecord(List<int> record) {
    final category = record[3];
    final register = record[4];
    final valueBytes = record.sublist(6);

    final registerId = '${category.toRadixString(16).padLeft(2, '0')}'
        '${register.toRadixString(16).padLeft(2, '0')}';

    final rawValue = _decodeLittleEndian(
      valueBytes,
      signed: _isSignedRegister(registerId),
    );

    _latestData = _decoder
        .decode(
          _latestData,
          registerId,
          rawValue,
        )
        .copyWith(
          updatedAt: DateTime.now(),
        );
    _publish();
  }

  int _decodeLittleEndian(
    List<int> bytes, {
    required bool signed,
  }) {
    int value = 0;

    for (int index = 0; index < bytes.length; index++) {
      value |= bytes[index] << (8 * index);
    }

    if (signed) {
      final bits = bytes.length * 8;
      final signBit = 1 << (bits - 1);

      if ((value & signBit) != 0) {
        value -= 1 << bits;
      }
    }

    return value;
  }

  bool _isSignedRegister(String registerId) {
    return registerId == 'ed8c' || registerId == 'ed8e';
  }

  void _publish() {
    _liveDataController.add(_latestData);
  }

  String _toHex(List<int> bytes) {
    return bytes
        .map(
          (byte) => byte.toRadixString(16).padLeft(2, '0'),
        )
        .join(' ');
  }

  @override
  Future<void> disconnect() async {
    _requestTimer?.cancel();
    _requestTimer = null;

    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }

    _subscriptions.clear();
    _characteristics.clear();
    _protocolBuffer.clear();

    await device.disconnect();
  }

  @override
  Future<void> dispose() async {
    _requestTimer?.cancel();
    _requestTimer = null;

    await disconnect();

    if (!_liveDataController.isClosed) {
      await _liveDataController.close();
    }
  }
}
