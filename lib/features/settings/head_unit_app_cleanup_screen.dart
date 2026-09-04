import 'package:flutter/material.dart';
import '../../services/head_unit_app_service.dart';

class HeadUnitAppCleanupScreen extends StatefulWidget {
  const HeadUnitAppCleanupScreen({super.key});
  @override
  State<HeadUnitAppCleanupScreen> createState() => _State();
}

class _State extends State<HeadUnitAppCleanupScreen> {
  final service = HeadUnitAppService.instance;
  @override
  void initState() {
    super.initState();
    service.refresh();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Head-unit apps'), actions: [
          IconButton(
              onPressed: service.refresh, icon: const Icon(Icons.refresh))
        ]),
        body: Column(children: [
          const Padding(
              padding: EdgeInsets.all(16),
              child: Card(
                  child: ListTile(
                leading: Icon(Icons.warning_amber_rounded),
                title: Text('Disable safely from Android app info'),
                subtitle: Text(
                    'RigOS lists launcher apps. Tap one to open Android App Info, then Disable/Force stop if the radio allows it. Do not disable MCU, CAN, Bluetooth, radio/tuner, launcher framework or system services until identified.'),
              ))),
          Expanded(
              child: ValueListenableBuilder<List<HeadUnitAppInfo>>(
            valueListenable: service.apps,
            builder: (context, apps, _) => apps.isEmpty
                ? const Center(
                    child: Text('No launcher apps returned • tap refresh'))
                : ListView.builder(
                    itemCount: apps.length,
                    itemBuilder: (context, i) {
                      final app = apps[i];
                      return ListTile(
                        leading: Icon(app.system ? Icons.android : Icons.apps),
                        title: Text(app.label),
                        subtitle: Text(app.packageName),
                        trailing: const Icon(Icons.settings),
                        onTap: () => service.openDetails(app.packageName),
                      );
                    }),
          )),
        ]),
      );
}
