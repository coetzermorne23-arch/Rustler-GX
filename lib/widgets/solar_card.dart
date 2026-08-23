import 'package:flutter/material.dart';

class SolarCard extends StatelessWidget {
  const SolarCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "☀ Solar",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text("0 W"),
            Text("0 A"),
            Text("No Input"),
          ],
        ),
      ),
    );
  }
}