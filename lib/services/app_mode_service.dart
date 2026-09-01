import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum RustlerAppMode {
  standard,
  rangerHeadUnit,
}

class AppModeService {
  AppModeService._();

  static final AppModeService instance = AppModeService._();

  static const String _modeKey = 'rustler_gx_app_mode';

  final ValueNotifier<RustlerAppMode> mode = ValueNotifier<RustlerAppMode>(
    RustlerAppMode.standard,
  );

  bool _initialised = false;

  bool get isHeadUnit => mode.value == RustlerAppMode.rangerHeadUnit;

  bool get isStandard => mode.value == RustlerAppMode.standard;

  Future<void> initialise() async {
    if (_initialised) {
      return;
    }

    final SharedPreferences preferences = await SharedPreferences.getInstance();

    final String? savedMode = preferences.getString(_modeKey);

    switch (savedMode) {
      case 'ranger_head_unit':
        mode.value = RustlerAppMode.rangerHeadUnit;
        break;

      case 'standard':
      default:
        mode.value = RustlerAppMode.standard;
        break;
    }

    _initialised = true;
  }

  Future<bool> hasSavedMode() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();

    return preferences.containsKey(_modeKey);
  }

  Future<void> setStandardMode() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();

    await preferences.setString(
      _modeKey,
      'standard',
    );

    mode.value = RustlerAppMode.standard;
    _initialised = true;
  }

  Future<void> setRangerHeadUnitMode() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();

    await preferences.setString(
      _modeKey,
      'ranger_head_unit',
    );

    mode.value = RustlerAppMode.rangerHeadUnit;
    _initialised = true;
  }

  Future<void> reset() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();

    await preferences.remove(_modeKey);

    mode.value = RustlerAppMode.standard;
    _initialised = false;
  }
}
