import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/obd_adapter_device.dart';
import 'vehicle_data_service.dart';

class ObdService {
  ObdService._();

  static final ObdService instance = ObdService._();

  static const MethodChannel _channel = MethodChannel('rustler_gx/obd');
  static const String _adapterKey = 'ranger_gx_obd_adapter_address';

  final VehicleDataService vehicle = VehicleDataService.instance;

  final ValueNotifier<bool> connecting = ValueNotifier<bool>(false);
  final ValueNotifier<bool> connected = ValueNotifier<bool>(false);
  final ValueNotifier<String?> adapterAddress = ValueNotifier<String?>(null);
  final ValueNotifier<String?> adapterName = ValueNotifier<String?>(null);
  final ValueNotifier<String?> error = ValueNotifier<String?>(null);
  final ValueNotifier<Set<int>> supportedPids =
      ValueNotifier<Set<int>>(<int>{});
  final ValueNotifier<Map<String, String>> rawResponses =
      ValueNotifier<Map<String, String>>(<String, String>{});

  Timer? _pollTimer;
  Timer? _reconnectTimer;
  bool _polling = false;
  bool _preferencesLoaded = false;
  double? _barometricPressureKpa;

  Future<void> start() async {
    if (!_preferencesLoaded) {
      _preferencesLoaded = true;
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      adapterAddress.value = prefs.getString(_adapterKey);
    }

    _reconnectTimer ??= Timer.periodic(const Duration(seconds: 12), (_) {
      final String? saved = adapterAddress.value;
      if (!connected.value &&
          !connecting.value &&
          saved != null &&
          saved.isNotEmpty) {
        unawaited(connect(saved));
      }
    });

    final String? savedAddress = adapterAddress.value;
    if (!connected.value &&
        !connecting.value &&
        savedAddress != null &&
        savedAddress.isNotEmpty) {
      unawaited(connect(savedAddress));
    }
  }

  Future<List<ObdAdapterDevice>> bondedDevices() async {
    try {
      final List<dynamic>? values =
          await _channel.invokeMethod<List<dynamic>>('bondedDevices');
      return (values ?? <dynamic>[])
          .whereType<Map<dynamic, dynamic>>()
          .map(ObdAdapterDevice.fromMap)
          .where((ObdAdapterDevice item) => item.address.isNotEmpty)
          .toList(growable: false);
    } on MissingPluginException {
      return <ObdAdapterDevice>[];
    }
  }

