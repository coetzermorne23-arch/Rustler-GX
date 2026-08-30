import 'package:flutter/material.dart';

import '../../models/victron_device.dart';
import '../../services/bluetooth_service.dart';
import '../../services/victron_key_service.dart';
import '../device_capabilities_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Settings',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          'Configure Rustler GX integrations, '
          'dashboard and device features.',
          style: TextStyle(
            color: Colors.white70,
          ),
        ),

        const SizedBox(height: 24),

        // ===================================================
        // CONNECTIONS
        // ===================================================

        const _SectionTitle(
          title: 'Connections',
        ),

        _SettingsTile(
          icon: Icons.bluetooth,
          title: 'Bluetooth & Victron',
          subtitle: 'Bluetooth devices, Victron setup and encryption keys',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const VictronSettingsScreen(),
              ),
            );
          },
        ),

        _SettingsTile(
          icon: Icons.extension,
          title: 'Device Capabilities',
          subtitle: 'Bluetooth, Hub, GPS, media and dashboard capabilities',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const DeviceCapabilitiesScreen(),
              ),
            );
          },
        ),

        const SizedBox(height: 22),

        // ===================================================
        // DASHBOARD
        // ===================================================

        const _SectionTitle(
          title: 'Dashboard',
        ),

        const _SettingsTile(
          icon: Icons.dashboard_customize,
          title: 'Dashboard & Pages',
          subtitle: 'Widgets, dashboard pages and layouts',
        ),

        const SizedBox(height: 22),

        // ===================================================
        // HEAD UNIT
        // ===================================================

        const _SectionTitle(
          title: 'Head Unit',
        ),

        const _SettingsTile(
          icon: Icons.navigation,
          title: 'GPS & Navigation',
          subtitle: 'GPS source, navigation and driving features',
        ),

        const _SettingsTile(
          icon: Icons.music_note,
          title: 'Media',
          subtitle: 'Music apps and dashboard media controls',
        ),

        const SizedBox(height: 22),

        // ===================================================
        // SYSTEM
        // ===================================================

        const _SectionTitle(
          title: 'System',
        ),

        const _SettingsTile(
          icon: Icons.extension,
          title: 'Device Capabilities',
          subtitle: 'Bluetooth, Hub, GPS, media and dashboard capabilities',
        ),

        const _SettingsTile(
          icon: Icons.cloud_outlined,
          title: 'Remote Access',
          subtitle: 'Optional internet-based remote monitoring',
        ),

        const _SettingsTile(
          icon: Icons.info_outline,
          title: 'About Rustler GX',
          subtitle: 'Version and system information',
        ),

        const SizedBox(height: 30),
      ],
    );
  }
}

// ===========================================================
// SETTINGS SECTION TITLE
// ===========================================================

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 8,
      ),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

// ===========================================================
// SETTINGS TILE
// ===========================================================

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
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
          size: 28,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(
            top: 3,
          ),
          child: Text(
            subtitle,
          ),
        ),
        trailing: onTap == null
            ? const Icon(
                Icons.lock_clock,
                size: 20,
              )
            : const Icon(
                Icons.chevron_right,
              ),
        onTap: onTap,
      ),
    );
  }
}

// ===========================================================
// VICTRON SETTINGS
// ===========================================================

class VictronSettingsScreen extends StatefulWidget {
  const VictronSettingsScreen({
    super.key,
  });

  @override
  State<VictronSettingsScreen> createState() => _VictronSettingsScreenState();
}

class _VictronSettingsScreenState extends State<VictronSettingsScreen> {
  final VictronBluetoothService bluetooth = VictronBluetoothService.instance;

  final VictronKeyService keyService = VictronKeyService.instance;

