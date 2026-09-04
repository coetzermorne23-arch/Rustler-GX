import 'package:flutter/material.dart';

import '../../models/victron_device.dart';
import '../../services/bluetooth_service.dart';
import '../../services/victron_key_service.dart';
import '../../services/device_profile_service.dart';
import '../../services/head_unit_runtime_service.dart';
import '../../services/head_unit_service.dart';
import '../../services/media_session_service.dart';
import '../dashboard/dashboard_screen.dart';
import '../driving/head_unit_home_screen.dart';
import 'head_unit_settings_screen.dart';
import 'rigos_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final VictronBluetoothService bluetooth = VictronBluetoothService.instance;

  final VictronKeyService keyService = VictronKeyService.instance;

  final DeviceProfileService profile = DeviceProfileService.instance;

  final HeadUnitRuntimeService runtime = HeadUnitRuntimeService.instance;

  final HeadUnitService headUnit = HeadUnitService.instance;

  final MediaSessionService media = MediaSessionService.instance;

  @override
  void initState() {
    super.initState();

    profile.initialise();
    media.checkAccess();
  }

  Future<void> _switchToRanger() async {
    await profile.setRangerHeadUnit();
    await runtime.start();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const HeadUnitHomeScreen(),
      ),
      (_) => false,
    );
  }

  Future<void> _switchToStandard() async {
    await profile.setStandard();
    await runtime.leaveHeadUnitMode();
    await headUnit.normalSystemUi();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const DashboardScreen(),
      ),
      (_) => false,
    );
  }

  Future<void> _openNotificationAccess() async {
    await media.openAccessSettings();
  }

  Future<void> _editKey(
    VictronDevice device,
  ) async {
    final deviceId = device.device.remoteId.str;

    final existingKey = await keyService.getKey(deviceId);

    if (!mounted) return;

    final changed = await showDialog<bool>(
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
    return StreamBuilder<List<VictronDevice>>(
      stream: bluetooth.devices,
      builder: (context, snapshot) {
        final devices = snapshot.data ?? const [];

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
            const SizedBox(height: 18),
            Card(
              child: ListTile(
                leading: const Icon(Icons.tune_rounded),
                title: const Text('RigOS main settings'),
                subtitle: const Text(
                    'Identity, profiles, pairing, energy flow, GPS, OBD, SRNE and head-unit settings.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const RigOsSettingsScreen()),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<RustlerDeviceProfile>(
              valueListenable: profile.profile,
              builder: (context, activeProfile, child) {
                final bool ranger =
                    activeProfile == RustlerDeviceProfile.rangerHeadUnit;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Device profile',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ranger
                              ? 'RANGER_GX head unit mode is active.'
                              : 'Standard RigOS mode is active.',
                          style: const TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            FilledButton.icon(
                              onPressed: ranger ? null : _switchToRanger,
                              icon: const Icon(
                                Icons.directions_car_filled,
                              ),
                              label: const Text(
                                'USE RANGER_GX',
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: ranger ? _switchToStandard : null,
                              icon: const Icon(
                                Icons.phone_android,
                              ),
                              label: const Text(
                                'USE STANDARD',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.settings_input_component),
                title: const Text('RigOS head-unit platform'),
                subtitle: const Text(
                  'Launcher, boot/wake, USB, steering controls and call bridge.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const HeadUnitSettingsScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Head unit media access',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'RigOS needs Android notification access '
                      'to read and control YouTube Music playback.',
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ValueListenableBuilder<bool>(
                      valueListenable: media.notificationAccess,
                      builder: (context, access, child) {
                        return Row(
                          children: [
                            Icon(
                              access
                                  ? Icons.check_circle
                                  : Icons.warning_amber_rounded,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                access
                                    ? 'Media access ready'
                                    : 'Media access not enabled',
                              ),
                            ),
                            OutlinedButton(
                              onPressed: _openNotificationAccess,
                              child: Text(
                                access ? 'OPEN SETTINGS' : 'ENABLE',
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Victron encryption keys',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Keys are stored locally on this device.',
              style: TextStyle(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            if (devices.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'Scan for Victron devices first. '
                    'Detected devices will appear here.',
                  ),
                ),
              )
            else
              ...devices.map(
                (device) => _DeviceKeyCard(
                  device: device,
                  keyService: keyService,
                  onEditKey: () => _editKey(device),
                ),
              ),
          ],
        );
      },
    );
  }
}

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
    final deviceId = device.device.remoteId.str;

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
              builder: (context, snapshot) {
                final hasKey = snapshot.data ?? false;

                return Row(
                  children: [
                    Icon(
                      hasKey ? Icons.key : Icons.key_off,
                    ),
                    const SizedBox(width: 8),
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
    final value =
        controller.text.replaceAll(' ', '').replaceAll(':', '').trim();

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

      if (!mounted) return;

      Navigator.pop(
        context,
        true,
      );
    } catch (error) {
      if (!mounted) return;

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

    if (!mounted) return;

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
