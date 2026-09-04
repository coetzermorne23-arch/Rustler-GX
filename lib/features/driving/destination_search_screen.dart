import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/navigation_place.dart';
import '../../services/gps_service.dart';
import '../../services/navigation_place_service.dart';
import '../../services/navigation_service.dart';
import '../../services/offline_geocoder_service.dart';
import '../../services/osm_search_service.dart';

class DestinationSearchScreen extends StatefulWidget {
  const DestinationSearchScreen({super.key});
  @override
  State<DestinationSearchScreen> createState() =>
      _DestinationSearchScreenState();
}

class _DestinationSearchScreenState extends State<DestinationSearchScreen> {
  final places = NavigationPlaceService.instance;
  final geocoder = OfflineGeocoderService.instance;
  final osm = OsmSearchService.instance;
  final navigation = NavigationService.instance;
  final gps = GpsService.instance;
  final controller = TextEditingController();
  List<NavigationPlace> results = const [];
  bool loading = true;
  bool searching = false;
  Timer? debounce;
  int generation = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await places.initialise();
    await geocoder.initialise();
    if (mounted) setState(() => loading = false);
  }

  void _changed(String value) {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 220), () => _search(value));
    setState(() {});
  }

  Future<void> _search(String value) async {
    final query = value.trim();
    final current = ++generation;
    if (query.isEmpty) {
      if (mounted)
        setState(() {
          results = const [];
          searching = false;
        });
      return;
    }
    if (mounted) {
      setState(() => searching = true);
    }
    final pos = gps.position.value;
    final offline = await geocoder.search(
      query,
      latitude: pos?.latitude,
      longitude: pos?.longitude,
    );
    List<NavigationPlace> saved = const [];
    try {
      saved = await places.search(query);
    } catch (_) {}
    // Online OpenStreetMap/Nominatim fills the gap when the local search DB is
    // absent or incomplete. Maps and saved routes remain offline-capable.
    final online = await osm.search(
      query,
      latitude: pos?.latitude,
      longitude: pos?.longitude,
    );
    if (!mounted || current != generation || controller.text.trim() != query) {
      return;
    }
    final merged = <String, NavigationPlace>{};
    for (final p in [...saved, ...offline, ...online]) {
      merged.putIfAbsent(
        '${p.name.toLowerCase()}|${p.latitude.toStringAsFixed(5)}|${p.longitude.toStringAsFixed(5)}',
        () => p,
      );
    }
    setState(() {
      results = merged.values.take(50).toList();
      searching = false;
    });
  }

  Future<void> _import() async {
    try {
      await geocoder.chooseDatabase();
      if (!mounted) {
        return;
      }
      setState(() {});
      if (controller.text.trim().isNotEmpty) await _search(controller.text);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'SA offline search loaded: ${geocoder.placeCount.value} entries'),
      ));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(geocoder.error.value ?? 'Could not import search DB'),
      ));
    }
  }

  Future<void> _select(NavigationPlace place) async {
    await navigation.selectDestination(place);
    if (mounted) Navigator.of(context).pop(place);
  }

  @override
  void dispose() {
    debounce?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Where to?'),
        actions: [
          IconButton(
            tooltip: 'Import SA offline search database',
            onPressed: _import,
            icon: const Icon(Icons.storage_rounded),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  onChanged: _changed,
                  style: const TextStyle(fontSize: 20),
                  decoration: InputDecoration(
                    hintText: geocoder.ready.value
                        ? 'Address, street, suburb, town or place...'
                        : 'Import SA search DB for offline addresses',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: controller.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              controller.clear();
                              _changed('');
                            },
                            icon: const Icon(Icons.clear),
                          ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              InkWell(
                onTap: _import,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                  child: Row(children: [
                    Icon(
                        geocoder.ready.value
                            ? Icons.offline_pin
                            : Icons.storage_outlined,
                        size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(
                      geocoder.error.value ??
                          (geocoder.ready.value
                              ? 'SA OFFLINE SEARCH • ${geocoder.placeCount.value} indexed entries'
                              : 'Offline DB not installed • online OSM search active when connected'),
                      style: TextStyle(
                          fontSize: 11,
                          color: geocoder.error.value == null
                              ? Colors.white60
                              : Colors.orangeAccent),
                    )),
                  ]),
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  children: [
                    for (final item in const <(String, IconData)>[
                      ('fuel', Icons.local_gas_station),
                      ('supermarket', Icons.shopping_cart),
                      ('hospital', Icons.local_hospital),
                      ('restaurant', Icons.restaurant),
                      ('camp site', Icons.park_rounded),
                      ('atm', Icons.atm),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          avatar: Icon(item.$2, size: 16),
                          label: Text(item.$1.toUpperCase()),
                          onPressed: () {
                            controller.text = item.$1;
                            _search(item.$1);
                          },
                        ),
                      ),
                  ],
                ),
              ),
              if (searching) const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: controller.text.trim().isEmpty
                    ? Center(
                        child: Padding(
                        padding: const EdgeInsets.all(24),
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.travel_explore, size: 64),
                          const SizedBox(height: 14),
                          Text(
                            geocoder.ready.value
                                ? 'Search South Africa completely offline'
                                : 'Build and import south_africa_search.sqlite once',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          if (!geocoder.ready.value) ...[
                            const SizedBox(height: 16),
                            FilledButton.icon(
                                onPressed: _import,
                                icon: const Icon(Icons.folder_open),
                                label: const Text('IMPORT SEARCH DATABASE')),
                          ],
                        ]),
                      ))
                    : results.isEmpty && !searching
                        ? const Center(
                            child: Text(
                                'No offline results. Try fewer words or the street name first.',
                                textAlign: TextAlign.center))
                        : ListView.separated(
                            itemCount: results.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final p = results[i];
                              return ListTile(
                                leading: const Icon(Icons.location_on_outlined),
                                title: Text(p.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                subtitle: Text(
                                    '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => _select(p),
                              );
                            },
                          ),
              ),
            ]),
    );
  }
}
