import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../services/gps_service.dart';
import '../../services/media_launcher_service.dart';

class DrivingScreen
    extends StatefulWidget {
  const DrivingScreen({
    super.key,
  });

  @override
  State<DrivingScreen> createState() =>
      _DrivingScreenState();
}

class _DrivingScreenState
    extends State<DrivingScreen> {
  final GpsService gps =
      GpsService.instance;

  final MediaLauncherService media =
      MediaLauncherService.instance;

  @override
  void initState() {
    super.initState();

    gps.start();
  }

  double _speedKmh(
    Position position,
  ) {
    final double speed =
        position.speed;

    if (speed < 0) {
      return 0;
    }

    return speed * 3.6;
  }

  String _heading(
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
        ((heading + 22.5) ~/ 45) % 8;

    return directions[index];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ================================================
          // GPS AREA
          // ================================================

          Container(
            color:
                Theme.of(context)
                    .scaffoldBackgroundColor,
            child:
                ValueListenableBuilder<
                    Position?>(
              valueListenable:
                  gps.position,
              builder: (
                context,
                position,
                child,
              ) {
                if (position == null) {
                  return const Center(
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.gps_fixed,
                          size: 70,
                        ),
                        SizedBox(
                          height: 16,
                        ),
                        Text(
                          'WAITING FOR GPS',
                          style:
                              TextStyle(
                            fontSize: 22,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Padding(
                  padding:
                      const EdgeInsets.all(
                    24,
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize:
                                MainAxisSize.min,
                            children: [
                              Text(
                                _speedKmh(
                                  position,
                                ).toStringAsFixed(
                                  0,
                                ),
                                style:
                                    const TextStyle(
                                  fontSize: 110,
                                  height: 0.9,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              const Text(
                                'km/h',
                                style:
                                    TextStyle(
                                  fontSize: 25,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceAround,
                        children: [
                          _GpsValue(
                            title:
                                'HEADING',
                            value:
                                '${_heading(position.heading)} '
                                '${position.heading.toStringAsFixed(0)}°',
                          ),
                          _GpsValue(
                            title:
                                'ALTITUDE',
                            value:
                                '${position.altitude.toStringAsFixed(0)} m',
                          ),
                          _GpsValue(
                            title:
                                'ACCURACY',
                            value:
                                '${position.accuracy.toStringAsFixed(0)} m',
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      Text(
                        '${position.latitude.toStringAsFixed(6)}, '
                        '${position.longitude.toStringAsFixed(6)}',
                        style:
                            const TextStyle(
                          color:
                              Colors.white54,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // ================================================
          // YOUTUBE MUSIC OVERLAY
          // ================================================

          Positioned(
            left: 18,
            top: 18,
            width: 250,
            child: Card(
              child: InkWell(
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
                onTap: () async {
                  try {
                    await media
                        .openYouTubeMusic();
                  } catch (_) {
                    if (!context.mounted) {
                      return;
                    }

                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'YouTube Music could not be opened.',
                        ),
                      ),
                    );
                  }
                },
                child: const Padding(
                  padding:
                      EdgeInsets.all(
                    14,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.music_note,
                        size: 36,
                      ),
                      SizedBox(
                        width: 12,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              'YouTube Music',
                              style:
                                  TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            SizedBox(
                              height: 3,
                            ),
                            Text(
                              'Tap to open',
                              style:
                                  TextStyle(
                                color:
                                    Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons
                            .open_in_new,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ================================================
          // NEXT DASHBOARD PAGE
          // ================================================

          Positioned(
            right: 20,
            bottom: 20,
            child:
                FloatingActionButton(
              heroTag:
                  'driving_next',
              onPressed: () {
                Navigator.of(context)
                    .pop();
              },
              child: const Icon(
                Icons
                    .dashboard_customize,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GpsValue
    extends StatelessWidget {
  final String title;
  final String value;

  const _GpsValue({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style:
              const TextStyle(
            fontSize: 11,
            color:
                Colors.white54,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(
          height: 4,
        ),
        Text(
          value,
          style:
              const TextStyle(
            fontSize: 18,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ],
    );
  }
}