  Future<void> _editKey(
    VictronDevice device,
  ) async {
    final String deviceId = device.device.remoteId.str;

    final String? existingKey = await keyService.getKey(
      deviceId,
    );

    if (!mounted) {
      return;
    }

    final bool? changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _KeyDialog(
          device: device,
          existingKey: existingKey,
        );
      },
    );

    if (changed == true && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bluetooth & Victron',
        ),
      ),
      body: StreamBuilder<List<VictronDevice>>(
        stream: bluetooth.devices,
        builder: (
          context,
          snapshot,
        ) {
          final List<VictronDevice> devices =
              snapshot.data ?? const <VictronDevice>[];

          return ListView(
            padding: const EdgeInsets.all(
              16,
            ),
            children: [
              const Text(
                'Victron Devices',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Manage Victron Instant Readout '
                'encryption keys stored on this device.',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 18),
              if (devices.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Column(
                      children: [
                        Icon(
                          Icons.bluetooth_searching,
                          size: 38,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No Victron devices detected.',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Scan for BT devices first. '
                          'Detected Victron devices '
                          'will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...devices.map(
                  (device) => _DeviceKeyCard(
                    device: device,
                    keyService: keyService,
                    onEditKey: () => _editKey(
                      device,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ===========================================================
// DEVICE KEY CARD
// ===========================================================

class _DeviceKeyCard extends StatelessWidget {
  final VictronDevice device;

  final VictronKeyService keyService;

  final VoidCallback onEditKey;

  const _DeviceKeyCard({
    required this.device,
    required this.keyService,
    required this.onEditKey,
  });

  @override
  Widget build(BuildContext context) {
    final String deviceId = device.device.remoteId.str;

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Padding(
        padding: const EdgeInsets.all(
          16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              device.displayName,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              deviceId,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<bool>(
              future: keyService.hasKey(
                deviceId,
              ),
              builder: (
                context,
                snapshot,
              ) {
                final bool hasKey = snapshot.data ?? false;

                return Row(
                  children: [
                    Icon(
                      hasKey ? Icons.key : Icons.key_off,
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Expanded(
                      child: Text(
                        hasKey ? 'Encryption key saved' : 'No encryption key',
                      ),
                    ),
                    FilledButton(
                      onPressed: onEditKey,
                      child: Text(
                        hasKey ? 'EDIT KEY' : 'ADD KEY',
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================
// KEY DIALOG
// ===========================================================

class _KeyDialog extends StatefulWidget {
  final VictronDevice device;

  final String? existingKey;

  const _KeyDialog({
    required this.device,
    required this.existingKey,
  });

  @override
  State<_KeyDialog> createState() => _KeyDialogState();
}

class _KeyDialogState extends State<_KeyDialog> {
  final VictronKeyService keyService = VictronKeyService.instance;

  late final TextEditingController controller;

  bool obscure = true;

  bool saving = false;

  @override
  void initState() {
    super.initState();

    controller = TextEditingController(
      text: widget.existingKey ?? '',
    );
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  Future<void> _save() async {
    final String value = controller.text
        .replaceAll(
          ' ',
          '',
        )
        .replaceAll(
          ':',
          '',
        )
        .trim();

    if (!RegExp(
      r'^[0-9a-fA-F]{32}$',
    ).hasMatch(value)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Key must be exactly '
            '32 hexadecimal characters.',
          ),
        ),
      );

      return;
    }

    setState(() {
      saving = true;
    });

    try {
      await keyService.saveKey(
        deviceId: widget.device.device.remoteId.str,
        encryptionKey: value,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
        true,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString(),
          ),
        ),
      );
    }
  }

  Future<void> _remove() async {
    setState(() {
      saving = true;
    });

    await keyService.removeKey(
      widget.device.device.remoteId.str,
    );

    if (!mounted) {
      return;
    }

    Navigator.pop(
      context,
      true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.device.displayName,
      ),
      content: SizedBox(
        width: 420,
        child: TextField(
          controller: controller,
          obscureText: obscure,
          maxLength: 32,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: 'Encryption key',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              onPressed: saving
                  ? null
                  : () {
                      setState(() {
                        obscure = !obscure;
                      });
                    },
              icon: Icon(
                obscure ? Icons.visibility : Icons.visibility_off,
              ),
            ),
          ),
        ),
      ),
      actions: [
        if (widget.existingKey != null)
          TextButton(
            onPressed: saving ? null : _remove,
            child: const Text(
              'REMOVE',
            ),
          ),
        TextButton(
          onPressed: saving
              ? null
              : () {
                  Navigator.pop(
                    context,
                    false,
                  );
                },
          child: const Text(
            'CANCEL',
          ),
        ),
        FilledButton(
          onPressed: saving ? null : _save,
          child: saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'SAVE',
                ),
        ),
      ],
    );
  }
}
