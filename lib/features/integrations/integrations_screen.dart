import 'package:flutter/material.dart';

import '../../models/entity_sources.dart';
import '../../models/local_http_device.dart';
import '../../models/rustler_device.dart';
import '../../services/device_registry_service.dart';
import '../../services/integrations/esp_http_service.dart';
import '../../services/integrations/integration_manager_service.dart';
import '../../services/integrations/local_device_config_service.dart';
import '../../services/integrations/sonoff_diy_service.dart';
import '../../services/integrations/tuya_bridge_service.dart';

class IntegrationsScreen extends StatefulWidget {
  const IntegrationsScreen({super.key});

  @override
  State<IntegrationsScreen> createState() => _IntegrationsScreenState();
}

class _IntegrationsScreenState extends State<IntegrationsScreen> {
  final IntegrationManagerService manager = IntegrationManagerService.instance;
  final LocalDeviceConfigService configs = LocalDeviceConfigService.instance;
  final DeviceRegistryService registry = DeviceRegistryService.instance;

  bool refreshing = false;

  @override
  void initState() {
    super.initState();
    manager.start();
  }

  Future<void> _addOrEdit([LocalHttpDevice? existing]) async {
    final LocalHttpDevice? device = await showDialog<LocalHttpDevice>(
      context: context,
      builder: (_) => _LocalDeviceDialog(existing: existing),
    );
    if (device == null) return;
    await configs.upsert(device);
    await manager.restart();
  }

  Future<void> _remove(LocalHttpDevice device) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove device?'),
        content: Text('Remove ${device.name} from RigOS?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('REMOVE'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await configs.remove(device.id);
    await manager.restart();
  }

