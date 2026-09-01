import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum RustlerDeviceProfile {
  standard,
  rangerHeadUnit,
}

class DeviceProfileService {
  DeviceProfileService._();

  static final DeviceProfileService instance = DeviceProfileService._();

  static const String _modeKey = 'rustler_gx_app_mode';
  static const String _standardValue = 'standard';
  static const String _rangerValue = 'ranger_head_unit';

  final ValueNotifier<RustlerDeviceProfile> profile =
      ValueNotifier<RustlerDeviceProfile>(
    RustlerDeviceProfile.standard,
  );

  bool _initialised = false;

  bool get initialised => _initialised;

  bool get isHeadUnit => profile.value == RustlerDeviceProfile.rangerHeadUnit;

  bool get isStandard => profile.value == RustlerDeviceProfile.standard;

  Future<void> initialise() async {
    if (_initialised) {
      return;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final String? saved = prefs.getString(_modeKey);

    profile.value = saved == _rangerValue
        ? RustlerDeviceProfile.rangerHeadUnit
        : RustlerDeviceProfile.standard;

    _initialised = true;
  }

  Future<bool> hasSavedProfile() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.containsKey(_modeKey);
  }

  Future<void> setStandard() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _modeKey,
      _standardValue,
    );

    profile.value = RustlerDeviceProfile.standard;

    _initialised = true;
  }

  Future<void> setRangerHeadUnit() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _modeKey,
      _rangerValue,
    );

    profile.value = RustlerDeviceProfile.rangerHeadUnit;

    _initialised = true;
  }

  Future<void> reset() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.remove(_modeKey);

    profile.value = RustlerDeviceProfile.standard;

    _initialised = true;
  }
}