  Future<bool> connect(String address) async {
    if (connecting.value) {
      return false;
    }

    connecting.value = true;
    error.value = null;

    try {
      final Map<dynamic, dynamic>? result =
          await _channel.invokeMapMethod<dynamic, dynamic>(
        'connect',
        <String, dynamic>{'address': address},
      );

      final bool ok = result?['connected'] == true;
      if (!ok) {
        throw StateError(
            (result?['error'] as String?) ?? 'OBD connection failed');
      }

      connected.value = true;
      vehicle.setConnected(true);
      adapterAddress.value = address;
      adapterName.value = result?['name'] as String?;

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_adapterKey, address);

      await _discoverSupportedPids();
      await _pollOnce();
      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(
        const Duration(milliseconds: 900),
        (_) => unawaited(_pollOnce()),
      );
      return true;
    } catch (exception) {
      error.value = exception.toString();
      connected.value = false;
      vehicle.setConnected(false);
      return false;
    } finally {
      connecting.value = false;
    }
  }

  Future<void> disconnect() async {
    _pollTimer?.cancel();
    _pollTimer = null;
    try {
      await _channel.invokeMethod<void>('disconnect');
    } catch (_) {}
    connected.value = false;
    vehicle.setConnected(false);
  }

  Future<void> forgetAdapter() async {
    await disconnect();
    adapterAddress.value = null;
    adapterName.value = null;
    supportedPids.value = <int>{};
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_adapterKey);
  }

  Future<void> _discoverSupportedPids() async {
    final Set<int> found = <int>{};
    for (final int base in <int>[0x00, 0x20, 0x40, 0x60]) {
      final String response = await _query(
        '01${base.toRadixString(16).padLeft(2, '0').toUpperCase()}',
      );
      final List<int> bytes = _hexBytes(response);
      final int index = _findModePid(bytes, 0x41, base);
      if (index < 0 || bytes.length < index + 6) {
        if (base == 0) {
          continue;
        }
        break;
      }
      final int bits = (bytes[index + 2] << 24) |
          (bytes[index + 3] << 16) |
          (bytes[index + 4] << 8) |
          bytes[index + 5];
      for (int bit = 0; bit < 32; bit++) {
        if ((bits & (1 << (31 - bit))) != 0) {
          found.add(base + bit + 1);
        }
      }
      if (!found.contains(base + 0x20)) {
        break;
      }
    }
    supportedPids.value = found;
  }

  Future<void> _pollOnce() async {
    if (_polling || !connected.value) {
      return;
    }
    _polling = true;

    try {
      double? rpm;
      double? speed;
      double? coolant;
      double? intake;
      double? voltage;
      double? map;
      double? load;
      double? throttle;
      double? maf;
      double? fuelRate;

      if (_supports(0x0C)) rpm = await _pid010C();
      if (_supports(0x0D)) speed = await _singleBytePid(0x0D);
      if (_supports(0x05)) {
        final double? value = await _singleBytePid(0x05);
        coolant = value == null ? null : value - 40;
      }
      if (_supports(0x0F)) {
        final double? value = await _singleBytePid(0x0F);
        intake = value == null ? null : value - 40;
      }
      if (_supports(0x0B)) map = await _singleBytePid(0x0B);
      if (_supports(0x04)) {
        final double? value = await _singleBytePid(0x04);
        load = value == null ? null : value * 100 / 255;
      }
      if (_supports(0x11)) {
        final double? value = await _singleBytePid(0x11);
        throttle = value == null ? null : value * 100 / 255;
      }
      if (_supports(0x10)) maf = await _pid0110();
      if (_supports(0x5E)) fuelRate = await _pid015E();
      if (_supports(0x33)) {
        _barometricPressureKpa = await _singleBytePid(0x33);
      }
      voltage = await _adapterVoltage();

      final double? boost = map == null
          ? null
          : (map - (_barometricPressureKpa ?? 101.325)) / 100.0;

      vehicle.publish(
        rpm: rpm,
        vehicleSpeedKmh: speed,
        coolantTemperatureC: coolant,
        intakeTemperatureC: intake,
        batteryVoltage: voltage,
        boostBar: boost,
        manifoldAbsolutePressureKpa: map,
        engineLoadPercent: load,
        throttlePercent: throttle,
        massAirFlowGps: maf,
        fuelRateLitresPerHour: fuelRate ?? _estimateDieselFuelRate(maf),
      );
    } catch (exception) {
      error.value = 'OBD polling: $exception';
      final bool stillConnected = await _nativeConnected();
      if (!stillConnected) {
        connected.value = false;
        vehicle.setConnected(false);
        _pollTimer?.cancel();
        _pollTimer = null;
      }
    } finally {
      _polling = false;
    }
  }

  bool _supports(int pid) {
    final Set<int> values = supportedPids.value;
    return values.isEmpty || values.contains(pid);
  }

  Future<bool> _nativeConnected() async {
    try {
      return await _channel.invokeMethod<bool>('isConnected') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<String> _query(String command) async {
    final String response =
        await _channel.invokeMethod<String>('query', <String, dynamic>{
              'command': command,
            }) ??
            '';
    final Map<String, String> updated =
        Map<String, String>.from(rawResponses.value);
    updated[command] = response;
    rawResponses.value = updated;
    return response;
  }

  Future<double?> _singleBytePid(int pid) async {
    final String code = pid.toRadixString(16).padLeft(2, '0').toUpperCase();
    final List<int> bytes = _hexBytes(await _query('01$code'));
    final int index = _findModePid(bytes, 0x41, pid);
    return index >= 0 && bytes.length > index + 2
        ? bytes[index + 2].toDouble()
        : null;
  }

  Future<double?> _pid010C() async {
    final List<int> bytes = _hexBytes(await _query('010C'));
    final int index = _findModePid(bytes, 0x41, 0x0C);
    if (index < 0 || bytes.length <= index + 3) return null;
    return ((bytes[index + 2] << 8) + bytes[index + 3]) / 4.0;
  }

  Future<double?> _pid0110() async {
    final List<int> bytes = _hexBytes(await _query('0110'));
    final int index = _findModePid(bytes, 0x41, 0x10);
    if (index < 0 || bytes.length <= index + 3) return null;
    return ((bytes[index + 2] << 8) + bytes[index + 3]) / 100.0;
  }

  Future<double?> _pid015E() async {
    final List<int> bytes = _hexBytes(await _query('015E'));
    final int index = _findModePid(bytes, 0x41, 0x5E);
    if (index < 0 || bytes.length <= index + 3) return null;
    return ((bytes[index + 2] << 8) + bytes[index + 3]) / 20.0;
  }

  Future<double?> _adapterVoltage() async {
    final String response = await _query('ATRV');
    final RegExpMatch? match =
        RegExp(r'([0-9]+(?:\.[0-9]+)?)\s*V?', caseSensitive: false)
            .firstMatch(response);
    return match == null ? null : double.tryParse(match.group(1)!);
  }

  double? _estimateDieselFuelRate(double? mafGps) {
    if (mafGps == null || mafGps <= 0) return null;
    // Approximation only. Diesel AFR varies heavily with load; this keeps
    // estimated trip fuel usable until the ECU exposes PID 0x5E.
    const double assumedAfr = 18.0;
    const double dieselDensityGramsPerLitre = 832.0;
    return mafGps / assumedAfr / dieselDensityGramsPerLitre * 3600.0;
  }

  List<int> _hexBytes(String raw) {
    final String cleaned = raw
        .toUpperCase()
        .replaceAll(RegExp(r'[^0-9A-F]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty) return <int>[];
    final List<String> tokens = cleaned.split(' ');
    final List<int> bytes = <int>[];
    for (final String token in tokens) {
      if (token.length == 2) {
        final int? value = int.tryParse(token, radix: 16);
        if (value != null) bytes.add(value);
      } else if (token.length.isEven && token.length >= 4) {
        for (int i = 0; i < token.length; i += 2) {
          final int? value = int.tryParse(token.substring(i, i + 2), radix: 16);
          if (value != null) bytes.add(value);
        }
      }
    }
    return bytes;
  }

  int _findModePid(List<int> bytes, int mode, int pid) {
    for (int i = 0; i + 1 < bytes.length; i++) {
      if (bytes[i] == mode && bytes[i + 1] == pid) return i;
    }
    return -1;
  }
}
