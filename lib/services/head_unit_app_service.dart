import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class HeadUnitAppInfo {
  final String packageName;
  final String label;
  final bool system;
  const HeadUnitAppInfo(
      {required this.packageName, required this.label, required this.system});
  factory HeadUnitAppInfo.fromMap(Map<dynamic, dynamic> m) => HeadUnitAppInfo(
        packageName: '${m['packageName'] ?? ''}',
        label: '${m['label'] ?? m['packageName'] ?? ''}',
        system: m['system'] == true,
      );
}

class HeadUnitAppService {
  HeadUnitAppService._();
  static final HeadUnitAppService instance = HeadUnitAppService._();
  static const _channel = MethodChannel('rustler_gx/head_unit');
  final ValueNotifier<List<HeadUnitAppInfo>> apps = ValueNotifier(const []);
  final ValueNotifier<String?> error = ValueNotifier(null);

  Future<void> refresh() async {
    try {
      final raw =
          await _channel.invokeListMethod<dynamic>('launcherApps') ?? const [];
      final list = raw
          .whereType<Map<dynamic, dynamic>>()
          .map(HeadUnitAppInfo.fromMap)
          .toList()
        ..sort(
            (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
      apps.value = list;
      error.value = null;
    } catch (e) {
      error.value = '$e';
    }
  }

  Future<void> openDetails(String packageName) async {
    await _channel.invokeMethod(
        'openAppDetails', <String, dynamic>{'packageName': packageName});
  }
}
