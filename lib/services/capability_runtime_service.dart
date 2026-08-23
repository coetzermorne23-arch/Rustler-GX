// lib/services/capability_runtime_service.dart

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/rustler_gx_mode.dart';
import 'bluetooth_service.dart';
import 'hub_client_service.dart';
import 'hub_server_service.dart';
import 'rustler_gx_config_service.dart';

class CapabilityRuntimeService {
  CapabilityRuntimeService._();

  static final CapabilityRuntimeService instance =
      CapabilityRuntimeService._();

  final RustlerGxConfigService config =
      RustlerGxConfigService.instance;

  final VictronBluetoothService bluetooth =
      VictronBluetoothService.instance;

  final HubClientService hubClient =
      HubClientService.instance;

  final HubServerService hubServer =
      HubServerService.instance;

  bool _initialized = false;

  Set<RustlerGxCapability> _activeCapabilities =
      <RustlerGxCapability>{};

  Set<RustlerGxCapability> get activeCapabilities =>
      Set<RustlerGxCapability>.unmodifiable(
        _activeCapabilities,
      );

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _initialized = true;

    await applySavedCapabilities();
  }

  Future<void> applySavedCapabilities() async {
    final Set<RustlerGxCapability> capabilities =
        await config.getCapabilities();

    await applyCapabilities(
      capabilities,
    );
  }

  Future<void> applyCapabilities(
    Set<RustlerGxCapability> capabilities,
  ) async {
    final Set<RustlerGxCapability> previous =
        Set<RustlerGxCapability>.from(
      _activeCapabilities,
    );

    _activeCapabilities =
        Set<RustlerGxCapability>.from(
      capabilities,
    );

    await _applyLocalBluetooth(
      previous,
      capabilities,
    );

    await _applyHubServer(
      previous,
      capabilities,
    );

    await _applyHubClient(
      previous,
      capabilities,
    );

    debugPrint(
      'Rustler GX capabilities active: '
      '${capabilities.map((e) => e.name).join(', ')}',
    );
  }

  Future<void> _applyLocalBluetooth(
    Set<RustlerGxCapability> previous,
    Set<RustlerGxCapability> current,
  ) async {
    final bool wasEnabled =
        previous.contains(
      RustlerGxCapability.localBluetooth,
    );

    final bool isEnabled =
        current.contains(
      RustlerGxCapability.localBluetooth,
    );

    if (isEnabled && !wasEnabled) {
      try {
        await bluetooth.startScan();

        debugPrint(
          'Local Bluetooth enabled',
        );
      } catch (error) {
        debugPrint(
          'Could not start Bluetooth scan: $error',
        );
      }

      return;
    }

    if (!isEnabled && wasEnabled) {
      try {
        await bluetooth.stopScan();
      } catch (_) {}

      await bluetooth.disconnect();

      bluetooth.clearLiveDevices();

      debugPrint(
        'Local Bluetooth disabled',
      );
    }
  }

  Future<void> _applyHubServer(
    Set<RustlerGxCapability> previous,
    Set<RustlerGxCapability> current,
  ) async {
    final bool wasEnabled =
        previous.contains(
      RustlerGxCapability.hubServer,
    );

    final bool isEnabled =
        current.contains(
      RustlerGxCapability.hubServer,
    );

    if (isEnabled && !wasEnabled) {
      try {
        final int port =
            await config.getHubPort();

        await hubServer.start(
          port: port,
        );

        debugPrint(
          'Hub Server enabled on port $port',
        );
      } catch (error) {
        debugPrint(
          'Could not start Hub Server: $error',
        );
      }

      return;
    }

    if (!isEnabled && wasEnabled) {
      await hubServer.stop();

      debugPrint(
        'Hub Server disabled',
      );
    }
  }

  Future<void> _applyHubClient(
    Set<RustlerGxCapability> previous,
    Set<RustlerGxCapability> current,
  ) async {
    final bool wasEnabled =
        previous.contains(
      RustlerGxCapability.hubClient,
    );

    final bool isEnabled =
        current.contains(
      RustlerGxCapability.hubClient,
    );

    if (isEnabled && !wasEnabled) {
      try {
        await hubClient.connect();

        debugPrint(
          'Hub Client enabled',
        );
      } catch (error) {
        debugPrint(
          'Could not start Hub Client: $error',
        );
      }

      return;
    }

    if (!isEnabled && wasEnabled) {
      await hubClient.disconnect();

      debugPrint(
        'Hub Client disabled',
      );
    }
  }

  Future<void> refresh() async {
    await applySavedCapabilities();
  }

  bool hasCapability(
    RustlerGxCapability capability,
  ) {
    return _activeCapabilities.contains(
      capability,
    );
  }

  Future<void> shutdown() async {
    try {
      await bluetooth.stopScan();
    } catch (_) {}

    await bluetooth.disconnect();

    await hubClient.disconnect();

    await hubServer.stop();

    _activeCapabilities.clear();

    _initialized = false;

    debugPrint(
      'Rustler GX runtime stopped',
    );
  }
}