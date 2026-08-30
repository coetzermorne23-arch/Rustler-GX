import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/navigation_place.dart';
import '../../services/gps_service.dart';
import '../../services/navigation_place_service.dart';
import '../../services/navigation_service.dart';

class DestinationSearchScreen extends StatefulWidget {
  const DestinationSearchScreen({
    super.key,
  });

  @override
  State<DestinationSearchScreen> createState() =>
      _DestinationSearchScreenState();
}

class _DestinationSearchScreenState extends State<DestinationSearchScreen> {
  final NavigationPlaceService places = NavigationPlaceService.instance;

  final NavigationService navigation = NavigationService.instance;

  final GpsService gps = GpsService.instance;

  final TextEditingController controller = TextEditingController();

  List<NavigationPlace> results = <NavigationPlace>[];

  bool loading = true;

  @override
  void initState() {
    super.initState();

    _initialise();
  }

  Future<void> _initialise() async {
    await places.initialise();

    if (!mounted) {
      return;
    }

    setState(() {
      loading = false;
    });
  }

  // =========================================================
  // SEARCH
  // =========================================================

  Future<void> _search(
    String value,
  ) async {
    final String query = value.trim();

    if (query.isEmpty) {
      if (!mounted) {
        return;
      }

      setState(() {
        results = <NavigationPlace>[];
      });

      return;
    }

    final List<NavigationPlace> found = await places.search(
      query,
    );

    if (!mounted) {
      return;
    }

    // User may have typed another character while the
    // previous async search was still running.
    if (controller.text.trim() != query) {
      return;
    }

    setState(() {
      results = found;
    });
  }

  // =========================================================
  // SELECT DESTINATION
  // =========================================================

  Future<void> _select(
    NavigationPlace place,
  ) async {
    await navigation.selectDestination(
      place,
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(
      place,
    );
  }

  // =========================================================
  // SAVE CURRENT GPS POSITION
  // =========================================================

  Future<void> _saveCurrentPosition() async {
    Position? position = gps.position.value;

    position ??= await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
      ),
    );

    if (!mounted) {
      return;
    }

    final NavigationPlace? place = await showDialog<NavigationPlace>(
      context: context,
      builder: (
        context,
      ) {
        return _SavePlaceDialog(
          latitude: position!.latitude,
          longitude: position.longitude,
        );
      },
    );

    if (place == null) {
      return;
    }

    await places.addPlace(
      name: place.name,
      latitude: place.latitude,
      longitude: place.longitude,
    );

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  // =========================================================
  // UI
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Where to?',
        ),
        actions: [
          IconButton(
            tooltip: 'Save current position',
            onPressed: _saveCurrentPosition,
            icon: const Icon(
              Icons.add_location_alt,
            ),
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                // =================================================
                // SEARCH BAR
                // =================================================

                Padding(
                  padding: const EdgeInsets.all(
                    16,
                  ),
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    onChanged: _search,
                    style: const TextStyle(
                      fontSize: 20,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search destination...',
                      prefixIcon: const Icon(
                        Icons.search,
                      ),
                      suffixIcon: controller.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                controller.clear();

                                _search(
                                  '',
                                );
                              },
                              icon: const Icon(
                                Icons.clear,
                              ),
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          14,
                        ),
                      ),
                    ),
                  ),
                ),

                // =================================================
                // SAVED / SEARCH RESULTS
                // =================================================

                if (controller.text.trim().isEmpty)
                  Expanded(
                    child: _SavedPlaces(
                      places: places,
                      onSelect: _select,
                    ),
                  )
                else
                  Expanded(
                    child: _SearchResults(
                      results: results,
                      onSelect: _select,
                    ),
                  ),
              ],
            ),
    );
  }
}

// =============================================================
// SAVED PLACES
// =============================================================

class _SavedPlaces extends StatelessWidget {
  final NavigationPlaceService places;

  final Future<void> Function(
    NavigationPlace place,
  ) onSelect;

