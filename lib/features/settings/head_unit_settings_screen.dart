import 'package:flutter/material.dart';

import '../../models/head_unit_platform_state.dart';
import '../../services/head_unit_platform_service.dart';

class HeadUnitSettingsScreen extends StatelessWidget {
  const HeadUnitSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final HeadUnitPlatformService platform = HeadUnitPlatformService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('RigOS Head Unit')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: platform.defaultHome,
            builder: (context, enabled, child) => ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Dedicated head-unit launcher'),
              subtitle: Text(enabled
                  ? 'RigOS is the Android HOME app.'
                  : 'Set RigOS as HOME for reliable boot/wake return.'),
              trailing: enabled
                  ? const Icon(Icons.check_circle)
                  : FilledButton(
                      onPressed: platform.requestHomeRole,
                      child: const Text('SET HOME'),
                    ),
            ),
          ),
          const Divider(),
          ValueListenableBuilder<List<HeadUnitStorageVolume>>(
            valueListenable: platform.storageVolumes,
            builder: (context, volumes, child) {
              final removable = volumes.where((v) => v.removable).toList();
              return Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.usb),
                    title: Text('USB media storage'),
                    subtitle: Text(
                        'YouTube Music remains default; USB is detected automatically.'),
                  ),
                  for (final volume in removable)
                    ListTile(
                      dense: true,
                      leading: Icon(volume.state == 'mounted'
                          ? Icons.usb_rounded
                          : Icons.usb_off),
                      title: Text(volume.description),
                      subtitle: Text('${volume.state}  ${volume.path}'),
                    ),
                ],
              );
            },
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Steering-wheel control'),
            subtitle: Text(
              'RigOS captures Android media key events when the head-unit firmware delivers them. '
              'If the radio firmware launches its stock BT Music app before Android delivers the key, '
              'that firmware mapping must be disabled in the radio factory/SWC settings.',
            ),
          ),
        ],
      ),
    );
  }
}
