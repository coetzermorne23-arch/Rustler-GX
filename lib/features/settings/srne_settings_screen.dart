import 'package:flutter/material.dart';
import '../../services/srne_config_service.dart';

class SrneSettingsScreen extends StatefulWidget {
  const SrneSettingsScreen({super.key});
  @override
  State<SrneSettingsScreen> createState() => _SrneSettingsScreenState();
}

class _SrneSettingsScreenState extends State<SrneSettingsScreen> {
  final s = SrneConfigService.instance;
  final host = TextEditingController();
  final port = TextEditingController();
  final unit = TextEditingController();
  bool enabled = false;
  bool loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await s.load();
    final c = s.config.value;
    host.text = c.host;
    port.text = '${c.port}';
    unit.text = '${c.unitId}';
    enabled = c.enabled;
    if (mounted) setState(() => loading = false);
  }

  Future<void> _save() async {
    await s.save(SrneConfig(
        host: host.text.trim(),
        port: int.tryParse(port.text) ?? 502,
        unitId: int.tryParse(unit.text) ?? 1,
        enabled: enabled));
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SRNE local connection saved')));
  }

  Future<void> _test() async {
    await _save();
    final ok = await s.testTcp();
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              ok ? 'TCP endpoint reachable' : 'Could not reach TCP endpoint')));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('SRNE local inverter')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(16), children: [
              const Text(
                  'Local-first SRNE endpoint. Use the inverter Wi-Fi dongle on your private router. Internet access is not required.',
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              SwitchListTile(
                  title: const Text('Enable SRNE integration'),
                  value: enabled,
                  onChanged: (v) => setState(() => enabled = v)),
              TextField(
                  controller: host,
                  decoration: const InputDecoration(
                      labelText: 'Dongle IP / hostname',
                      hintText: '192.168.8.50',
                      border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(
                  controller: port,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'TCP port', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(
                  controller: unit,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Modbus unit ID',
                      border: OutlineInputBorder())),
              const SizedBox(height: 16),
              Wrap(spacing: 10, children: [
                FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: const Text('SAVE')),
                OutlinedButton.icon(
                    onPressed: _test,
                    icon: const Icon(Icons.cable),
                    label: const Text('TEST TCP'))
              ]),
              const SizedBox(height: 18),
              const Card(
                  child: ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('Register decoder intentionally separated'),
                      subtitle: Text(
                          'RigOS stores and tests the local endpoint now. Exact SRNE register mapping is kept in its adapter layer so other inverter brands can use the same normalized entities.')))
            ]));
}
