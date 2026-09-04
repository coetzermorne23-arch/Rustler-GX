import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum HeadUnitPackageClass { safeToDisable, vendorKeep, unknown }

class HeadUnitAppInfo {
  final String packageName;
  final String label;
  final bool system;
  final bool enabled;
  final bool homeCandidate;

  const HeadUnitAppInfo({
    required this.packageName,
    required this.label,
    required this.system,
    required this.enabled,
    required this.homeCandidate,
  });

  factory HeadUnitAppInfo.fromMap(Map<dynamic, dynamic> m) => HeadUnitAppInfo(
        packageName: '${m['packageName'] ?? ''}',
        label: '${m['label'] ?? m['packageName'] ?? ''}',
        system: m['system'] == true,
        enabled: m['enabled'] != false,
        homeCandidate: m['homeCandidate'] == true,
      );

  HeadUnitPackageClass get classification {
    final text = '$packageName $label'.toLowerCase();

    const protected = <String>[
      'rigos',
      'rustler_gx',
      'android',
      'systemui',
      'settings',
      'bluetooth',
      'bt',
      'mcu',
      'canbus',
      'can.',
      'steering',
      'swc',
      'radio',
      'tuner',
      'fm',
      'audio',
      'dsp',
      'usb',
      'gps',
      'gnss',
      'location',
      'launcher3',
      'packageinstaller',
      'permissioncontroller',
      'inputmethod',
      'keyboard',
      'webview',
      'media.provider',
    ];
    if (protected.any(text.contains)) return HeadUnitPackageClass.vendorKeep;

    const bloat = <String>[
      'video',
      'gallery',
      'browser',
      'chrome',
      'filemanager',
      'file manager',
      'explorer',
      'music',
      'photo',
      'wallpaper',
      'weather',
      'calculator',
      'calendar',
      'email',
      'clock',
      'youtube',
    ];
    if (bloat.any(text.contains)) return HeadUnitPackageClass.safeToDisable;

    return HeadUnitPackageClass.unknown;
  }

  String get classLabel => switch (classification) {
        HeadUnitPackageClass.safeToDisable => 'SAFE TO DISABLE',
        HeadUnitPackageClass.vendorKeep => 'VENDOR / HARDWARE — KEEP',
        HeadUnitPackageClass.unknown => 'UNKNOWN',
      };
}

class HeadUnitAppService {
  HeadUnitAppService._();
  static final HeadUnitAppService instance = HeadUnitAppService._();
  static const _channel = MethodChannel('rustler_gx/head_unit');
  static const _disabledKey = 'rigos_disabled_packages';

  final ValueNotifier<List<HeadUnitAppInfo>> apps = ValueNotifier(const []);
  final ValueNotifier<Set<String>> disabledByRigOs = ValueNotifier(<String>{});
  final ValueNotifier<bool> rootAvailable = ValueNotifier(false);
  final ValueNotifier<String?> error = ValueNotifier(null);

  Future<void> refresh() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      disabledByRigOs.value =
          (prefs.getStringList(_disabledKey) ?? const <String>[]).toSet();

      rootAvailable.value =
          await _channel.invokeMethod<bool>('rootAvailable') ?? false;

      final raw =
          await _channel.invokeListMethod<dynamic>('installedApps') ?? const [];
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

  Future<void> openDetails(String packageName) =>
      _channel.invokeMethod('openAppDetails', {'packageName': packageName});

  Future<String> disable(HeadUnitAppInfo app) async {
    if (app.classification == HeadUnitPackageClass.vendorKeep) {
      return 'Blocked by RigOS protection list.';
    }
    try {
      final result = await _channel.invokeMethod<String>(
            'disablePackage',
            {'packageName': app.packageName},
          ) ??
          'No result';
      if (result.startsWith('OK')) {
        final next = {...disabledByRigOs.value, app.packageName};
        disabledByRigOs.value = next;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(_disabledKey, next.toList()..sort());
      }
      await refresh();
      return result;
    } catch (e) {
      return '$e';
    }
  }

  Future<String> enable(String packageName) async {
    try {
      final result = await _channel.invokeMethod<String>(
            'enablePackage',
            {'packageName': packageName},
          ) ??
          'No result';
      if (result.startsWith('OK')) {
        final next = {...disabledByRigOs.value}..remove(packageName);
        disabledByRigOs.value = next;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(_disabledKey, next.toList()..sort());
      }
      await refresh();
      return result;
    } catch (e) {
      return '$e';
    }
  }

  Future<List<String>> disableSafeBloat() async {
    final results = <String>[];
    for (final app in apps.value.where(
      (a) => a.classification == HeadUnitPackageClass.safeToDisable,
    )) {
      results.add('${app.label}: ${await disable(app)}');
    }
    return results;
  }

  Future<void> restoreAll() async {
    for (final packageName in disabledByRigOs.value.toList()) {
      await enable(packageName);
    }
  }

  Future<String> disableOtherHomeApps() async {
    final candidates = apps.value.where(
      (a) =>
          a.homeCandidate &&
          !a.packageName.contains('rustler_gx') &&
          a.classification != HeadUnitPackageClass.vendorKeep,
    );
    if (candidates.isEmpty) return 'No unprotected stock HOME candidate found.';
    final results = <String>[];
    for (final app in candidates) {
      results.add('${app.label}: ${await disable(app)}');
    }
    return results.join('\n');
  }
}
