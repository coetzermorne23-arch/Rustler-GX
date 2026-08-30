import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart'
    as vt;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../models/navigation_place.dart';
import '../../models/navigation_route.dart';
import '../../models/route_instruction.dart';
import '../../services/gps_service.dart';
import '../../services/navigation_service.dart';
import '../../services/vector_offline_map_service.dart';

import 'destination_search_screen.dart';
import 'media_control_card.dart';

class OfflineNavigationScreen extends StatefulWidget {
  const OfflineNavigationScreen({
    super.key,
  });

  @override
  State<OfflineNavigationScreen> createState() =>
      _OfflineNavigationScreenState();
}

class _OfflineNavigationScreenState
    extends State<OfflineNavigationScreen> {
  final GpsService gps =
      GpsService.instance;

  final VectorOfflineMapService maps =
      VectorOfflineMapService.instance;

  final NavigationService navigation =
      NavigationService.instance;

  final MapController mapController =
      MapController();

  bool followVehicle = true;

  bool _mapReady = false;

  @override
  void initState() {
    super.initState();

    gps.position.addListener(
      _gpsChanged,
    );

    navigation.destination.addListener(
      _destinationChanged,
    );

    navigation.route.addListener(
      _routeChanged,
    );

    navigation.navigating.addListener(
      _refresh,
    );

    navigation.calculating.addListener(
      _refresh,
    );

    navigation.currentInstruction.addListener(
      _refresh,
    );

    navigation.offRoute.addListener(
      _refresh,
    );

    navigation.error.addListener(
      _refresh,
    );

    maps.mapPath.addListener(
      _refresh,
    );

    maps.loading.addListener(
      _refresh,
    );

    _initialise();
  }

  Future<void> _initialise() async {
    try {
      await navigation.initialise();
    } catch (error) {
      debugPrint(
        'Navigation initialise error: $error',
      );
    }

    try {
      await maps.loadDefaultMap();
    } catch (error) {
      debugPrint(
        'Map initialise error: $error',
      );
    }

    try {
      await gps.start();
    } catch (error) {
      debugPrint(
        'GPS initialise error: $error',
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  void _refresh() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  void _destinationChanged() {
    _refresh();

    final NavigationPlace? destination =
        navigation.destination.value;

    if (destination == null ||
        !_mapReady) {
      return;
    }

    if (navigation.navigating.value) {
      return;
    }

    followVehicle = false;

    try {
      mapController.move(
        LatLng(
          destination.latitude,
          destination.longitude,
        ),
        16,
      );

      mapController.rotate(
        0,
      );
    } catch (_) {}
  }

  void _routeChanged() {
    _refresh();

    final NavigationRoute? route =
        navigation.route.value;

    if (route == null ||
        route.points.isEmpty ||
        !_mapReady) {
      return;
    }

    if (navigation.navigating.value) {
      _followCurrentPosition();
    }
  }

  void _gpsChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});

    if (!followVehicle ||
        !_mapReady) {
      return;
    }

    _followCurrentPosition(
      updateState: false,
    );
  }

  double _speedKmh(
    Position position,
  ) {
    if (position.speed < 0) {
      return 0;
    }

    return position.speed * 3.6;
  }

  String _headingText(
    double heading,
  ) {
    if (heading < 0) {
      return '--';
    }

    const List<String> directions =
        <String>[
      'N',
      'NE',
      'E',
      'SE',
      'S',
      'SW',
      'W',
      'NW',
    ];

    final int index =
        ((heading + 22.5) ~/ 45) %
            8;

    return directions[index];
  }

  String _formatDistance(
    double metres,
  ) {
    if (metres < 1000) {
      return '${metres.round()} m';
    }

    return '${(metres / 1000).toStringAsFixed(1)} km';
  }

  double? _directDistance(
    Position? position,
    NavigationPlace? destination,
  ) {
    if (position == null ||
        destination == null) {
      return null;
    }

    return Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      destination.latitude,
      destination.longitude,
    );
  }

  void _followCurrentPosition({
    bool updateState = true,
  }) {
    final Position? position =
        gps.position.value;

    if (updateState &&
        mounted) {
      setState(() {
        followVehicle = true;
      });
    } else {
      followVehicle = true;
    }

    if (position == null ||
        !_mapReady) {
      return;
    }

    try {
      mapController.move(
        LatLng(
          position.latitude,
          position.longitude,
        ),
        navigation.navigating.value
            ? 17
            : 16,
      );

      if (position.heading >= 0) {
        mapController.rotate(
          -position.heading,
        );
      }
    } catch (_) {}
  }

  void _showDestination() {
    final NavigationPlace? destination =
        navigation.destination.value;

    if (destination == null ||
        !_mapReady) {
      return;
    }

    setState(() {
      followVehicle = false;
    });

    try {
      mapController.move(
        LatLng(
          destination.latitude,
          destination.longitude,
        ),
        16,
      );

      mapController.rotate(
        0,
      );
    } catch (_) {}
  }

  Future<void> _openDestinationSearch() async {
    final NavigationPlace? selected =
        await Navigator.of(context)
            .push<NavigationPlace>(
      MaterialPageRoute<NavigationPlace>(
        builder: (
          context,
        ) {
          return const DestinationSearchScreen();
        },
      ),
    );

    if (selected == null ||
        !mounted) {
      return;
    }

    setState(() {
      followVehicle = false;
    });

    _showDestination();
  }

  Future<void> _chooseMap() async {
    try {
      await maps.chooseMap();

      if (!mounted) {
        return;
      }

      setState(() {});
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'Map error: $error',
          ),
        ),
      );
    }
  }

  Future<void> _startNavigation() async {
    final bool success =
        await navigation.startNavigation();

    if (!mounted) {
      return;
    }

    if (!success) {
      final String message =
          navigation.error.value ??
              'Could not calculate route.';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            message,
          ),
        ),
      );

      return;
    }

    setState(() {
      followVehicle = true;
    });

    _followCurrentPosition();
  }

  void _cancelNavigation() {
    navigation.stopNavigation();

    setState(() {
      followVehicle = true;
    });

    _followCurrentPosition();
  }

  IconData _instructionIcon(
    RouteInstructionType type,
  ) {
    switch (type) {
      case RouteInstructionType.start:
        return Icons.navigation;

      case RouteInstructionType.straight:
        return Icons.straight;

      case RouteInstructionType.slightLeft:
        return Icons.turn_slight_left;

      case RouteInstructionType.left:
        return Icons.turn_left;

      case RouteInstructionType.sharpLeft:
        return Icons.turn_sharp_left;

      case RouteInstructionType.slightRight:
        return Icons.turn_slight_right;

      case RouteInstructionType.right:
        return Icons.turn_right;

      case RouteInstructionType.sharpRight:
        return Icons.turn_sharp_right;

      case RouteInstructionType.uTurn:
        return Icons.u_turn_left;

      case RouteInstructionType.arrive:
        return Icons.flag;
    }
  }

  @override
  void dispose() {
    gps.position.removeListener(
      _gpsChanged,
    );

    navigation.destination.removeListener(
      _destinationChanged,
    );

    navigation.route.removeListener(
      _routeChanged,
    );

    navigation.navigating.removeListener(
      _refresh,
    );

    navigation.calculating.removeListener(
      _refresh,
    );

    navigation.currentInstruction.removeListener(
      _refresh,
    );

    navigation.offRoute.removeListener(
      _refresh,
    );

    navigation.error.removeListener(
      _refresh,
    );

    maps.mapPath.removeListener(
      _refresh,
    );

    maps.loading.removeListener(
      _refresh,
    );

    mapController.dispose();

    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final NavigationPlace? destination =
        navigation.destination.value;

    final NavigationRoute? route =
        navigation.route.value;

    final RouteInstruction? instruction =
        navigation.currentInstruction.value;

    final bool navigating =
        navigation.navigating.value;

    final bool calculating =
        navigation.calculating.value;

    final Position? position =
        gps.position.value;

    final double? direct =
        _directDistance(
      position,
      destination,
    );

    return Scaffold(
      body: ValueListenableBuilder<String?>(
        valueListenable:
            maps.mapPath,
        builder: (
          context,
          mapPath,
          child,
        ) {
          if (maps.loading.value) {
            return const _MapLoadingScreen();
          }

          if (mapPath == null ||
              !maps.ready) {
            return _NoOfflineMap(
              error:
                  maps.error.value,
              onChooseMap:
                  _chooseMap,
            );
          }

          final LatLng initialCenter =
              position == null
                  ? const LatLng(
                      -30.5595,
                      22.9375,
                    )
                  : LatLng(
                      position.latitude,
                      position.longitude,
                    );

          return Stack(
            children: [
              // ==========================================
              // OFFLINE SOUTH AFRICA VECTOR MAP
              // ==========================================

              Positioned.fill(
                child: FlutterMap(
                  mapController:
                      mapController,
                  options:
                      MapOptions(
                    initialCenter:
                        initialCenter,
                    initialZoom:
                        position == null
                            ? 5.2
                            : 15,
                    minZoom:
                        3,
                    maxZoom:
                        19,
                    onMapReady:
                        () {
                      _mapReady = true;

                      if (navigating) {
                        _followCurrentPosition();
                      } else if (destination !=
                          null) {
                        _showDestination();
                      } else if (position !=
                          null) {
                        _followCurrentPosition();
                      }
                    },
                    onPositionChanged:
                        (
                      camera,
                      hasGesture,
                    ) {
                      if (hasGesture &&
                          followVehicle) {
                        setState(() {
                          followVehicle =
                              false;
                        });
                      }
                    },
                  ),
                  children: [
                    // ====================================
                    // VECTOR MBTILES
                    // ====================================

                    vt.VectorTileLayer(
                      theme:
                          maps.style!.theme,
                      tileProviders:
                          maps.style!.providers,
                      rasterSources:
                          maps.style!.rasterSources,
                      sprites:
                          maps.style!.sprites,
                    ),

                    // ====================================
                    // ROUTE
                    // ====================================

                    if (route != null &&
                        route.points.length >=
                            2)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points:
                                route.points
                                    .map(
                                      (
                                        point,
                                      ) =>
                                          LatLng(
                                        point.latitude,
                                        point.longitude,
                                      ),
                                    )
                                    .toList(),
                            strokeWidth:
                                7,
                          ),
                        ],
                      ),

                    // ====================================
                    // VEHICLE
                    // ====================================

                    if (position != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point:
                                LatLng(
                              position.latitude,
                              position.longitude,
                            ),
                            width:
                                64,
                            height:
                                64,
                            child:
                                Transform.rotate(
                              angle:
                                  position.heading >=
                                          0
                                      ? position.heading *
                                          0.017453292519943295
                                      : 0,
                              child:
                                  Container(
                                decoration:
                                    BoxDecoration(
                                  shape:
                                      BoxShape.circle,
                                  color:
                                      Colors.black.withValues(
                                    alpha:
                                        0.75,
                                  ),
                                ),
                                child:
                                    const Icon(
                                  Icons.navigation,
                                  size:
                                      42,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                    // ====================================
                    // DESTINATION
                    // ====================================

                    if (destination != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point:
                                LatLng(
                              destination.latitude,
                              destination.longitude,
                            ),
                            width:
                                68,
                            height:
                                68,
                            child:
                                const Icon(
                              Icons.location_on,
                              size:
                                  64,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // ==========================================
              // NEXT TURN
              // ==========================================

              if (navigating &&
                  instruction != null)
                Positioned(
                  left:
                      18,
                  top:
                      18,
                  width:
                      430,
                  child:
                      Card(
                    child:
                        Padding(
                      padding:
                          const EdgeInsets.all(
                        14,
                      ),
                      child:
                          Row(
                        children: [
                          Icon(
                            _instructionIcon(
                              instruction.type,
                            ),
                            size:
                                48,
                          ),

                          const SizedBox(
                            width:
                                14,
                          ),

                          Expanded(
                            child:
                                Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  instruction.text,
                                  maxLines:
                                      2,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style:
                                      const TextStyle(
                                    fontSize:
                                        18,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),

                                if (instruction.distanceMetres >
                                    0)
                                  Text(
                                    _formatDistance(
                                      instruction.distanceMetres,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ==========================================
              // WHERE TO
              // ==========================================

              if (!navigating)
                Positioned(
                  left:
                      18,
                  top:
                      18,
                  width:
                      290,
                  child:
                      FilledButton.icon(
                    onPressed:
                        _openDestinationSearch,
                    icon:
                        const Icon(
                      Icons.search,
                    ),
                    label:
                        Text(
                      destination == null
                          ? 'WHERE TO?'
                          : 'CHANGE DESTINATION',
                    ),
                  ),
                ),

              // ==========================================
              // SPEED
              // ==========================================

              Positioned(
                right:
                    18,
                top:
                    18,
                child:
                    Card(
                  child:
                      Padding(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal:
                          18,
                      vertical:
                          9,
                    ),
                    child:
                        Column(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        Text(
                          position == null
                              ? '--'
                              : _speedKmh(
                                  position,
                                ).toStringAsFixed(
                                  0,
                                ),
                          style:
                              const TextStyle(
                            fontSize:
                                34,
                            height:
                                0.95,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const Text(
                          'km/h',
                          style:
                              TextStyle(
                            fontSize:
                                11,
                          ),
                        ),

                        if (position != null)
                          Text(
                            _headingText(
                              position.heading,
                            ),
                            style:
                                const TextStyle(
                              fontSize:
                                  11,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // ==========================================
              // DESTINATION / ROUTE SUMMARY
              // ==========================================

              if (destination != null)
                Positioned(
                  left:
                      18,
                  top:
                      navigating
                          ? 130
                          : 80,
                  width:
                      350,
                  child:
                      Card(
                    child:
                        Padding(
                      padding:
                          const EdgeInsets.all(
                        14,
                      ),
                      child:
                          Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                              ),

                              const SizedBox(
                                width:
                                    8,
                              ),

                              Expanded(
                                child:
                                    Text(
                                  destination.name,
                                  maxLines:
                                      1,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style:
                                      const TextStyle(
                                    fontSize:
                                        17,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          if (destination.address !=
                                  null &&
                              destination.address!
                                  .isNotEmpty) ...[
                            const SizedBox(
                              height:
                                  4,
                            ),

                            Text(
                              destination.address!,
                              maxLines:
                                  2,
                              overflow:
                                  TextOverflow.ellipsis,
                              style:
                                  const TextStyle(
                                fontSize:
                                    11,
                              ),
                            ),
                          ],

                          const SizedBox(
                            height:
                                10,
                          ),

                          if (route != null)
                            Row(
                              children: [
                                const Icon(
                                  Icons.route,
                                  size:
                                      18,
                                ),

                                const SizedBox(
                                  width:
                                      6,
                                ),

                                Text(
                                  route.distanceText,
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(
                                  width:
                                      18,
                                ),

                                const Icon(
                                  Icons.schedule,
                                  size:
                                      18,
                                ),

                                const SizedBox(
                                  width:
                                      6,
                                ),

                                Text(
                                  route.etaText,
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          else if (direct !=
                              null)
                            Text(
                              '${_formatDistance(direct)} direct',
                            ),

                          if (navigation.offRoute.value) ...[
                            const SizedBox(
                              height:
                                  8,
                            ),

                            const Row(
                              children: [
                                Icon(
                                  Icons.warning_amber,
                                  size:
                                      18,
                                ),

                                SizedBox(
                                  width:
                                      6,
                                ),

                                Expanded(
                                  child:
                                      Text(
                                    'OFF ROUTE — recalculating',
                                    style:
                                        TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          if (navigation.error.value !=
                              null) ...[
                            const SizedBox(
                              height:
                                  8,
                            ),

                            Text(
                              navigation.error.value!,
                              style:
                                  const TextStyle(
                                fontSize:
                                    12,
                              ),
                            ),
                          ],

                          const SizedBox(
                            height:
                                12,
                          ),

                          Row(
                            children: [
                              if (!navigating)
                                Expanded(
                                  child:
                                      FilledButton.icon(
                                    onPressed:
                                        calculating
                                            ? null
                                            : _startNavigation,
                                    icon:
                                        calculating
                                            ? const SizedBox(
                                                width:
                                                    18,
                                                height:
                                                    18,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth:
                                                      2,
                                                ),
                                              )
                                            : const Icon(
                                                Icons.navigation,
                                              ),
                                    label:
                                        Text(
                                      calculating
                                          ? 'CALCULATING'
                                          : 'START',
                                    ),
                                  ),
                                ),

                              if (navigating)
                                Expanded(
                                  child:
                                      FilledButton.icon(
                                    onPressed:
                                        _cancelNavigation,
                                    icon:
                                        const Icon(
                                      Icons.close,
                                    ),
                                    label:
                                        const Text(
                                      'STOP',
                                    ),
                                  ),
                                ),

                              const SizedBox(
                                width:
                                    8,
                              ),

                              IconButton(
                                tooltip:
                                    'Show destination',
                                onPressed:
                                    _showDestination,
                                icon:
                                    const Icon(
                                  Icons.flag,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ==========================================
              // MAP NAME
              // ==========================================

              Positioned(
                top:
                    18,
                left:
                    0,
                right:
                    0,
                child:
                    Center(
                  child:
                      IgnorePointer(
                    child:
                        Card(
                      child:
                          Padding(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal:
                              12,
                          vertical:
                              7,
                        ),
                        child:
                            Row(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.public,
                              size:
                                  16,
                            ),

                            const SizedBox(
                              width:
                                  6,
                            ),

                            const Text(
                              'SOUTH AFRICA • OFFLINE',
                              style:
                                  TextStyle(
                                fontSize:
                                    10,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ==========================================
              // MEDIA
              // ==========================================

              const Positioned(
                left:
                    18,
                bottom:
                    18,
                width:
                    430,
                child:
                    MediaControlCard(),
              ),

              // ==========================================
              // MAP CONTROLS
              // ==========================================

              Positioned(
                right:
                    18,
                bottom:
                    18,
                child:
                    Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    FloatingActionButton.small(
                      heroTag:
                          'map_zoom_in',
                      onPressed:
                          () {
                        final camera =
                            mapController.camera;

                        mapController.move(
                          camera.center,
                          camera.zoom +
                              1,
                        );
                      },
                      child:
                          const Icon(
                        Icons.add,
                      ),
                    ),

                    const SizedBox(
                      height:
                          10,
                    ),

                    FloatingActionButton.small(
                      heroTag:
                          'map_zoom_out',
                      onPressed:
                          () {
                        final camera =
                            mapController.camera;

                        mapController.move(
                          camera.center,
                          camera.zoom -
                              1,
                        );
                      },
                      child:
                          const Icon(
                        Icons.remove,
                      ),
                    ),

                    const SizedBox(
                      height:
                          10,
                    ),

                    FloatingActionButton(
                      heroTag:
                          'follow_vehicle',
                      onPressed:
                          _followCurrentPosition,
                      child:
                          Icon(
                        followVehicle
                            ? Icons.my_location
                            : Icons.location_searching,
                      ),
                    ),

                    if (destination != null) ...[
                      const SizedBox(
                        height:
                            10,
                      ),

                      FloatingActionButton.small(
                        heroTag:
                            'show_destination',
                        onPressed:
                            _showDestination,
                        child:
                            const Icon(
                          Icons.flag,
                        ),
                      ),
                    ],

                    const SizedBox(
                      height:
                          10,
                    ),

                    FloatingActionButton.small(
                      heroTag:
                          'dashboard',
                      onPressed:
                          () {
                        Navigator.of(
                          context,
                        ).pop();
                      },
                      child:
                          const Icon(
                        Icons.dashboard_customize,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================
// MAP LOADING
// ============================================================

class _MapLoadingScreen
    extends StatelessWidget {
  const _MapLoadingScreen();

  @override
  Widget build(
    BuildContext context,
  ) {
    return const Center(
      child:
          Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          CircularProgressIndicator(),

          SizedBox(
            height:
                18,
          ),

          Text(
            'LOADING OFFLINE SOUTH AFRICA MAP...',
            style:
                TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// NO MAP
// ============================================================

class _NoOfflineMap
    extends StatelessWidget {
  final String? error;

  final Future<void> Function()
      onChooseMap;

  const _NoOfflineMap({
    required this.error,
    required this.onChooseMap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Center(
      child:
          Padding(
        padding:
            const EdgeInsets.all(
          24,
        ),
        child:
            Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons.public,
              size:
                  76,
            ),

            const SizedBox(
              height:
                  18,
            ),

            const Text(
              'SOUTH AFRICA OFFLINE MAP',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                fontSize:
                    22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height:
                  10,
            ),

            const SizedBox(
              width:
                  480,
              child:
                  Text(
                'Select the Rustler GX South Africa vector MBTiles map. '
                'After import the map is stored locally on the head unit '
                'and does not require mobile data or Wi-Fi.',
                textAlign:
                    TextAlign.center,
              ),
            ),

            if (error != null) ...[
              const SizedBox(
                height:
                    14,
              ),

              SizedBox(
                width:
                    480,
                child:
                    Text(
                  error!,
                  textAlign:
                      TextAlign.center,
                ),
              ),
            ],

            const SizedBox(
              height:
                  24,
            ),

            FilledButton.icon(
              onPressed:
                  () async {
                await onChooseMap();
              },
              icon:
                  const Icon(
                Icons.folder_open,
              ),
              label:
                  const Text(
                'SELECT SOUTH AFRICA MAP',
              ),
            ),
          ],
        ),
      ),
    );
  }
}