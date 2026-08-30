import 'package:flutter/material.dart';
import '../models/victron_device.dart';

class ChargerCard extends StatelessWidget {
  final VictronDevice charger;
  final VoidCallback onConnect;

  const ChargerCard({
    super.key,
    required this.charger,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final String name = charger.advertisedName.isNotEmpty
        ? charger.advertisedName
        : charger.platformName;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.battery_charging_full,
                  size: 38,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Blue Smart Charger',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(name),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Signal: ${charger.rssi} dBm'),
            const Text('Model: IP65 12/15'),
            const Text('Status: Discovered'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onConnect,
                icon: const Icon(Icons.bluetooth_connected),
                label: const Text('CONNECT'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
