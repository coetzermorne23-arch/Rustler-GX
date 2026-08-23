import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import '../../models/victron_device_type.dart';

class VictronInstantReadoutResult {
  final int modelId;
  final int readoutType;
  final Map<String, dynamic> values;

  const VictronInstantReadoutResult({
    required this.modelId,
    required this.readoutType,
    required this.values,
  });
}

class VictronInstantReadoutDecoder {
  const VictronInstantReadoutDecoder();

  VictronInstantReadoutResult decode({
    required List<int> manufacturerData,
    required String encryptionKey,
    required VictronDeviceType deviceType,
  }) {
    if (manufacturerData.length < 9) {
      throw const FormatException(
        'Victron manufacturer payload is too short.',
      );
    }

    final Uint8List data = Uint8List.fromList(
      manufacturerData,
    );

    final Uint8List key = _hexToBytes(encryptionKey);

    if (key.length != 16) {
      throw const FormatException(
        'Victron encryption key must be 16 bytes.',
      );
    }

    // manufacturerData is already the payload for Victron
    // company ID 0x02E1; flutter_blue_plus does not include
    // the company ID in this byte list.
    //
    // byte 0   = 0x10 Product Advertisement
    // byte 1-2 = model/product ID (little endian)
    // byte 3   = readout type
    // byte 4   = Instant Readout record type
    // byte 5-6 = AES nonce / data counter
    // byte 7   = first byte of advertisement key
    // byte 8+  = encrypted payload
    final int advertisementType = data[0];
    final int modelId = _uint16(data, 1);
    final int readoutType = data[3];
    final int recordType = data[4];
    final int iv = _uint16(data, 5);

    if (advertisementType != 0x10) {
      throw FormatException(
        'Unsupported Victron advertisement type: '
        '0x${advertisementType.toRadixString(16)}',
      );
    }

    final int keyCheckByte = data[7];

    if (keyCheckByte != key.first) {
      throw const FormatException(
        'Encryption key does not match this Victron device.',
      );
    }

    final Uint8List encrypted = Uint8List.fromList(
      data.sublist(8),
    );

    if (encrypted.isEmpty) {
      throw const FormatException(
        'Victron encrypted payload is empty.',
      );
    }

    final Uint8List decrypted = _decryptCtr(
      encrypted: encrypted,
      key: key,
      initialValue: iv,
    );

    final Map<String, dynamic> values;

    switch (deviceType) {
      case VictronDeviceType.smartShunt:
        values = _decodeBatteryMonitor(decrypted);
        break;

      case VictronDeviceType.smartSolar:
        values = _decodeSolarCharger(decrypted);
        break;

      case VictronDeviceType.orionSmart:
      case VictronDeviceType.orionXs:
        values = _decodeOrionRaw(decrypted);
        break;

      case VictronDeviceType.blueSmartCharger:
  values = _decodeAcCharger(
    decrypted,
  );
  break;

case VictronDeviceType.unknown:
  values = {
    'raw': _bytesToHex(decrypted),
  };
  break;
    }

    values['recordType'] = recordType;

    return VictronInstantReadoutResult(
      modelId: modelId,
      readoutType: readoutType,
      values: values,
    );
  }

  Map<String, dynamic> _decodeBatteryMonitor(
    Uint8List decrypted,
  ) {
    final _BitReader reader = _BitReader(decrypted);

    final int remainingMinutes =
        reader.readUnsigned(16);

    final int rawVoltage =
        reader.readSigned(16);

    final int alarm =
        reader.readUnsigned(16);

    final int rawAux =
        reader.readUnsigned(16);

    final int auxMode =
        reader.readUnsigned(2);

    final int rawCurrent =
        reader.readSigned(22);

    final int rawConsumedAh =
        reader.readUnsigned(20);

    final int rawSoc =
        reader.readUnsigned(10);

    final Map<String, dynamic> values = {
      'remainingMinutes':
          remainingMinutes == 0xffff
              ? null
              : remainingMinutes,
      'batteryVoltage':
          rawVoltage == 0x7fff
              ? null
              : rawVoltage / 100.0,
      'batteryCurrent':
          rawCurrent == 0x3fffff
              ? null
              : rawCurrent / 1000.0,
      'consumedAh':
          rawConsumedAh == 0xfffff
              ? null
              : -(rawConsumedAh / 10.0),
      'stateOfCharge':
          rawSoc == 0x3ff
              ? null
              : rawSoc / 10.0,
      'alarmCode': alarm,
      'auxMode': auxMode,
    };

    final double? voltage =
        values['batteryVoltage'] as double?;

    final double? current =
        values['batteryCurrent'] as double?;

    values['batteryPower'] =
        voltage != null && current != null
            ? voltage * current
            : null;

    switch (auxMode) {
      case 0:
        values['starterVoltage'] =
            _signedValue(rawAux, 16) / 100.0;
        break;

      case 1:
        values['midpointVoltage'] =
            rawAux / 100.0;
        break;

      case 2:
        values['temperature'] =
            (rawAux / 100.0) - 273.15;
        break;
    }

    return values;
  }