  Future<void> _test(LocalHttpDevice device) async {
    try {
      switch (device.kind) {
        case LocalHttpDeviceKind.sonoffDiy:
          await SonoffDiyService.instance.readSwitch(device);
          break;
        case LocalHttpDeviceKind.espJson:
        case LocalHttpDeviceKind.customJson:
          await EspHttpService.instance.poll(device);
          break;
        case LocalHttpDeviceKind.tuyaBridge:
          await TuyaBridgeService.instance.poll(device);
          break;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${device.name}: connected')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${device.name}: $error')),
      );
    }
  }

  Future<void> _refresh() async {
    if (refreshing) return;
    setState(() => refreshing = true);
    try {
      await manager.refreshAll();
    } finally {
      if (mounted) setState(() => refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RigOS Integrations'),
        actions: [
          IconButton(
            onPressed: refreshing ? null : _refresh,
            icon: refreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Refresh all',
          ),
          IconButton(
            onPressed: _addOrEdit,
            icon: const Icon(Icons.add),
            tooltip: 'Add local device',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: manager.running,
            builder: (context, running, child) =>
                _RuntimeCard(running: running),
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'Victron BLE',
            subtitle: 'SmartShunt, SmartSolar, Blue Smart and Orion live data',
            child: ValueListenableBuilder<Map<String, RustlerDevice>>(
              valueListenable: registry.devices,
              builder: (context, devices, child) {
                final List<RustlerDevice> values = devices.values
                    .where((device) => device.source == EntitySources.victron)
                    .toList()
                  ..sort((a, b) => a.name.compareTo(b.name));
                return _RegisteredSummary(
                  emptyText:
                      'No Victron live data yet. Scan/connect from Devices.',
                  devices: values,
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'Local network devices',
            subtitle: 'ESP/ESP32 JSON, SONOFF DIY and local Tuya bridge',
            child: ValueListenableBuilder<List<LocalHttpDevice>>(
              valueListenable: configs.devices,
              builder: (context, devices, child) {
                if (devices.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.lan_outlined, size: 48),
                        const SizedBox(height: 10),
                        const Text(
                          'No local devices configured yet.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _addOrEdit,
                          icon: const Icon(Icons.add_link),
                          label: const Text('ADD LOCAL DEVICE'),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: devices
                      .map(
                        (device) => _LocalDeviceTile(
                          device: device,
                          onEdit: () => _addOrEdit(device),
                          onTest: () => _test(device),
                          onDelete: () => _remove(device),
                          onEnabled: (value) async {
                            await configs
                                .upsert(device.copyWith(enabled: value));
                            await manager.restart();
                          },
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'Universal registry',
            subtitle: 'Everything published into the common RigOS device model',
            child: ValueListenableBuilder<Map<String, RustlerDevice>>(
              valueListenable: registry.devices,
              builder: (context, devices, child) {
                final List<RustlerDevice> values = devices.values.toList()
                  ..sort((a, b) => a.name.compareTo(b.name));
                return _RegisteredSummary(
                  emptyText: 'No universal devices registered yet.',
                  devices: values,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addOrEdit,
        icon: const Icon(Icons.add_link),
        label: const Text('ADD DEVICE'),
      ),
    );
  }
}

class _RuntimeCard extends StatelessWidget {
  final bool running;

  const _RuntimeCard({required this.running});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(running ? Icons.hub : Icons.hub_outlined, size: 36),
        title: const Text('Integration runtime'),
        subtitle: Text(running ? 'Running' : 'Stopped'),
        trailing: Icon(
          Icons.circle,
          size: 12,
          color: running ? Colors.greenAccent : Colors.white38,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _Section({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ),
          child,
        ],
      ),
    );
  }
}

class _LocalDeviceTile extends StatelessWidget {
  final LocalHttpDevice device;
  final VoidCallback onEdit;
  final VoidCallback onTest;
  final VoidCallback onDelete;
  final ValueChanged<bool> onEnabled;

  const _LocalDeviceTile({
    required this.device,
    required this.onEdit,
    required this.onTest,
    required this.onDelete,
    required this.onEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(_iconForKind(device.kind), size: 34),
      title: Text(device.name),
      subtitle: Text(
        '${device.displayEndpoint} • ${_labelForKind(device.kind)}\n'
        '${device.statusPath} • ${device.pollInterval.inSeconds}s poll',
      ),
      isThreeLine: true,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(value: device.enabled, onChanged: onEnabled),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'test':
                  onTest();
                  break;
                case 'edit':
                  onEdit();
                  break;
                case 'delete':
                  onDelete();
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'test', child: Text('Test now')),
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Remove')),
            ],
          ),
        ],
      ),
    );
  }
}

class _RegisteredSummary extends StatelessWidget {
  final String emptyText;
  final List<RustlerDevice> devices;

  const _RegisteredSummary({required this.emptyText, required this.devices});

  @override
  Widget build(BuildContext context) {
    if (devices.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(emptyText),
      );
    }

    return Column(
      children: devices
          .map(
            (device) => ListTile(
              leading: Icon(_iconForDevice(device.type)),
              title: Text(device.name),
              subtitle: Text(
                '${device.manufacturer}${device.model == null ? '' : ' • ${device.model}'}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.circle,
                    size: 10,
                    color:
                        device.available ? Colors.greenAccent : Colors.white38,
                  ),
                  const SizedBox(width: 6),
                  Text(device.available ? 'LIVE' : 'OFFLINE'),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _LocalDeviceDialog extends StatefulWidget {
  final LocalHttpDevice? existing;

  const _LocalDeviceDialog({this.existing});

  @override
  State<_LocalDeviceDialog> createState() => _LocalDeviceDialogState();
}

class _LocalDeviceDialogState extends State<_LocalDeviceDialog> {
  late final TextEditingController nameController;
  late final TextEditingController hostController;
  late final TextEditingController portController;
  late final TextEditingController statusController;
  late final TextEditingController controlController;
  late final TextEditingController protocolIdController;
  late final TextEditingController pollController;
  late LocalHttpDeviceKind kind;

  @override
  void initState() {
    super.initState();
    final LocalHttpDevice? existing = widget.existing;
    kind = existing?.kind ?? LocalHttpDeviceKind.espJson;
    nameController = TextEditingController(text: existing?.name ?? '');
    hostController = TextEditingController(text: existing?.host ?? '');
    portController = TextEditingController(text: '${existing?.port ?? 80}');
    statusController = TextEditingController(
      text: existing?.statusPath ?? _defaultStatus(kind),
    );
    controlController =
        TextEditingController(text: existing?.controlPath ?? '');
    protocolIdController = TextEditingController(
      text: existing?.protocolDeviceId ?? '',
    );
    pollController = TextEditingController(
      text: '${existing?.pollInterval.inSeconds ?? 3}',
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    hostController.dispose();
    portController.dispose();
    statusController.dispose();
    controlController.dispose();
    protocolIdController.dispose();
    pollController.dispose();
    super.dispose();
  }

  void _save() {
    final String name = nameController.text.trim();
    final String host = hostController.text.trim();
    final int? port = int.tryParse(portController.text.trim());
    final int poll = int.tryParse(pollController.text.trim()) ?? 3;

    if (name.isEmpty ||
        host.isEmpty ||
        port == null ||
        port < 1 ||
        port > 65535) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid name, host and port.')),
      );
      return;
    }

    final String id = widget.existing?.id ??
        '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

    Navigator.pop(
      context,
      LocalHttpDevice(
        id: id,
        name: name,
        host: host,
        port: port,
        kind: kind,
        statusPath: statusController.text.trim().isEmpty
            ? _defaultStatus(kind)
            : statusController.text.trim(),
        controlPath: _nullable(controlController.text),
        protocolDeviceId: _nullable(protocolIdController.text),
        pollInterval: Duration(seconds: poll.clamp(1, 3600).toInt()),
        enabled: widget.existing?.enabled ?? true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add local device' : 'Edit device'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<LocalHttpDeviceKind>(
                initialValue: kind,
                decoration:
                    const InputDecoration(labelText: 'Integration type'),
                items: LocalHttpDeviceKind.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(_labelForKind(value)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    kind = value;
                    if (widget.existing == null ||
                        statusController.text.trim().isEmpty) {
                      statusController.text = _defaultStatus(value);
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Device name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hostController,
                decoration: const InputDecoration(
                  labelText: 'IP address / hostname',
                  hintText: '192.168.1.50',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: portController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Port'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: statusController,
                decoration: const InputDecoration(labelText: 'Status path'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controlController,
                decoration: const InputDecoration(
                  labelText: 'Control path',
                  hintText: '/control',
                ),
              ),
              if (kind == LocalHttpDeviceKind.sonoffDiy) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: protocolIdController,
                  decoration: const InputDecoration(
                    labelText: 'SONOFF device ID',
                    hintText: 'Optional if firmware accepts blank ID',
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: pollController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Poll interval (seconds)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        FilledButton(onPressed: _save, child: const Text('SAVE')),
      ],
    );
  }
}

String _defaultStatus(LocalHttpDeviceKind kind) {
  return switch (kind) {
    LocalHttpDeviceKind.sonoffDiy => '/zeroconf/info',
    _ => '/status',
  };
}

String? _nullable(String value) {
  final String text = value.trim();
  return text.isEmpty ? null : text;
}

String _labelForKind(LocalHttpDeviceKind kind) {
  return switch (kind) {
    LocalHttpDeviceKind.espJson => 'ESP / ESP32 JSON',
    LocalHttpDeviceKind.sonoffDiy => 'SONOFF DIY',
    LocalHttpDeviceKind.tuyaBridge => 'Tuya local bridge',
    LocalHttpDeviceKind.customJson => 'Custom HTTP JSON',
  };
}

IconData _iconForKind(LocalHttpDeviceKind kind) {
  return switch (kind) {
    LocalHttpDeviceKind.espJson => Icons.memory,
    LocalHttpDeviceKind.sonoffDiy => Icons.toggle_on,
    LocalHttpDeviceKind.tuyaBridge => Icons.hub,
    LocalHttpDeviceKind.customJson => Icons.http,
  };
}

IconData _iconForDevice(RustlerDeviceType type) {
  return switch (type) {
    RustlerDeviceType.batteryMonitor => Icons.battery_5_bar,
    RustlerDeviceType.solarCharger => Icons.solar_power,
    RustlerDeviceType.acCharger => Icons.battery_charging_full,
    RustlerDeviceType.dcDcCharger => Icons.electrical_services,
    RustlerDeviceType.fridge => Icons.kitchen,
    RustlerDeviceType.waterTank => Icons.water_drop,
    RustlerDeviceType.gps => Icons.gps_fixed,
    RustlerDeviceType.media => Icons.music_note,
    RustlerDeviceType.relay => Icons.toggle_on,
    RustlerDeviceType.sensor => Icons.sensors,
    RustlerDeviceType.hub => Icons.hub,
    RustlerDeviceType.unknown => Icons.devices_other,
  };
}