  const _SavedPlaces({
    required this.places,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<NavigationPlace>>(
      valueListenable: places.favourites,
      builder: (
        context,
        favourites,
        child,
      ) {
        return ValueListenableBuilder<List<NavigationPlace>>(
          valueListenable: places.recent,
          builder: (
            context,
            recent,
            child,
          ) {
            if (favourites.isEmpty && recent.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 65,
                    ),
                    SizedBox(
                      height: 14,
                    ),
                    Text(
                      'No saved destinations yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      height: 6,
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                      ),
                      child: Text(
                        'Use the location button to save your current position.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                16,
                0,
                16,
                24,
              ),
              children: [
                // =============================================
                // FAVOURITES
                // =============================================

                if (favourites.isNotEmpty) ...[
                  const _SectionTitle(
                    title: 'Saved',
                  ),
                  ...favourites.map(
                    (
                      NavigationPlace place,
                    ) =>
                        _PlaceTile(
                      place: place,
                      onTap: () {
                        onSelect(
                          place,
                        );
                      },
                    ),
                  ),
                ],

                // =============================================
                // RECENT
                // =============================================

                if (recent.isNotEmpty) ...[
                  const SizedBox(
                    height: 18,
                  ),
                  const _SectionTitle(
                    title: 'Recent',
                  ),
                  ...recent.map(
                    (
                      NavigationPlace place,
                    ) =>
                        _PlaceTile(
                      place: place,
                      onTap: () {
                        onSelect(
                          place,
                        );
                      },
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

// =============================================================
// SEARCH RESULTS
// =============================================================

class _SearchResults extends StatelessWidget {
  final List<NavigationPlace> results;

  final Future<void> Function(
    NavigationPlace place,
  ) onSelect;

  const _SearchResults({
    required this.results,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const Center(
        child: Text(
          'No offline destinations found',
          style: TextStyle(
            fontSize: 17,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        24,
      ),
      itemCount: results.length,
      itemBuilder: (
        context,
        index,
      ) {
        final NavigationPlace place = results[index];

        return _PlaceTile(
          place: place,
          onTap: () {
            onSelect(
              place,
            );
          },
        );
      },
    );
  }
}

// =============================================================
// PLACE TILE
// =============================================================

class _PlaceTile extends StatelessWidget {
  final NavigationPlace place;

  final VoidCallback onTap;

  const _PlaceTile({
    required this.place,
    required this.onTap,
  });

  IconData get icon {
    if (place.isHome) {
      return Icons.home;
    }

    if (place.isWork) {
      return Icons.work;
    }

    if (place.favourite) {
      return Icons.star;
    }

    return Icons.location_on;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        minTileHeight: 68,
        leading: Icon(
          icon,
          size: 30,
        ),
        title: Text(
          place.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: place.address == null || place.address!.isEmpty
            ? Text(
                '${place.latitude.toStringAsFixed(5)}, '
                '${place.longitude.toStringAsFixed(5)}',
              )
            : Text(
                place.address!,
              ),
        trailing: const Icon(
          Icons.chevron_right,
        ),
        onTap: onTap,
      ),
    );
  }
}

// =============================================================
// SECTION TITLE
// =============================================================

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 8,
      ),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

// =============================================================
// SAVE PLACE DIALOG
// =============================================================

class _SavePlaceDialog extends StatefulWidget {
  final double latitude;

  final double longitude;

  const _SavePlaceDialog({
    required this.latitude,
    required this.longitude,
  });

  @override
  State<_SavePlaceDialog> createState() => _SavePlaceDialogState();
}

class _SavePlaceDialogState extends State<_SavePlaceDialog> {
  final TextEditingController name = TextEditingController();

  bool favourite = true;

  bool home = false;

  bool work = false;

  @override
  void dispose() {
    name.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Save location',
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ===============================================
            // NAME
            // ===============================================

            TextField(
              controller: name,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Camp, Home, Workshop...',
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            // ===============================================
            // FAVOURITE
            // ===============================================

            CheckboxListTile(
              value: favourite,
              onChanged: (value) {
                setState(() {
                  favourite = value ?? false;
                });
              },
              title: const Text(
                'Favourite',
              ),
            ),

            // ===============================================
            // HOME
            // ===============================================

            CheckboxListTile(
              value: home,
              onChanged: (value) {
                setState(() {
                  home = value ?? false;

                  if (home) {
                    work = false;
                    favourite = true;
                  }
                });
              },
              title: const Text(
                'Set as Home',
              ),
            ),

            // ===============================================
            // WORK
            // ===============================================

            CheckboxListTile(
              value: work,
              onChanged: (value) {
                setState(() {
                  work = value ?? false;

                  if (work) {
                    home = false;
                    favourite = true;
                  }
                });
              },
              title: const Text(
                'Set as Work',
              ),
            ),
          ],
        ),
      ),
      actions: [
        // ===============================================
        // CANCEL
        // ===============================================

        TextButton(
          onPressed: () {
            Navigator.of(
              context,
            ).pop();
          },
          child: const Text(
            'CANCEL',
          ),
        ),

        // ===============================================
        // SAVE
        // ===============================================

        FilledButton(
          onPressed: () {
            final String placeName = name.text.trim();

            if (placeName.isEmpty) {
              return;
            }

            Navigator.of(
              context,
            ).pop(
              NavigationPlace(
                name: placeName,
                latitude: widget.latitude,
                longitude: widget.longitude,
                favourite: favourite,
                isHome: home,
                isWork: work,
              ),
            );
          },
          child: const Text(
            'SAVE',
          ),
        ),
      ],
    );
  }
}
