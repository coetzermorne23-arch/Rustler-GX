import 'package:flutter/material.dart';
import '../models/battery_data.dart';

class BatteryCard extends StatelessWidget {
  final BatteryData data;

  const BatteryCard({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "🔋 Battery",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text("${data.percentage}%"),
            Text("${data.voltage.toStringAsFixed(2)} V"),
            Text("${data.temperature.toStringAsFixed(1)} °C"),
          ],
        ),
      ),
    );
  }
}