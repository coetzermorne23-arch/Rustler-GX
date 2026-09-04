import 'package:flutter/material.dart';

import '../../models/obd_dashboard_config.dart';
import '../../services/obd_dashboard_config_service.dart';

class ObdDashboardSettingsScreen extends StatefulWidget {
  const ObdDashboardSettingsScreen({super.key});

  @override
  State<ObdDashboardSettingsScreen> createState() =>
      _ObdDashboardSettingsScreenState();
}

class _ObdDashboardSettingsScreenState
    extends State<ObdDashboardSettingsScreen> {
  final ObdDashboardConfigService settings = ObdDashboardConfigService.instance;

  static const Map<String, String> labels = <String, String>{
    'boost': 'Turbo boost',
    'coolant': 'Coolant temperature',
    'rpm': 'Engine RPM',
    'voltage': 'Battery / charging voltage',
    'oil_pressure': 'Oil pressure (only when available)',
    'vehicle_speed': 'OBD vehicle speed',
    'gps_speed': 'GPS speed',
    'engine_load': 'Engine load',
    'throttle': 'Throttle',
    'map': 'Manifold absolute pressure',
    'intake': 'Intake air temperature',
    'maf': 'Mass air flow',
    'fuel_rate': 'Fuel rate',
    'fuel_consumption': 'Trip fuel consumption',
    'trip_fuel': 'Trip fuel used',
  };

  @override
  void initState() {
    super.initState();
    settings.initialise();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OBD dashboard setup')),
      body: ValueListenableBuilder<ObdDashboardConfig>(
        valueListenable: settings.config,
        builder: (context, config, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              const Text(
                'DISPLAY STYLE',
                style:
                    TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.4),
              ),
              const SizedBox(height: 10),
              SegmentedButton<ObdDashboardStyle>(
                segments: const <ButtonSegment<ObdDashboardStyle>>[
                  ButtonSegment<ObdDashboardStyle>(
                    value: ObdDashboardStyle.gauges,
                    icon: Icon(Icons.speed),
                    label: Text('DIALS'),
                  ),
                  ButtonSegment<ObdDashboardStyle>(
                    value: ObdDashboardStyle.cards,
                    icon: Icon(Icons.grid_view_rounded),
                    label: Text('CARDS'),
                  ),
                ],
                selected: <ObdDashboardStyle>{config.style},
                onSelectionChanged: (Set<ObdDashboardStyle> value) {
                  settings.setStyle(value.first);
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'VISIBLE DATA',
                style:
                    TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.4),
              ),
              const SizedBox(height: 8),
              const Text(
                'Drag to reorder. Unsupported PIDs stay visible as -- instead of inventing data.',
                style: TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 12),
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: config.metricIds.length,
                onReorder: (int oldIndex, int newIndex) {
                  final List<String> ids = List<String>.from(config.metricIds);
                  if (newIndex > oldIndex) newIndex--;
                  final String moved = ids.removeAt(oldIndex);
                  ids.insert(newIndex, moved);
                  settings.setMetrics(ids);
                },
                itemBuilder: (context, index) {
                  final String id = config.metricIds[index];
                  return ListTile(
                    key: ValueKey<String>(id),
                    leading: const Icon(Icons.drag_handle),
                    title: Text(labels[id] ?? id),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () {
                        final List<String> ids =
                            List<String>.from(config.metricIds)..remove(id);
                        settings.setMetrics(ids);
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final String? id = await showModalBottomSheet<String>(
                    context: context,
                    builder: (context) {
                      final List<String> missing = labels.keys
                          .where((String id) => !config.metricIds.contains(id))
                          .toList();
                      return SafeArea(
                        child: ListView(
                          shrinkWrap: true,
                          children: missing
                              .map((String id) => ListTile(
                                    title: Text(labels[id] ?? id),
                                    onTap: () => Navigator.of(context).pop(id),
                                  ))
                              .toList(),
                        ),
                      );
                    },
                  );
                  if (id != null) {
                    settings.setMetrics(<String>[...config.metricIds, id]);
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('ADD DATA CARD'),
              ),
              TextButton(
                onPressed: settings.reset,
                child: const Text('RESET DEFAULT DASHBOARD'),
              ),
            ],
          );
        },
      ),
    );
  }
}
