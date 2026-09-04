import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/gps_display_settings.dart';
import '../../services/gnss_service.dart';
import '../../services/gps_service.dart';

class GpsCustomScreen extends StatefulWidget {
  const GpsCustomScreen({super.key});
  @override
  State<GpsCustomScreen> createState() => _GpsCustomScreenState();
}

class _GpsCustomScreenState extends State<GpsCustomScreen> {
  final gps = GpsService.instance;
  final gnss = GnssService.instance;
  final settings = GpsDisplaySettings.instance;

  static const labels = <String, String>{
    'speed': 'SPEED',
    'heading': 'HEADING',
    'altitude': 'ALTITUDE',
    'accuracy': 'ACCURACY',
    'coordinates': 'COORDINATES',
    'satellites': 'SATELLITES VISIBLE',
    'usedSatellites': 'SATELLITES USED',
    'gps': 'GPS SATELLITES',
    'galileo': 'GALILEO SATELLITES',
    'glonass': 'GLONASS SATELLITES',
    'beidou': 'BEIDOU SATELLITES',
    'bestSignal': 'BEST SATELLITE SIGNAL',
    'timestamp': 'GPS TIMESTAMP',
  };

  @override
  void initState() {
    super.initState();
    unawaited(settings.load());
    gnss.start();
  }

  String value(String key, Position? p) => switch (key) {
        'speed' => p == null
            ? '--'
            : '${(p.speed < 0 ? 0 : p.speed * 3.6).toStringAsFixed(1)} km/h',
        'heading' => p == null ? '--' : '${p.heading.toStringAsFixed(0)}°',
        'altitude' => p == null ? '--' : '${p.altitude.toStringAsFixed(0)} m',
        'accuracy' => p == null ? '--' : '±${p.accuracy.toStringAsFixed(0)} m',
        'coordinates' => p == null
            ? '--'
            : '${p.latitude.toStringAsFixed(6)}, ${p.longitude.toStringAsFixed(6)}',
        'satellites' => '${gnss.satellites.value.length}',
        'usedSatellites' => '${gnss.usedCount}',
        'gps' => '${gnss.count('GPS')}',
        'galileo' => '${gnss.count('GALILEO')}',
        'glonass' => '${gnss.count('GLONASS')}',
        'beidou' => '${gnss.count('BEIDOU')}',
        'bestSignal' =>
          gnss.bestCn0 <= 0 ? '--' : '${gnss.bestCn0.toStringAsFixed(1)} dB-Hz',
        'timestamp' => p == null ? '--' : p.timestamp.toLocal().toString(),
        _ => '--',
      };

  Future<void> customize() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AnimatedBuilder(
        animation: settings,
        builder: (context, __) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .80,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.tune),
                      SizedBox(width: 10),
                      Text(
                        'CUSTOMIZE GPS',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ReorderableListView.builder(
                    itemCount: settings.order.length,
                    onReorder: settings.reorder,
                    itemBuilder: (_, index) {
                      final key = settings.order[index];
                      return SwitchListTile(
                        key: ValueKey(key),
                        secondary: const Icon(Icons.drag_handle),
                        title: Text(labels[key] ?? key),
                        subtitle:
                            const Text('Drag to move • switch to show/hide'),
                        value: settings.enabled(key),
                        onChanged: (v) => settings.setEnabled(key, v),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('GPS / SATELLITES'),
          actions: [
            IconButton(
              onPressed: customize,
              icon: const Icon(Icons.tune),
              tooltip: 'Customize',
            ),
          ],
        ),
        body: AnimatedBuilder(
          animation: Listenable.merge([settings, gnss.satellites]),
          builder: (_, __) => ValueListenableBuilder<Position?>(
            valueListenable: gps.position,
            builder: (_, p, __) {
              final shown = settings.order.where(settings.enabled).toList();
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: shown.length + 1,
                itemBuilder: (_, index) {
                  if (index == shown.length) {
                    return ExpansionTile(
                      title: const Text('SATELLITE DETAIL'),
                      subtitle: Text(
                        '${gnss.satellites.value.length} visible • '
                        '${gnss.usedCount} used in fix',
                      ),
                      children: gnss.satellites.value
                          .map(
                            (s) => ListTile(
                              dense: true,
                              title: Text(
                                '${s.constellationName} • SVID ${s.svid}',
                              ),
                              subtitle: Text(
                                'C/N₀ ${s.cn0.toStringAsFixed(1)} dB-Hz • '
                                'elev ${s.elevation.toStringAsFixed(0)}° • '
                                'az ${s.azimuth.toStringAsFixed(0)}°',
                              ),
                              trailing: s.usedInFix
                                  ? const Icon(Icons.gps_fixed)
                                  : const Icon(Icons.gps_not_fixed),
                            ),
                          )
                          .toList(),
                    );
                  }
                  final key = shown[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.satellite_alt),
                      title: Text(labels[key] ?? key),
                      subtitle: Text(value(key, p)),
                    ),
                  );
                },
              );
            },
          ),
        ),
      );
}
