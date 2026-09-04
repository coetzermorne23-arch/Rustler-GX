import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GpsDisplaySettings extends ChangeNotifier {
  GpsDisplaySettings._();
  static final GpsDisplaySettings instance = GpsDisplaySettings._();

  static const _orderKey = 'ranger_gx_gps_order';
  static const _enabledPrefix = 'ranger_gx_gps_enabled_';

  final List<String> order = <String>[
    'speed',
    'heading',
    'altitude',
    'accuracy',
    'coordinates',
    'satellites',
    'usedSatellites',
    'gps',
    'galileo',
    'glonass',
    'beidou',
    'bestSignal',
    'timestamp',
  ];

  final Map<String, bool> _enabled = <String, bool>{
    'speed': true,
    'heading': true,
    'altitude': true,
    'accuracy': true,
    'coordinates': true,
    'satellites': true,
    'usedSatellites': true,
    'gps': true,
    'galileo': true,
    'glonass': true,
    'beidou': true,
    'bestSignal': true,
    'timestamp': false,
  };

  bool _loaded = false;
  bool get loaded => _loaded;
  bool enabled(String key) => _enabled[key] ?? false;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final savedOrder = prefs.getStringList(_orderKey);
    if (savedOrder != null && savedOrder.isNotEmpty) {
      final known = order.toSet();
      final valid = savedOrder.where(known.contains).toList();
      for (final key in order) {
        if (!valid.contains(key)) valid.add(key);
      }
      order
        ..clear()
        ..addAll(valid);
    }
    for (final key in _enabled.keys.toList()) {
      _enabled[key] = prefs.getBool('$_enabledPrefix$key') ?? _enabled[key]!;
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setEnabled(String key, bool value) async {
    _enabled[key] = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_enabledPrefix$key', value);
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final item = order.removeAt(oldIndex);
    order.insert(newIndex, item);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_orderKey, order);
  }
}
