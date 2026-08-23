import 'package:flutter/material.dart';

import '../../models/rustler_device.dart';
import '../../models/rustler_entity.dart';
import '../../models/victron_device.dart';
import '../../models/victron_device_type.dart';

import '../../services/bluetooth_service.dart';
import '../../services/device_entity_link_service.dart';
import '../../services/device_registry_service.dart';
import '../../services/entity_service.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({
    super.key,
  });

  @override
  State<DevicesScreen> createState() =>
      _DevicesScreenState();
}

class _DevicesScreenState
    extends State<DevicesScreen>
    with SingleTickerProviderStateMixin {
  final VictronBluetoothService bluetooth =
      VictronBluetoothService.instance;

  final DeviceRegistryService registry =
      DeviceRegistryService.instance;

  final EntityService entityService =
      EntityService.instance;

  final DeviceEntityLinkService links =
      DeviceEntityLinkService.instance;

  late final TabController tabController;

  bool _isScanning = false;

  @override
  void initState() {
    super.initState();

    tabController = TabController(
      length: 2,
      vsync: this,
    );
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    if (_isScanning) {
      return;
    }

    setState(() {
      _isScanning = true;
    });

    try {
      await bluetooth.startScan();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bluetooth scan failed: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _setupVictron(
    VictronDevice device,
  ) async {
    try {
      await bluetooth.connect(
        device,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${device.displayName} configured.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Devices',
        ),
        bottom: TabBar(
          controller: tabController,
          tabs: const [
            Tab(
              icon: Icon(
                Icons.bluetooth_searching,
              ),
              text: 'Nearby',
            ),
            Tab(
              icon: Icon(
                Icons.devices,
              ),
              text: 'Configured',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          _NearbyDevicesTab(
            bluetooth: bluetooth,
            isScanning: _isScanning,
            onScan: _scan,
            onSetup: _setupVictron,
          ),
          _ConfiguredDevicesTab(
            registry: registry,
            entityService: entityService,
            links: links,
          ),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: tabController,
        builder: (
          context,
          child,
        ) {
          if (tabController.index == 0) {
            return FloatingActionButton.extended(
              onPressed:
                  _isScanning
                      ? null
                      : _scan,
              icon: _isScanning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.bluetooth_searching,
                    ),
              label: Text(
                _isScanning
                    ? 'SCANNING...'
                    : 'SCAN FOR BT DEVICES',
              ),
            );
          }

          return FloatingActionButton.extended(
            onPressed: () {
              tabController.animateTo(
                0,
              );
            },
            icon: const Icon(
              Icons.add,
            ),
            label: const Text(
              'ADD DEVICE',
            ),
          );
        },
      ),
    );
  }
}

// ===========================================================
// NEARBY DEVICES
// ===========================================================

class _NearbyDevicesTab extends StatelessWidget {
  final VictronBluetoothService bluetooth;
  final bool isScanning;
  final VoidCallback onScan;
  final Future<void> Function(
    VictronDevice device,
  ) onSetup;

  const _NearbyDevicesTab({
    required this.bluetooth,
    required this.isScanning,
    required this.onScan,
    required this.onSetup,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<VictronDevice>>(
      stream: bluetooth.devices,
      builder: (
        context,
        snapshot,
      ) {
        final List<VictronDevice> devices =
            snapshot.data ??
                const <VictronDevice>[];

        if (devices.isEmpty) {
          return _NoNearbyDevices(
            isScanning: isScanning,
            onScan: onScan,
          );
        }

        return ListView(
          padding:
              const EdgeInsets.fromLTRB(
            12,
            16,
            12,
            90,
          ),
          children: [
            Row(
              children: [
                const Icon(
                  Icons.radar,
                ),
                const SizedBox(
                  width: 8,
                ),
                Expanded(
                  child: Text(
                    '${devices.length} nearby '
                    'Bluetooth device'
                    '${devices.length == 1 ? '' : 's'}',
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
                if (isScanning)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
              ],
            ),

            const SizedBox(
              height: 14,
            ),

            ...devices.map(
              (device) =>
                  _NearbyDeviceCard(
                device: device,
                bluetooth:
                    bluetooth,
                onSetup: () =>
                    onSetup(
                  device,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NearbyDeviceCard
    extends StatelessWidget {
  final VictronDevice device;
  final VictronBluetoothService bluetooth;
  final VoidCallback onSetup;

  const _NearbyDeviceCard({
    required this.device,
    required this.bluetooth,
    required this.onSetup,
  });

  @override
  Widget build(BuildContext context) {
    final String deviceId =
        device.device.remoteId.str;

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          child: Icon(
            _victronIcon(
              device.type,
            ),
          ),
        ),
        title: Text(
          device.displayName,
          style: const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${_victronTypeLabel(device.type)}'
          ' • ${device.rssi} dBm',
        ),
        childrenPadding:
            const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16,
        ),
        children: [
          _InfoRow(
            label: 'Manufacturer',
            value: 'Victron Energy',
          ),

          _InfoRow(
            label: 'Type',
            value:
                _victronTypeLabel(
              device.type,
            ),
          ),

          _InfoRow(
            label: 'Bluetooth ID',
            value: deviceId,
          ),

          _InfoRow(
            label: 'Signal',
            value:
                '${device.rssi} dBm',
          ),

          _InfoRow(
            label:
                'Instant Readout',
            value:
                device.hasInstantReadout
                    ? 'Supported'
                    : 'Not detected',
          ),

          if (device.modelId != null)
            _InfoRow(
              label: 'Model ID',
              value:
                  device.modelIdHex,
            ),

          if (device.recordType !=
              null)
            _InfoRow(
              label:
                  'Record type',
              value:
                  device.recordTypeHex,
            ),

          const SizedBox(
            height: 14,
          ),

          ValueListenableBuilder<
              VictronDevice?>(
            valueListenable:
                bluetooth
                    .connectedDevice,
            builder: (
              context,
              connected,
              child,
            ) {
              final bool active =
                  connected
                          ?.device
                          .remoteId
                          .str ==
                      deviceId;

              return SizedBox(
                width:
                    double.infinity,
                child:
                    FilledButton.icon(
                  onPressed:
                      active
                          ? null
                          : onSetup,
                  icon: Icon(
                    active
                        ? Icons
                            .check_circle
                        : Icons.add,
                  ),
                  label: Text(
                    active
                        ? 'CONFIGURED'
                        : 'SET UP DEVICE',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// CONFIGURED DEVICES
// ===========================================================

class _ConfiguredDevicesTab
    extends StatelessWidget {
  final DeviceRegistryService registry;
  final EntityService entityService;
  final DeviceEntityLinkService links;

  const _ConfiguredDevicesTab({
    required this.registry,
    required this.entityService,
    required this.links,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<
        Map<String, RustlerDevice>>(
      valueListenable:
          registry.devices,
      builder: (
        context,
        devices,
        child,
      ) {
        if (devices.isEmpty) {
          return const _NoConfiguredDevices();
        }

        final List<RustlerDevice> list =
            devices.values.toList()
              ..sort(
                (
                  a,
                  b,
                ) =>
                    a.name.compareTo(
                  b.name,
                ),
              );

        return ListView(
          padding:
              const EdgeInsets.fromLTRB(
            12,
            16,
            12,
            90,
          ),
          children: [
            Row(
              children: [
                const Icon(
                  Icons.devices,
                ),
                const SizedBox(
                  width: 8,
                ),
                Expanded(
                  child: Text(
                    '${list.length} configured '
                    'device'
                    '${list.length == 1 ? '' : 's'}',
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 14,
            ),

            ...list.map(
              (device) =>
                  _ConfiguredDeviceCard(
                device: device,
                entityService:
                    entityService,
                links: links,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ConfiguredDeviceCard
    extends StatelessWidget {
  final RustlerDevice device;
  final EntityService entityService;
  final DeviceEntityLinkService links;

  const _ConfiguredDeviceCard({
    required this.device,
    required this.entityService,
    required this.links,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: ExpansionTile(
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              child: Icon(
                _rustlerDeviceIcon(
                  device.type,
                ),
              ),
            ),

            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 13,
                height: 13,
                decoration:
                    BoxDecoration(
                  shape:
                      BoxShape.circle,
                  color: device.available
                      ? Colors.green
                      : Colors.grey,
                  border: Border.all(
                    color: Theme.of(
                      context,
                    )
                        .scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          device.name,
          style: const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${_rustlerDeviceTypeLabel(device.type)}'
          ' • '
          '${device.available ? 'ONLINE' : 'OFFLINE'}',
        ),
        childrenPadding:
            const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16,
        ),
        children: [
          _InfoRow(
            label: 'Manufacturer',
            value:
                device.manufacturer,
          ),

          if (device.model != null &&
              device.model!.isNotEmpty)
            _InfoRow(
              label: 'Model',
              value: device.model!,
            ),

          _InfoRow(
            label: 'Source',
            value: device.source,
          ),

          _InfoRow(
            label: 'Device ID',
            value: device.id,
          ),

          _InfoRow(
            label: 'Status',
            value:
                device.available
                    ? 'Online'
                    : 'Offline',
          ),

          const SizedBox(
            height: 14,
          ),

          const Align(
            alignment:
                Alignment.centerLeft,
            child: Text(
              'Entities',
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          ValueListenableBuilder<
              Map<String, RustlerEntity>>(
            valueListenable:
                entityService.entities,
            builder: (
              context,
              entityMap,
              child,
            ) {
              final List<RustlerEntity>
                  deviceEntities =
                  device.entityIds
                      .map(
                        (
                          id,
                        ) =>
                            entityMap[id],
                      )
                      .whereType<
                          RustlerEntity>()
                      .toList();

              if (deviceEntities
                  .isEmpty) {
                return const Align(
                  alignment:
                      Alignment
                          .centerLeft,
                  child: Text(
                    'No entities yet.',
                    style: TextStyle(
                      color:
                          Colors.white54,
                    ),
                  ),
                );
              }

              return Column(
                children:
                    deviceEntities
                        .map(
                          (
                            entity,
                          ) =>
                              _EntityTile(
                            entity:
                                entity,
                          ),
                        )
                        .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// ENTITY TILE
// ===========================================================

class _EntityTile
    extends StatelessWidget {
  final RustlerEntity entity;

  const _EntityTile({
    required this.entity,
  });

  @override
  Widget build(BuildContext context) {
    final String value =
        _formatEntityValue(
      entity,
    );

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 6,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(
          10,
        ),
        color: Colors.white
            .withValues(
          alpha: 0.04,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _entityIcon(
              entity,
            ),
            size: 20,
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  entity.name,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),
                Text(
                  entity.available
                      ? entity.source
                      : 'OFFLINE',
                  style:
                      const TextStyle(
                    fontSize: 11,
                    color:
                        Colors.white54,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Text(
            value,
            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
              color:
                  entity.available
                      ? null
                      : Colors.white38,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// EMPTY STATES
// ===========================================================

class _NoNearbyDevices
    extends StatelessWidget {
  final bool isScanning;
  final VoidCallback onScan;

  const _NoNearbyDevices({
    required this.isScanning,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(
          24,
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons
                  .bluetooth_searching,
              size: 64,
            ),

            const SizedBox(
              height: 16,
            ),

            const Text(
              'No Bluetooth devices detected',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            const Text(
              'Scan for nearby supported '
              'Bluetooth devices.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Colors.white70,
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            FilledButton.icon(
              onPressed:
                  isScanning
                      ? null
                      : onScan,
              icon: const Icon(
                Icons
                    .bluetooth_searching,
              ),
              label: Text(
                isScanning
                    ? 'SCANNING...'
                    : 'SCAN FOR BT DEVICES',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoConfiguredDevices
    extends StatelessWidget {
  const _NoConfiguredDevices();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding:
            EdgeInsets.all(24),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Icon(
              Icons.devices_other,
              size: 64,
            ),
            SizedBox(
              height: 16,
            ),
            Text(
              'No configured devices',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            SizedBox(
              height: 8,
            ),
            Text(
              'Use the Nearby tab to add '
              'a device to Rustler GX.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================
// HELPERS
// ===========================================================

class _InfoRow
    extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 4,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style:
                  const TextStyle(
                color:
                    Colors.white70,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
            ),
          ),
        ],
      ),
    );
  }
}

String _victronTypeLabel(
  VictronDeviceType type,
) {
  switch (type) {
    case VictronDeviceType.blueSmartCharger:
      return 'Blue Smart Charger';

    case VictronDeviceType.smartSolar:
      return 'SmartSolar MPPT';

    case VictronDeviceType.smartShunt:
      return 'SmartShunt / BMV';

    case VictronDeviceType.orionSmart:
      return 'Orion Smart DC-DC';

    case VictronDeviceType.orionXs:
      return 'Orion XS DC-DC';

    case VictronDeviceType.unknown:
      return 'Victron Device';
  }
}

IconData _victronIcon(
  VictronDeviceType type,
) {
  switch (type) {
    case VictronDeviceType.smartSolar:
      return Icons.solar_power;

    case VictronDeviceType.smartShunt:
      return Icons.battery_5_bar;

    case VictronDeviceType.orionSmart:
    case VictronDeviceType.orionXs:
      return Icons.electrical_services;

    case VictronDeviceType.blueSmartCharger:
      return Icons.battery_charging_full;

    case VictronDeviceType.unknown:
      return Icons.bluetooth;
  }
}

String _rustlerDeviceTypeLabel(
  RustlerDeviceType type,
) {
  switch (type) {
    case RustlerDeviceType.batteryMonitor:
      return 'Battery Monitor';

    case RustlerDeviceType.solarCharger:
      return 'Solar Charger';

    case RustlerDeviceType.acCharger:
      return 'AC Charger';

    case RustlerDeviceType.dcDcCharger:
      return 'DC-DC Charger';

    case RustlerDeviceType.fridge:
      return 'Fridge';

    case RustlerDeviceType.waterTank:
      return 'Water Tank';

    case RustlerDeviceType.gps:
      return 'GPS';

    case RustlerDeviceType.media:
      return 'Media';

    case RustlerDeviceType.relay:
      return 'Relay';

    case RustlerDeviceType.sensor:
      return 'Sensor';

    case RustlerDeviceType.hub:
      return 'Rustler GX Hub';

    case RustlerDeviceType.unknown:
      return 'Device';
  }
}

IconData _rustlerDeviceIcon(
  RustlerDeviceType type,
) {
  switch (type) {
    case RustlerDeviceType.batteryMonitor:
      return Icons.battery_5_bar;

    case RustlerDeviceType.solarCharger:
      return Icons.solar_power;

    case RustlerDeviceType.acCharger:
      return Icons.battery_charging_full;

    case RustlerDeviceType.dcDcCharger:
      return Icons.electrical_services;

    case RustlerDeviceType.fridge:
      return Icons.kitchen;

    case RustlerDeviceType.waterTank:
      return Icons.water_drop;

    case RustlerDeviceType.gps:
      return Icons.gps_fixed;

    case RustlerDeviceType.media:
      return Icons.music_note;

    case RustlerDeviceType.relay:
      return Icons.toggle_on;

    case RustlerDeviceType.sensor:
      return Icons.sensors;

    case RustlerDeviceType.hub:
      return Icons.hub;

    case RustlerDeviceType.unknown:
      return Icons.devices_other;
  }
}

IconData _entityIcon(
  RustlerEntity entity,
) {
  switch (entity.type) {
    case RustlerEntityType.battery:
      return Icons.battery_5_bar;

    case RustlerEntityType.climate:
      return Icons.thermostat;

    case RustlerEntityType.switchEntity:
      return Icons.toggle_on;

    case RustlerEntityType.binarySensor:
      return Icons.circle;

    case RustlerEntityType.number:
      return Icons.numbers;

    case RustlerEntityType.gps:
      return Icons.gps_fixed;

    case RustlerEntityType.media:
      return Icons.music_note;

    case RustlerEntityType.sensor:
      return Icons.sensors;
  }
}

String _formatEntityValue(
  RustlerEntity entity,
) {
  if (!entity.available) {
    return 'OFFLINE';
  }

  final dynamic raw =
      entity.value;

  String value;

  if (raw is double) {
    if (raw.abs() >= 100) {
      value =
          raw.toStringAsFixed(
        0,
      );
    } else {
      value =
          raw.toStringAsFixed(
        2,
      );
    }
  } else {
    value = raw.toString();
  }

  if (entity.unit == null ||
      entity.unit!.isEmpty) {
    return value;
  }

  return '$value ${entity.unit}';
}