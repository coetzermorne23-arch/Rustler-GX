import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/history_record.dart';
import '../models/victron_live_data.dart';

class HistoryService {
  HistoryService._();

  static final HistoryService instance =
      HistoryService._();

  static const String _storageKey =
      'rustler_gx_history_v1';

  static const Duration sampleInterval =
      Duration(minutes: 1);

  static const int maxRecords = 10000;

  final ValueNotifier<List<HistoryRecord>> records =
      ValueNotifier<List<HistoryRecord>>([]);

  final Map<String, DateTime> _lastSample = {};

  bool _loaded = false;

  Future<void> initialize() async {
    if (_loaded) {
      return;
    }

    final prefs =
        await SharedPreferences.getInstance();

    final stored =
        prefs.getString(_storageKey);

    if (stored == null || stored.isEmpty) {
      _loaded = true;
      return;
    }

    try {
      final decoded = jsonDecode(stored);

      if (decoded is! List) {
        _loaded = true;
        return;
      }

      final loadedRecords = decoded
          .whereType<Map>()
          .map(
            (item) => HistoryRecord.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();

      loadedRecords.sort(
        (a, b) => b.timestamp.compareTo(
          a.timestamp,
        ),
      );

      records.value = loadedRecords;

      _loaded = true;

      debugPrint(
        'History loaded: '
        '${loadedRecords.length} records',
      );
    } catch (error) {
      debugPrint(
        'History load failed: $error',
      );

      _loaded = true;
    }
  }

  Future<void> record(
    VictronLiveData data,
  ) async {
    if (!_loaded) {
      await initialize();
    }

    if (data.serial.isEmpty) {
      return;
    }

    if (!_hasUsefulData(data)) {
      return;
    }

    final now = DateTime.now();

    final previous =
        _lastSample[data.serial];

    if (previous != null &&
        now.difference(previous) <
            sampleInterval) {
      return;
    }

    _lastSample[data.serial] = now;

    final record = HistoryRecord(
      deviceId: data.serial,
      deviceName: data.name,
      timestamp: now,

      batteryVoltage:
          data.batteryVoltage,

      batteryCurrent:
          data.batteryCurrent,

      batteryPower:
          data.power,

      stateOfCharge:
          data.stateOfCharge,

      pvVoltage:
          data.pvVoltage,

      pvCurrent:
          data.pvCurrent,

      pvPower:
          data.pvPower,

      chargeCurrent:
          data.chargeCurrent,

      chargeState:
          data.chargeState,

      inputVoltage:
          data.inputVoltage,

      outputVoltage:
          data.outputVoltage,

      outputCurrent:
          data.outputCurrent,

      outputPower:
          data.outputPower,
    );

    final updated =
        List<HistoryRecord>.from(
      records.value,
    );

    updated.insert(
      0,
      record,
    );

    if (updated.length > maxRecords) {
      updated.removeRange(
        maxRecords,
        updated.length,
      );
    }

    records.value = updated;

    await _save();

    debugPrint(
      'History sample: '
      '${data.name} '
      '${record.timestamp}',
    );
  }

  bool _hasUsefulData(
    VictronLiveData data,
  ) {
    return data.batteryVoltage != null ||
        data.batteryCurrent != null ||
        data.power != null ||
        data.stateOfCharge != null ||
        data.pvVoltage != null ||
        data.pvCurrent != null ||
        data.pvPower != null ||
        data.chargeCurrent != null ||
        data.inputVoltage != null ||
        data.outputVoltage != null ||
        data.outputCurrent != null ||
        data.outputPower != null;
  }

  Future<void> _save() async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      final encoded = jsonEncode(
        records.value
            .map(
              (record) =>
                  record.toJson(),
            )
            .toList(),
      );

      await prefs.setString(
        _storageKey,
        encoded,
      );
    } catch (error) {
      debugPrint(
        'History save failed: $error',
      );
    }
  }

  List<HistoryRecord> forDevice(
    String deviceId,
  ) {
    return records.value
        .where(
          (record) =>
              record.deviceId ==
              deviceId,
        )
        .toList();
  }

  List<HistoryRecord> since(
    DateTime time,
  ) {
    return records.value
        .where(
          (record) =>
              record.timestamp
                  .isAfter(time),
        )
        .toList();
  }

  Future<void> clear() async {
    records.value = [];
    _lastSample.clear();

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(
      _storageKey,
    );

    debugPrint(
      'History cleared',
    );
  }
}