import 'package:flutter/material.dart';

import '../models/rustler_gx_mode.dart';
import '../services/runtime_capability_controller.dart';

class DeviceCapabilitiesScreen extends StatefulWidget {
  const DeviceCapabilitiesScreen({
    super.key,
  });

  @override
  State<DeviceCapabilitiesScreen> createState() =>
      _DeviceCapabilitiesScreenState();
}

class _DeviceCapabilitiesScreenState extends State<DeviceCapabilitiesScreen> {
  final RuntimeCapabilityController controller =
      RuntimeCapabilityController.instance;

  Set<RustlerGxCapability> capabilities = <RustlerGxCapability>{};

  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();

    _load();
  }

  Future<void> _load() async {
    final loaded = await controller.getCapabilities();

    if (!mounted) {
      return;
    }

    setState(() {
      capabilities = Set<RustlerGxCapability>.from(
        loaded,
      );

      loading = false;
    });
  }

  Future<void> _change(
    RustlerGxCapability capability,
    bool enabled,
  ) async {
    if (saving) {
      return;
    }

    final previous = Set<RustlerGxCapability>.from(
      capabilities,
    );

    final updated = Set<RustlerGxCapability>.from(
      capabilities,
    );

    if (enabled) {
      updated.add(capability);
    } else {
      updated.remove(capability);
    }

    setState(() {
      capabilities = updated;
      saving = true;
    });

    try {
      await controller.setCapabilities(
        updated,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        capabilities = previous;
      });

      _message(
        'Could not apply setting: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  Future<void> _preset(
    Set<RustlerGxCapability> preset,
  ) async {
    if (saving) {
      return;
    }

    final previous = Set<RustlerGxCapability>.from(
      capabilities,
    );

    setState(() {
      capabilities = Set<RustlerGxCapability>.from(
        preset,
      );

      saving = true;
    });

    try {
      await controller.setCapabilities(
        preset,
      );

      _message(
        'Device preset applied.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        capabilities = previous;
      });

      _message(
        'Could not apply preset: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  void _message(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  bool _enabled(
    RustlerGxCapability capability,
  ) {
    return capabilities.contains(
      capability,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Device Capabilities',
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Device Capabilities',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Device Presets',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Choose a preset or configure '
            'each capability manually.',
            style: TextStyle(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 18),
          _PresetTile(
            icon: Icons.directions_car,
            title: 'Head Unit',
            subtitle: 'Bluetooth + Dashboard + GPS + Media',
            onTap: saving
                ? null
                : () => _preset(
                      {
                        RustlerGxCapability.localBluetooth,
                        RustlerGxCapability.dashboard,
                        RustlerGxCapability.gps,
                        RustlerGxCapability.media,
                      },
                    ),
          ),
          _PresetTile(
            icon: Icons.tablet_android,
            title: 'Monitoring Tablet',
            subtitle: 'Bluetooth + Dashboard + Hub Client',
            onTap: saving
                ? null
                : () => _preset(
                      {
                        RustlerGxCapability.localBluetooth,
                        RustlerGxCapability.dashboard,
                        RustlerGxCapability.hubClient,
                      },
                    ),
          ),
          _PresetTile(
            icon: Icons.hub,
            title: 'Hub',
            subtitle: 'Bluetooth + Hub Server',
            onTap: saving
                ? null
                : () => _preset(
                      {
                        RustlerGxCapability.localBluetooth,
                        RustlerGxCapability.hubServer,
                      },
                    ),
          ),
          const SizedBox(height: 22),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Manual Configuration',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _CapabilityTile(
            icon: Icons.bluetooth,
            title: 'Local Bluetooth',
            subtitle: 'Scan and connect to nearby devices.',
            value: _enabled(
              RustlerGxCapability.localBluetooth,
            ),
            onChanged: saving
                ? null
                : (value) => _change(
                      RustlerGxCapability.localBluetooth,
                      value,
                    ),
          ),
          _CapabilityTile(
            icon: Icons.cloud_download_outlined,
            title: 'Hub Client',
            subtitle: 'Receive data from another Rustler GX Hub.',
            value: _enabled(
              RustlerGxCapability.hubClient,
            ),
            onChanged: saving
                ? null
                : (value) => _change(
                      RustlerGxCapability.hubClient,
                      value,
                    ),
          ),
          _CapabilityTile(
            icon: Icons.hub,
            title: 'Hub Server',
            subtitle: 'Share this device entities over the local network.',
            value: _enabled(
              RustlerGxCapability.hubServer,
            ),
            onChanged: saving
                ? null
                : (value) => _change(
                      RustlerGxCapability.hubServer,
                      value,
                    ),
          ),
          _CapabilityTile(
            icon: Icons.dashboard,
            title: 'Dashboard',
            subtitle: 'Enable the local dashboard.',
            value: _enabled(
              RustlerGxCapability.dashboard,
            ),
            onChanged: saving
                ? null
                : (value) => _change(
                      RustlerGxCapability.dashboard,
                      value,
                    ),
          ),
          _CapabilityTile(
            icon: Icons.gps_fixed,
            title: 'GPS',
            subtitle: 'Use built-in GPS and location hardware.',
            value: _enabled(
              RustlerGxCapability.gps,
            ),
            onChanged: saving
                ? null
                : (value) => _change(
                      RustlerGxCapability.gps,
                      value,
                    ),
          ),
          _CapabilityTile(
            icon: Icons.music_note,
            title: 'Media',
            subtitle: 'Enable head-unit media features.',
            value: _enabled(
              RustlerGxCapability.media,
            ),
            onChanged: saving
                ? null
                : (value) => _change(
                      RustlerGxCapability.media,
                      value,
                    ),
          ),
          _CapabilityTile(
            icon: Icons.public,
            title: 'Remote Access',
            subtitle: 'Enable optional internet remote monitoring.',
            value: _enabled(
              RustlerGxCapability.remoteAccess,
            ),
            onChanged: saving
                ? null
                : (value) => _change(
                      RustlerGxCapability.remoteAccess,
                      value,
                    ),
          ),
          if (saving) ...[
            const SizedBox(
              height: 16,
            ),
            const Center(
              child: CircularProgressIndicator(),
            ),
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _PresetTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _PresetTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          size: 30,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
        ),
        trailing: const Icon(
          Icons.chevron_right,
        ),
        onTap: onTap,
      ),
    );
  }
}

class _CapabilityTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _CapabilityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      child: SwitchListTile(
        secondary: Icon(
          icon,
          size: 28,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
