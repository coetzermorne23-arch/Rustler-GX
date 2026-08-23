import 'package:flutter/material.dart';

import '../models/discovered_hub.dart';
import '../services/entity_service.dart';
import '../services/hub_client_service.dart';
import '../services/hub_discovery_service.dart';
import '../services/rustler_gx_config_service.dart';

class HubSettingsScreen extends StatefulWidget {
  const HubSettingsScreen({
    super.key,
  });

  @override
  State<HubSettingsScreen> createState() =>
      _HubSettingsScreenState();
}

class _HubSettingsScreenState
    extends State<HubSettingsScreen> {
  final RustlerGxConfigService config =
      RustlerGxConfigService.instance;

  final HubClientService hub =
      HubClientService.instance;

  final HubDiscoveryService discovery =
      HubDiscoveryService.instance;

  final EntityService entities =
      EntityService.instance;

  final TextEditingController hostController =
      TextEditingController();

  final TextEditingController portController =
      TextEditingController();

  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();

    _load();
  }

  Future<void> _load() async {
    final String host =
        await config.getHubHost();

    final int port =
        await config.getHubPort();

    hostController.text = host;
    portController.text = port.toString();

    try {
      await discovery.startListening();
    } catch (_) {}

    if (!mounted) {
      return;
    }

    setState(() {
      loading = false;
    });
  }

  @override
  void dispose() {
    hostController.dispose();
    portController.dispose();

    super.dispose();
  }

  Future<bool> _saveSettings() async {
    final String host =
        hostController.text.trim();

    final int? port =
        int.tryParse(
      portController.text.trim(),
    );

    if (host.isEmpty) {
      _message(
        'Hub address cannot be empty.',
      );

      return false;
    }

    if (port == null ||
        port < 1 ||
        port > 65535) {
      _message(
        'Hub port must be between 1 and 65535.',
      );

      return false;
    }

    setState(() {
      saving = true;
    });

    try {
      await config.setHubHost(
        host,
      );

      await config.setHubPort(
        port,
      );

      return true;
    } catch (error) {
      _message(
        error.toString(),
      );

      return false;
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  Future<void> _connect() async {
    final bool saved =
        await _saveSettings();

    if (!saved) {
      return;
    }

    await hub.reconnect();
  }

  Future<void> _selectHub(
    DiscoveredHub discoveredHub,
  ) async {
    hostController.text =
        discoveredHub.host;

    portController.text =
        discoveredHub.port.toString();

    final bool saved =
        await _saveSettings();

    if (!saved) {
      return;
    }

    await hub.reconnect();
  }

  void _message(
    String value,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(value),
      ),
    );
  }

  String _stateText(
    HubConnectionState state,
  ) {
    switch (state) {
      case HubConnectionState.disconnected:
        return 'Disconnected';

      case HubConnectionState.connecting:
        return 'Connecting';

      case HubConnectionState.connected:
        return 'Connected';

      case HubConnectionState.reconnecting:
        return 'Reconnecting';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Rustler GX Hub',
          ),
        ),
        body: const Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Rustler GX Hub',
        ),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          const Text(
            'Discovered Hubs',
            style: TextStyle(
              fontSize: 22,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Rustler GX automatically searches '
            'for hubs on the local network.',
            style: TextStyle(
              color: Colors.white70,
            ),
          ),

          const SizedBox(height: 14),

          ValueListenableBuilder<
              List<DiscoveredHub>>(
            valueListenable:
                discovery.hubs,
            builder: (
              context,
              hubs,
              child,
            ) {
              if (hubs.isEmpty) {
                return const Card(
                  child: Padding(
                    padding:
                        EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          size: 30,
                        ),
                        SizedBox(
                          width: 14,
                        ),
                        Expanded(
                          child: Text(
                            'Searching for Rustler GX hubs...',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: hubs
                    .map(
                      (discoveredHub) =>
                          Card(
                        child: ListTile(
                          leading:
                              const Icon(
                            Icons.hub,
                            size: 30,
                          ),
                          title: Text(
                            discoveredHub
                                .name,
                          ),
                          subtitle: Text(
                            '${discoveredHub.host}:'
                            '${discoveredHub.port}',
                          ),
                          trailing:
                              FilledButton(
                            onPressed:
                                saving
                                    ? null
                                    : () {
                                        _selectHub(
                                          discoveredHub,
                                        );
                                      },
                            child:
                                const Text(
                              'CONNECT',
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),

          const SizedBox(height: 26),

          const Divider(),

          const SizedBox(height: 18),

          const Text(
            'Manual Connection',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 14),

          TextField(
            controller:
                hostController,
            decoration:
                const InputDecoration(
              labelText: 'Hub address',
              hintText:
                  '192.168.1.50',
              prefixIcon:
                  Icon(Icons.dns),
              border:
                  OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller:
                portController,
            keyboardType:
                TextInputType.number,
            decoration:
                const InputDecoration(
              labelText: 'Port',
              hintText: '8765',
              prefixIcon: Icon(
                Icons.settings_ethernet,
              ),
              border:
                  OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child:
                    FilledButton.icon(
                  onPressed:
                      saving
                          ? null
                          : _connect,
                  icon: const Icon(
                    Icons.link,
                  ),
                  label: const Text(
                    'CONNECT',
                  ),
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child:
                    OutlinedButton.icon(
                  onPressed: () {
                    hub.disconnect();
                  },
                  icon: const Icon(
                    Icons.link_off,
                  ),
                  label: const Text(
                    'DISCONNECT',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          ValueListenableBuilder<
              HubConnectionState>(
            valueListenable:
                hub.connectionState,
            builder: (
              context,
              state,
              child,
            ) {
              return _InfoTile(
                icon: state ==
                        HubConnectionState
                            .connected
                    ? Icons.cloud_done
                    : Icons.cloud_off,
                title:
                    'Connection',
                value:
                    _stateText(state),
              );
            },
          ),

          ValueListenableBuilder<
              Map<String, dynamic>>(
            valueListenable:
                entities.entities,
            builder: (
              context,
              entityMap,
              child,
            ) {
              final int count =
                  entityMap.values
                      .where(
                        (entity) =>
                            entity.id
                                .startsWith(
                              'hub.',
                            ),
                      )
                      .length;

              return _InfoTile(
                icon:
                    Icons.sensors,
                title:
                    'Remote entities',
                value:
                    count.toString(),
              );
            },
          ),

          ValueListenableBuilder<
              DateTime?>(
            valueListenable:
                hub.lastMessageAt,
            builder: (
              context,
              value,
              child,
            ) {
              return _InfoTile(
                icon:
                    Icons.schedule,
                title:
                    'Last message',
                value: value == null
                    ? 'Never'
                    : value
                        .toLocal()
                        .toString(),
              );
            },
          ),

          ValueListenableBuilder<
              String?>(
            valueListenable:
                hub.lastError,
            builder: (
              context,
              error,
              child,
            ) {
              if (error == null ||
                  error.isEmpty) {
                return const SizedBox
                    .shrink();
              }

              return _InfoTile(
                icon:
                    Icons.error_outline,
                title:
                    'Last error',
                value: error,
              );
            },
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _InfoTile
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          size: 28,
        ),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }
}