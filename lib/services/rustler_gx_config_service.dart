import 'package:shared_preferences/shared_preferences.dart';

import '../models/rustler_gx_mode.dart';

class RustlerGxConfigService {
  RustlerGxConfigService._();

  static final RustlerGxConfigService instance = RustlerGxConfigService._();

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  static const String _capabilitiesKey = 'rustler_gx_capabilities';

  static const String _hubHostKey = 'rustler_gx_hub_host';

  static const String _hubPortKey = 'rustler_gx_hub_port';

  static const String defaultHubHost = 'rustlergx.local';

  static const int defaultHubPort = 8765;

  static const Set<RustlerGxCapability> defaultCapabilities = {
    RustlerGxCapability.localBluetooth,
    RustlerGxCapability.dashboard,
  };

  Future<Set<RustlerGxCapability>> getCapabilities() async {
    final List<String>? stored = await _preferences.getStringList(
      _capabilitiesKey,
    );

    if (stored == null || stored.isEmpty) {
      return Set<RustlerGxCapability>.from(
        defaultCapabilities,
      );
    }

    final Set<RustlerGxCapability> result = <RustlerGxCapability>{};

    for (final String name in stored) {
      for (final capability in RustlerGxCapability.values) {
        if (capability.name == name) {
          result.add(capability);
          break;
        }
      }
    }

    if (result.isEmpty) {
      return Set<RustlerGxCapability>.from(
        defaultCapabilities,
      );
    }

    return result;
  }

  Future<void> setCapabilities(
    Set<RustlerGxCapability> capabilities,
  ) async {
    await _preferences.setStringList(
      _capabilitiesKey,
      capabilities
          .map(
            (capability) => capability.name,
          )
          .toList(),
    );
  }

  Future<bool> hasCapability(
    RustlerGxCapability capability,
  ) async {
    final capabilities = await getCapabilities();

    return capabilities.contains(
      capability,
    );
  }

  Future<void> enableCapability(
    RustlerGxCapability capability,
  ) async {
    final capabilities = await getCapabilities();

    capabilities.add(
      capability,
    );

    await setCapabilities(
      capabilities,
    );
  }

  Future<void> disableCapability(
    RustlerGxCapability capability,
  ) async {
    final capabilities = await getCapabilities();

    capabilities.remove(
      capability,
    );

    await setCapabilities(
      capabilities,
    );
  }

  Future<String> getHubHost() async {
    return await _preferences.getString(
          _hubHostKey,
        ) ??
        defaultHubHost;
  }

  Future<void> setHubHost(
    String host,
  ) async {
    final String clean = host.trim();

    if (clean.isEmpty) {
      throw const FormatException(
        'Hub address cannot be empty.',
      );
    }

    await _preferences.setString(
      _hubHostKey,
      clean,
    );
  }

  Future<int> getHubPort() async {
    return await _preferences.getInt(
          _hubPortKey,
        ) ??
        defaultHubPort;
  }

  Future<void> setHubPort(
    int port,
  ) async {
    if (port < 1 || port > 65535) {
      throw const FormatException(
        'Hub port must be between 1 and 65535.',
      );
    }

    await _preferences.setInt(
      _hubPortKey,
      port,
    );
  }

  Future<Uri> getHubHttpUri() async {
    final String host = await getHubHost();

    final int port = await getHubPort();

    return Uri(
      scheme: 'http',
      host: host,
      port: port,
    );
  }

  Future<Uri> getHubWebSocketUri() async {
    final String host = await getHubHost();

    final int port = await getHubPort();

    return Uri(
      scheme: 'ws',
      host: host,
      port: port,
      path: '/ws',
    );
  }
}
