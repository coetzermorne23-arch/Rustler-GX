import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class InstallationIdentityService {
  InstallationIdentityService._();

  static final InstallationIdentityService instance =
      InstallationIdentityService._();

  final SharedPreferencesAsync _preferences =
      SharedPreferencesAsync();

  static const String _installationIdKey =
      'rustler_gx_installation_id';

  static const String _installationNameKey =
      'rustler_gx_installation_name';

  Future<String> getInstallationId() async {
    final String? existing =
        await _preferences.getString(
      _installationIdKey,
    );

    if (existing != null &&
        existing.isNotEmpty) {
      return existing;
    }

    final String generated =
        _generateId();

    await _preferences.setString(
      _installationIdKey,
      generated,
    );

    return generated;
  }

  Future<String> getInstallationName() async {
    return await _preferences.getString(
          _installationNameKey,
        ) ??
        'Rustler GX Hub';
  }

  Future<void> setInstallationName(
    String name,
  ) async {
    final String clean =
        name.trim();

    if (clean.isEmpty) {
      throw const FormatException(
        'Installation name cannot be empty.',
      );
    }

    await _preferences.setString(
      _installationNameKey,
      clean,
    );
  }

  String _generateId() {
    final Random random =
        Random.secure();

    final String randomPart =
        List<int>.generate(
      8,
      (_) => random.nextInt(256),
    ).map(
      (value) =>
          value
              .toRadixString(16)
              .padLeft(2, '0'),
    ).join();

    return 'rgx-$randomPart';
  }
}