  Map<String, dynamic> _decodeSolarCharger(
    Uint8List decrypted,
  ) {
    final _BitReader reader = _BitReader(decrypted);

    final int chargeState =
        reader.readUnsigned(8);

    final int chargerError =
        reader.readUnsigned(8);

    final int rawBatteryVoltage =
        reader.readSigned(16);

    final int rawChargeCurrent =
        reader.readSigned(16);

    final int rawYieldToday =
        reader.readUnsigned(16);

    final int rawSolarPower =
        reader.readUnsigned(16);

    final int rawLoadCurrent =
        reader.readUnsigned(9);

    return {
      'chargeStateCode':
          chargeState == 0xff ? null : chargeState,
      'chargeState':
          chargeState == 0xff
              ? null
              : _chargeStateLabel(chargeState),
      'chargerError':
          chargerError == 0xff
              ? null
              : chargerError,
      'batteryVoltage':
          rawBatteryVoltage == 0x7fff
              ? null
              : rawBatteryVoltage / 100.0,
      'chargeCurrent':
          rawChargeCurrent == 0x7fff
              ? null
              : rawChargeCurrent / 10.0,
      'yieldTodayWh':
          rawYieldToday == 0xffff
              ? null
              : rawYieldToday * 10,
      'solarPower':
          rawSolarPower == 0xffff
              ? null
              : rawSolarPower,
      'loadCurrent':
          rawLoadCurrent == 0x1ff
              ? null
              : rawLoadCurrent / 10.0,
    };
  }
 Map<String, dynamic> _decodeAcCharger(
  Uint8List decrypted,
) {
  final Map<String, dynamic> values = {
    'raw': _bytesToHex(decrypted),
  };

  if (decrypted.length < 13) {
    return values;
  }

  try {
    final reader = _BitReader(decrypted);

    // =====================================================
    // Victron Instant Readout - AC Charger (0x08)
    // =====================================================

    final int deviceState =
        reader.readUnsigned(8);

    final int chargerError =
        reader.readUnsigned(8);

    final int rawVoltage1 =
        reader.readUnsigned(13);

    final int rawCurrent1 =
        reader.readUnsigned(11);

    final int rawVoltage2 =
        reader.readUnsigned(13);

    final int rawCurrent2 =
        reader.readUnsigned(11);

    final int rawVoltage3 =
        reader.readUnsigned(13);

    final int rawCurrent3 =
        reader.readUnsigned(11);

    final int rawTemperature =
        reader.readUnsigned(7);

    final int rawAcCurrent =
        reader.readUnsigned(9);

    // -----------------------------------------------------
    // DEVICE STATE
    // -----------------------------------------------------

    values['chargeStateCode'] =
        deviceState == 0xff
            ? null
            : deviceState;

    values['chargeState'] =
        deviceState == 0xff
            ? null
            : _chargeStateLabel(deviceState);

    // -----------------------------------------------------
    // CHARGER ERROR
    // -----------------------------------------------------

    values['chargerError'] =
        chargerError == 0xff
            ? null
            : chargerError;

    // -----------------------------------------------------
    // OUTPUT 1
    // -----------------------------------------------------

    final double? voltage1 =
        rawVoltage1 == 0x1fff
            ? null
            : rawVoltage1 / 100.0;

    final double? current1 =
        rawCurrent1 == 0x7ff
            ? null
            : rawCurrent1 / 10.0;

    values['outputVoltage1'] = voltage1;
    values['outputCurrent1'] = current1;

    // Rustler GX generic charger fields.
    values['batteryVoltage'] = voltage1;
    values['chargeCurrent'] = current1;

    if (voltage1 != null &&
        current1 != null) {
      values['power'] =
          voltage1 * current1;
    }

    // -----------------------------------------------------
    // OUTPUT 2
    // -----------------------------------------------------

    values['outputVoltage2'] =
        rawVoltage2 == 0x1fff
            ? null
            : rawVoltage2 / 100.0;

    values['outputCurrent2'] =
        rawCurrent2 == 0x7ff
            ? null
            : rawCurrent2 / 10.0;

    // -----------------------------------------------------
    // OUTPUT 3
    // -----------------------------------------------------

    values['outputVoltage3'] =
        rawVoltage3 == 0x1fff
            ? null
            : rawVoltage3 / 100.0;

    values['outputCurrent3'] =
        rawCurrent3 == 0x7ff
            ? null
            : rawCurrent3 / 10.0;

    // -----------------------------------------------------
    // TEMPERATURE
    // Victron encoding: raw - 40°C
    // -----------------------------------------------------

    values['temperature'] =
        rawTemperature == 0x7f
            ? null
            : rawTemperature - 40.0;

    // -----------------------------------------------------
    // AC INPUT CURRENT
    // -----------------------------------------------------

    values['acCurrent'] =
        rawAcCurrent == 0x1ff
            ? null
            : rawAcCurrent / 10.0;
  } on FormatException {
    // Preserve raw packet for debugging.
  }

  return values;
}
  Map<String, dynamic> _decodeOrionRaw(
    Uint8List decrypted,
  ) {
    return {
      'raw': _bytesToHex(decrypted),
      'status':
          'Orion payload detected; decoder mapping pending',
    };
  }

