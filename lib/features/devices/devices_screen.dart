import 'package:flutter/material.dart';

import '../../models/victron_device.dart';
import '../../models/victron_device_type.dart';
import '../../services/bluetooth_service.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() =>
      _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final VictronBluetoothService bluetooth =
      VictronBluetoothService.instance;

  bool _isScanning = false;

  Future<void> _scan() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
    });

    try {
      await bluetooth.startScan();
    } catch (error) {
      if (!mounted) return;

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

  Future<void> _connect(
    VictronDevice device,
  ) async {
    try {
      await bluetooth.connect(device);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${device.displayName} enabled',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString(),
          ),
        ),
      );
    }
  }

  String _typeLabel(
    VictronDeviceType type,
  ) {
    switch (type) {
      case VictronDeviceType.blueSmartCharger:
        return 'Victron Blue Smart Charger';

      case VictronDeviceType.smartSolar:
        return 'Victron SmartSolar MPPT';

      case VictronDeviceType.smartShunt:
        return 'Victron SmartShunt / BMV';

      case VictronDeviceType.orionSmart:
        return 'Victron Orion Smart DC-DC';

      case VictronDeviceType.orionXs:
        return 'Victron Orion XS DC-DC';

      case VictronDeviceType.unknown:
        return 'Victron Bluetooth Device';
    }
  }

  IconData _deviceIcon(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<VictronDevice>>(
        stream: bluetooth.devices,
        builder: (context, snapshot) {
          final List<VictronDevice> devices =
              snapshot.data ?? const [];

          if (devices.isEmpty) {
            return _EmptyDevices(
              isScanning: _isScanning,
              onScan: _scan,
            );
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${devices.length} Bluetooth device'
                      '${devices.length == 1 ? '' : 's'} detected',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_isScanning)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              ...devices.map(
                (device) => _DeviceCard(
                  device: device,
                  typeLabel:
                      _typeLabel(device.type),
                  icon:
                      _deviceIcon(device.type),
                  bluetooth: bluetooth,
                  onConnect: () =>
                      _connect(device),
                ),
              ),
            ],
          );
        },
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed:
            _isScanning ? null : _scan,
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
        tooltip: 'Scan for Bluetooth devices',
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final VictronDevice device;
  final String typeLabel;
  final IconData icon;

  final VictronBluetoothService bluetooth;

  final VoidCallback onConnect;

  const _DeviceCard({
    required this.device,
    required this.typeLabel,
    required this.icon,
    required this.bluetooth,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final String deviceId =
        device.device.remoteId.str;

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: ExpansionTile(
        leading: Icon(
          icon,
          size: 36,
        ),
        title: Text(
          device.displayName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '$typeLabel • ${device.rssi} dBm',
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
            label: 'Bluetooth ID',
            value: deviceId,
          ),

          _InfoRow(
            label: 'Device type',
            value: typeLabel,
          ),

          _InfoRow(
            label: 'Signal',
            value: '${device.rssi} dBm',
          ),

          _InfoRow(
            label: 'Instant Readout',
            value: device.hasInstantReadout
                ? 'Supported'
                : 'Not detected',
          ),

          if (device.modelId != null)
            _InfoRow(
              label: 'Model ID',
              value: device.modelIdHex,
            ),

          if (device.recordType != null)
            _InfoRow(
              label: 'Record type',
              value: device.recordTypeHex,
            ),

          _InfoRow(
            label: 'Manufacturer',
            value: 'Victron Energy',
          ),

          const SizedBox(height: 14),

          ValueListenableBuilder<VictronDevice?>(
            valueListenable:
                bluetooth.connectedDevice,
            builder: (
              context,
              connectedDevice,
              child,
            ) {
              final bool connected =
                  connectedDevice
                          ?.device.remoteId.str ==
                      deviceId;

              if (device.hasInstantReadout) {
                return SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed:
                        connected
                            ? null
                            : onConnect,
                    icon: Icon(
                      connected
                          ? Icons.check_circle
                          : Icons.sensors,
                    ),
                    label: Text(
                      connected
                          ? 'LIVE DATA ENABLED'
                          : 'SET UP DEVICE',
                    ),
                  ),
                );
              }

              return SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed:
                      connected
                          ? null
                          : onConnect,
                  icon: Icon(
                    connected
                        ? Icons.check_circle
                        : Icons
                            .bluetooth_connected,
                  ),
                  label: Text(
                    connected
                        ? 'CONNECTED'
                        : 'SET UP DEVICE',
                  ),
                ),
              );
            },
          ),

          if (device.hasInstantReadout) ...[
            const SizedBox(height: 8),
            const Text(
              'Once configured, Rustler GX '
              'can monitor this device '
              'automatically when it is in range.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyDevices extends StatelessWidget {
  final bool isScanning;
  final VoidCallback onScan;

  const _EmptyDevices({
    required this.isScanning,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.bluetooth_searching,
              size: 64,
            ),

            const SizedBox(height: 16),

            const Text(
              'No Bluetooth devices detected',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Scan for nearby supported '
              'Bluetooth devices.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 18),

            ElevatedButton.icon(
              onPressed:
                  isScanning ? null : onScan,
              icon: isScanning
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
      padding:
          const EdgeInsets.symmetric(
        vertical: 4,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}