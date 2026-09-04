import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/paired_endpoint.dart';
import '../../services/pairing_service.dart';
import '../devices/devices_screen.dart';
import '../integrations/integrations_screen.dart';

class DevicePairingScreen extends StatefulWidget {
  const DevicePairingScreen({super.key});
  @override
  State<DevicePairingScreen> createState() => _DevicePairingScreenState();
}

class _DevicePairingScreenState extends State<DevicePairingScreen> {
  final pairing = PairingService.instance;
  @override
  void initState() {
    super.initState();
    pairing.load();
  }

  Future<void> _manual({String? qr}) async {
    final name = TextEditingController();
    final address = TextEditingController();
    final port = TextEditingController(text: '502');
    final protocol = TextEditingController(text: 'modbus-tcp');
    if (qr != null) {
      try {
        final e = pairing.decodeQr(qr);
        name.text = e.name;
        address.text = e.address;
        port.text = '${e.port ?? 502}';
        protocol.text = e.protocol;
      } catch (_) {}
    }
    final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
                title: Text(
                    qr == null ? 'Pair network device' : 'Import pairing code'),
                content: SizedBox(
                    width: 460,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      TextField(
                          controller: name,
                          decoration: const InputDecoration(labelText: 'Name')),
                      TextField(
                          controller: address,
                          decoration: const InputDecoration(
                              labelText: 'IP / hostname')),
                      TextField(
                          controller: port,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Port')),
                      TextField(
                          controller: protocol,
                          decoration: const InputDecoration(
                              labelText:
                                  'Protocol (e.g. modbus-tcp, mqtt, http)')),
                    ])),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('CANCEL')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('PAIR'))
                ]));
    if (ok == true && address.text.trim().isNotEmpty) {
      await pairing.upsert(PairedEndpoint(
          id: 'rig-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}',
          name: name.text.trim().isEmpty ? 'Network device' : name.text.trim(),
          method: qr == null ? RigPairMethod.network : RigPairMethod.qr,
          address: address.text.trim(),
          protocol: protocol.text.trim(),
          port: int.tryParse(port.text)));
    }
  }

  Future<void> _pasteQr() async {
    final c = TextEditingController();
    final raw = await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
                title: const Text('RigOS pairing code'),
                content: TextField(
                    controller: c,
                    maxLines: 5,
                    decoration: const InputDecoration(
                        hintText: 'Paste scanned QR payload here',
                        border: OutlineInputBorder())),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('CANCEL')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, c.text),
                      child: const Text('IMPORT'))
                ]));
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final e = pairing.decodeQr(raw.trim());
        await pairing.upsert(e);
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Add / pair device')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Wrap(spacing: 10, runSpacing: 10, children: [
          FilledButton.icon(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const DevicesScreen())),
              icon: const Icon(Icons.bluetooth_searching),
              label: const Text('BLUETOOTH SCAN')),
          FilledButton.icon(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const IntegrationsScreen())),
              icon: const Icon(Icons.wifi_find),
              label: const Text('LOCAL DEVICES')),
          FilledButton.icon(
              onPressed: () => _manual(),
              icon: const Icon(Icons.lan),
              label: const Text('IP / HOSTNAME')),
          FilledButton.icon(
              onPressed: _pasteQr,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('QR CODE'))
        ]),
        const SizedBox(height: 18),
        const Text('PAIRED ENDPOINTS',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        ValueListenableBuilder<List<PairedEndpoint>>(
            valueListenable: pairing.endpoints,
            builder: (_, items, __) => items.isEmpty
                ? const Card(
                    child: ListTile(
                        title: Text('No universal endpoints paired yet'),
                        subtitle: Text(
                            'Victron BLE and existing integrations still work independently.')))
                : Column(
                    children: items
                        .map((e) => Card(
                            child: ListTile(
                                leading: Icon(
                                    e.method == RigPairMethod.bluetooth
                                        ? Icons.bluetooth
                                        : Icons.router),
                                title: Text(e.name),
                                subtitle: Text(
                                    '${e.protocol} • ${e.address}${e.port == null ? '' : ':${e.port}'}'),
                                trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => pairing.remove(e.id)))))
                        .toList())),
      ]));
}
