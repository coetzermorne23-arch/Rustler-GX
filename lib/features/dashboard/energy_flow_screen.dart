import 'package:flutter/material.dart';
import '../../models/rustler_entity.dart';
import '../../services/entity_service.dart';

class EnergyFlowScreen extends StatelessWidget {
  const EnergyFlowScreen({super.key});
  RustlerEntity? _find(Map<String, RustlerEntity> m, List<String> terms) {
    for (final e in m.values) {
      final h = '${e.id} ${e.name}'.toLowerCase();
      if (terms.every(h.contains)) return e;
    }
    return null;
  }

  String _v(RustlerEntity? e, String fallback) =>
      e == null ? '--' : '${e.value}${e.unit == null ? '' : ' ${e.unit}'}';
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('RigOS Energy Flow')),
      body: ValueListenableBuilder<Map<String, RustlerEntity>>(
          valueListenable: EntityService.instance.entities,
          builder: (_, m, __) {
            final solar =
                _find(m, ['solar', 'power']) ?? _find(m, ['pv', 'power']);
            final soc = _find(m, ['soc']);
            final batt = _find(m, ['battery', 'voltage']);
            final inverter =
                _find(m, ['inverter', 'power']) ?? _find(m, ['load', 'power']);
            final dc = _find(m, ['dc', 'power']);
            return ListView(padding: const EdgeInsets.all(20), children: [
              const Text('UNIVERSAL POWER FLOW',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2)),
              const SizedBox(height: 6),
              const Text(
                  'Cards bind to normalized RigOS entities, not a specific manufacturer.',
                  style: TextStyle(color: Colors.white60)),
              const SizedBox(height: 24),
              Center(
                  child: _Node(
                      icon: Icons.solar_power,
                      title: 'SOLAR',
                      value: _v(solar, '--'))),
              const Center(child: Icon(Icons.south, size: 34)),
              Row(children: [
                Expanded(
                    child: _Node(
                        icon: Icons.electric_bolt,
                        title: 'DC-DC / DC',
                        value: _v(dc, '--'))),
                const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.east, size: 30)),
                Expanded(
                    child: _Node(
                        icon: Icons.battery_charging_full,
                        title: 'BATTERY',
                        value: '${_v(soc, '--')}  •  ${_v(batt, '--')}'))
              ]),
              const Center(child: Icon(Icons.south, size: 34)),
              Center(
                  child: _Node(
                      icon: Icons.power,
                      title: 'INVERTER / LOAD',
                      value: _v(inverter, '--'))),
              const SizedBox(height: 22),
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                          '${m.length} normalized entities currently published. Victron, SRNE, ESP, BMS and future adapters can all feed this same flow layer.'))),
            ]);
          }));
}

class _Node extends StatelessWidget {
  final IconData icon;
  final String title, value;
  const _Node({required this.icon, required this.title, required this.value});
  @override
  Widget build(BuildContext context) => Container(
      constraints: const BoxConstraints(minWidth: 220),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: const Color(0xFF11171A),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF314047))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 34),
        const SizedBox(height: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 11, color: Colors.white60, letterSpacing: 1.2)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))
      ]));
}
