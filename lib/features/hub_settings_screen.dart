import 'package:flutter/material.dart';

import '../services/entity_service.dart';
import '../services/hub_client_service.dart';
import '../services/rustler_gx_config_service.dart';

class HubSettingsScreen extends StatefulWidget {
  const HubSettingsScreen({super.key});

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
      _showMessage(
        'Hub address cannot be empty.',
      );

      return false;
    }

    if (port == null ||
        port < 1 ||
        port > 65535) {
      _showMessage(
        'Hub port must be between '
        '1 and 65535.',
      );

      return false;
    }

    if (mounted) {
      setState(() {
        saving = true;
      });
    }

    try {
      await config.setHubHost(
        host,
      );

      await config.setHubPort(
        port,
      );

      return true;
    } catch (error) {
      _showMessage(
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

  Future<void> _disconnect() async {
    await hub.disconnect();
  }

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
      ),
    );
  }

  String _stateLabel(
    HubConnectionState state,
  ) {
    switch (state) {
      case HubConnectionState.disconnected:
        return 'DISCONNECTED';

      case HubConnectionState.connecting:
        return 'CONNECTING';

      case HubConnectionState.connected:
        return 'CONNECTED';

      case HubConnectionState.reconnecting:
        return 'RECONNECTING';
    }
  }

  IconData _stateIcon(
    HubConnectionState state,
  ) {
    switch (state) {
      case HubConnectionState.connected:
        return Icons.cloud_done;

      case HubConnectionState.connecting:
      case HubConnectionState.reconnecting:
        return Icons.sync;

      case HubConnectionState.disconnected:
        return Icons.cloud_off;
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
          child: CircularProgressIndicator(),
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
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Hub Connection',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          const Text(
            'Connect this device to another '
            'Rustler GX device acting as a hub.',
            style: TextStyle(
              color: Colors.white70,
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          TextField(
            controller: hostController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Hub address',
              hintText:
                  'rustlergx.local or 192.168.1.50',
              prefixIcon: Icon(
                Icons.dns,
              ),
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          TextField(
            controller: portController,
            keyboardType:
                TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Hub port',
              hintText: '8765',
              prefixIcon: Icon(
                Icons.settings_ethernet,
              ),
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          // =================================================
          // CONNECTION STATUS
          // =================================================

          ValueListenableBuilder<
              HubConnectionState>(
            valueListenable:
                hub.connectionState,
            builder: (
              context,
              state,
              child,
            ) {
              return Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    16,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _stateIcon(
                          state,
                        ),
                        size: 34,
                      ),

                      const SizedBox(
                        width: 14,
                      ),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            const Text(
                              'Connection status',
                              style: TextStyle(
                                color:
                                    Colors.white70,
                              ),
                            ),

                            const SizedBox(
                              height: 3,
                            ),

                            Text(
                              _stateLabel(
                                state,
                              ),
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight
                                        .bold,
                                fontSize: 17,
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (state ==
                              HubConnectionState
                                  .connecting ||
                          state ==
                              HubConnectionState
                                  .reconnecting)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(
            height: 10,
          ),

          // =================================================
          // LAST MESSAGE
          // =================================================

          ValueListenableBuilder<
              DateTime?>(
            valueListenable:
                hub.lastMessageAt,
            builder: (
              context,
              lastMessage,
              child,
            ) {
              return _InfoCard(
                icon: Icons.schedule,
                label: 'Last message',
                value:
                    lastMessage == null
                        ? 'Never'
                        : _formatDateTime(
                            lastMessage,
                          ),
              );
            },
          ),

          const SizedBox(
            height: 10,
          ),

          // =================================================
          // REMOTE ENTITIES
          // =================================================

          ValueListenableBuilder(
            valueListenable:
                entities.entities,
            builder: (
              context,
              value,
              child,
            ) {
              final int remoteEntityCount =
                  value.values
                      .where(
                        (entity) =>
                            entity.id
                                .startsWith(
                              'hub.',
                            ),
                      )
                      .length;

              return _InfoCard(
                icon: Icons.sensors,
                label: 'Remote entities',
                value:
                    remoteEntityCount
                        .toString(),
              );
            },
          ),

          const SizedBox(
            height: 10,
          ),

          // =================================================
          // LAST ERROR
          // =================================================

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

              return Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    16,
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      const Icon(
                        Icons.error_outline,
                      ),

                      const SizedBox(
                        width: 12,
                      ),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            const Text(
                              'Last error',
                              style: TextStyle(
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),

                            const SizedBox(
                              height: 4,
                            ),

                            Text(
                              error,
                              style:
                                  const TextStyle(
                                color:
                                    Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(
            height: 20,
          ),

          // =================================================
          // CONNECT / DISCONNECT
          // =================================================

          ValueListenableBuilder<
              HubConnectionState>(
            valueListenable:
                hub.connectionState,
            builder: (
              context,
              state,
              child,
            ) {
              final bool connected =
                  state ==
                      HubConnectionState
                          .connected;

              final bool busy =
                  state ==
                          HubConnectionState
                              .connecting ||
                      state ==
                          HubConnectionState
                              .reconnecting;

              return Row(
                children: [
                  Expanded(
                    child:
                        FilledButton.icon(
                      onPressed:
                          saving || busy
                              ? null
                              : _connect,
                      icon: const Icon(
                        Icons.link,
                      ),
                      label: Text(
                        saving
                            ? 'SAVING...'
                            : connected
                                ? 'RECONNECT'
                                : 'CONNECT',
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child:
                        OutlinedButton.icon(
                      onPressed:
                          connected || busy
                              ? _disconnect
                              : null,
                      icon: const Icon(
                        Icons.link_off,
                      ),
                      label: const Text(
                        'DISCONNECT',
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(
            height: 14,
          ),

          // =================================================
          // SAVE
          // =================================================

          OutlinedButton.icon(
            onPressed:
                saving
                    ? null
                    : () async {
                        final bool saved =
                            await _saveSettings();

                        if (saved) {
                          _showMessage(
                            'Hub settings saved.',
                          );
                        }
                      },
            icon: const Icon(
              Icons.save,
            ),
            label: const Text(
              'SAVE SETTINGS',
            ),
          ),

          const SizedBox(
            height: 24,
          ),

          const Divider(),

          const SizedBox(
            height: 12,
          ),

          const Text(
            'Connection example',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          const Text(
            'Pi Zero 2 W:\n'
            '192.168.1.50 : 8765\n\n'
            'Tablet:\n'
            'Local Bluetooth remains active while '
            'remote Hub entities are received over '
            'the local network.',
            style: TextStyle(
              color: Colors.white70,
            ),
          ),

          const SizedBox(
            height: 30,
          ),
        ],
      ),
    );
  }

  static String _formatDateTime(
    DateTime value,
  ) {
    final DateTime local =
        value.toLocal();

    String two(
      int value,
    ) {
      return value
          .toString()
          .padLeft(
            2,
            '0',
          );
    }

    return '${two(local.day)}/'
        '${two(local.month)}/'
        '${local.year} '
        '${two(local.hour)}:'
        '${two(local.minute)}:'
        '${two(local.second)}';
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(
          16,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 30,
            ),

            const SizedBox(
              width: 14,
            ),

            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                ),
              ),
            ),

            Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}