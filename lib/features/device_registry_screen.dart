import 'package:flutter/material.dart';

import '../models/rustler_device.dart';
import '../models/rustler_entity.dart';
import '../services/device_entity_link_service.dart';
import '../services/device_registry_service.dart';

class DeviceRegistryScreen extends StatelessWidget {
  const DeviceRegistryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DeviceRegistryService registry =
        DeviceRegistryService.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rustler GX Devices'),
      ),
      body: ValueListenableBuilder<Map<String, RustlerDevice>>(
        valueListenable: registry.devices,
        builder: (context, deviceMap, child) {
          final List<RustlerDevice> devices =
              deviceMap.values.toList()
                ..sort(
                  (a, b) => a.name.compareTo(b.name),
                );

          if (devices.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.devices_other,
                      size: 64,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No registered devices yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Devices will appear here when an integration publishes data.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: devices.length,
            itemBuilder: (context, index) {
              return _DeviceCard(
                device: devices[index],
              );
            },
          );
        },
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final RustlerDevice device;

  const _DeviceCard({
    required this.device,
  });

  @override
  Widget build(BuildContext context) {
    final DeviceEntityLinkService linkService =
        DeviceEntityLinkService.instance;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: Icon(
          _iconForType(device.type),
          size: 34,
        ),
        title: Text(
          device.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${device.manufacturer}'
          '${device.model == null ? '' : ' • ${device.model}'}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              device.available
                  ? Icons.circle
                  : Icons.circle_outlined,
              size: 10,
              color: device.available
                  ? Colors.greenAccent
                  : Colors.white38,
            ),
            const SizedBox(width: 6),
            Text(
              device.available
                  ? 'LIVE'
                  : 'OFFLINE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: device.available
                    ? Colors.greenAccent
                    : Colors.white38,
              ),
            ),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16,
        ),
        children: [
          _InfoRow(
            label: 'Device ID',
            value: device.id,
          ),
          _InfoRow(
            label: 'Source',
            value: device.source,
          ),
          _InfoRow(
            label: 'Type',
            value: device.type.name,
          ),
          const Divider(height: 24),
          ValueListenableBuilder<Map<String, RustlerEntity>>(
            valueListenable: linkService.entities.entities,
            builder: (context, entityMap, child) {
              final List<RustlerEntity> entities =
                  linkService.entitiesForDevice(
                device.id,
              );

              if (entities.isEmpty) {
                return const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'No entities published yet.',
                  ),
                );
              }

              entities.sort(
                (a, b) => a.name.compareTo(b.name),
              );

              return Column(
                children: entities
                    .map(
                      (entity) => _EntityRow(
                        entity: entity,
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

  IconData _iconForType(
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
}

class _EntityRow extends StatelessWidget {
  final RustlerEntity entity;

  const _EntityRow({
    required this.entity,
  });

  @override
  Widget build(BuildContext context) {
    final String value = entity.unit == null
        ? '${entity.value}'
        : '${entity.value} ${entity.unit}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              entity.name,
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 95,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(value),
          ),
        ],
      ),
    );
  }
}