  Uint8List _decryptCtr({
    required Uint8List encrypted,
    required Uint8List key,
    required int initialValue,
  }) {
    final AESEngine aes = AESEngine()
      ..init(
        true,
        KeyParameter(key),
      );

    final Uint8List output =
        Uint8List(encrypted.length);

    final Uint8List counter =
        Uint8List(16);

    counter[0] = initialValue & 0xff;
    counter[1] = (initialValue >> 8) & 0xff;

    int offset = 0;

    while (offset < encrypted.length) {
      final Uint8List streamBlock =
          Uint8List(16);

      aes.processBlock(
        counter,
        0,
        streamBlock,
        0,
      );

      final int blockLength =
          encrypted.length - offset > 16
              ? 16
              : encrypted.length - offset;

      for (int index = 0;
          index < blockLength;
          index++) {
        output[offset + index] =
            encrypted[offset + index] ^
                streamBlock[index];
      }

      _incrementLittleEndian(counter);
      offset += blockLength;
    }

    return output;
  }

  void _incrementLittleEndian(
    Uint8List counter,
  ) {
    for (int index = 0;
        index < counter.length;
        index++) {
      counter[index] =
          (counter[index] + 1) & 0xff;

      if (counter[index] != 0) {
        break;
      }
    }
  }

  int _uint16(
    Uint8List data,
    int offset,
  ) {
    return data[offset] |
        (data[offset + 1] << 8);
  }

  int _signedValue(
    int value,
    int bits,
  ) {
    final int signBit = 1 << (bits - 1);

    if ((value & signBit) != 0) {
      return value - (1 << bits);
    }

    return value;
  }

  Uint8List _hexToBytes(String value) {
    final String clean = value
        .replaceAll(' ', '')
        .replaceAll(':', '')
        .trim()
        .toLowerCase();

    if (!RegExp(r'^[0-9a-f]{32}$')
        .hasMatch(clean)) {
      throw const FormatException(
        'Encryption key must contain '
        'exactly 32 hexadecimal characters.',
      );
    }

    return Uint8List.fromList(
      List<int>.generate(
        clean.length ~/ 2,
        (index) => int.parse(
          clean.substring(
            index * 2,
            index * 2 + 2,
          ),
          radix: 16,
        ),
      ),
    );
  }

  String _bytesToHex(List<int> bytes) {
    return bytes
        .map(
          (byte) =>
              byte.toRadixString(16).padLeft(2, '0'),
        )
        .join(' ');
  }

  String _chargeStateLabel(int code) {
    switch (code) {
      case 0:
        return 'Off';
      case 1:
        return 'Low power';
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
        return 'Power supply';
      case 245:
        return 'Starting up';
      case 246:
        return 'Repeated absorption';
      case 247:
        return 'Recondition';
      case 248:
        return 'Battery safe';
      case 249:
        return 'Active';
      case 252:
        return 'External control';
      default:
        return 'Unknown ($code)';
    }
  }
}

class _BitReader {
  final Uint8List data;
int get remainingBits =>
    (data.length * 8) - _bitIndex;
  int _bitIndex = 0;

  _BitReader(this.data);

  int readUnsigned(int bitCount) {
    if (_bitIndex + bitCount >
        data.length * 8) {
      throw const FormatException(
        'Instant Readout payload ended unexpectedly.',
      );
    }

    int value = 0;

    for (int position = 0;
        position < bitCount;
        position++) {
      final int byteIndex =
          _bitIndex >> 3;

      final int bitInByte =
          _bitIndex & 7;

      final int bit =
          (data[byteIndex] >> bitInByte) & 1;

      value |= bit << position;
      _bitIndex++;
    }

    return value;
  }

  int readSigned(int bitCount) {
    final int value =
        readUnsigned(bitCount);

    final int signBit =
        1 << (bitCount - 1);

    if ((value & signBit) != 0) {
      return value - (1 << bitCount);
    }

    return value;
  }
}