import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/rig_profile.dart';

class RigProfileService {
  RigProfileService._();
  static final RigProfileService instance = RigProfileService._();
  static const _key = 'rigos_profile_type';
  final ValueNotifier<RigProfileType> type =
      ValueNotifier(RigProfileType.vehicle);
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final p = await SharedPreferences.getInstance();
    final saved = p.getString(_key);
    type.value = RigProfileType.values.firstWhere(
      (e) => e.name == saved,
      orElse: () => RigProfileType.vehicle,
    );
    _loaded = true;
  }

  Future<void> setType(RigProfileType value) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, value.name);
    type.value = value;
    _loaded = true;
  }
}
