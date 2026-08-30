import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../services/gps_service.dart';
import '../../services/media_launcher_service.dart';

import 'offline_navigation_screen.dart';

class DrivingScreen extends StatefulWidget {
  const DrivingScreen({
    super.key,
  });

  @override
  State<DrivingScreen> createState() => _DrivingScreenState();
}

class _DrivingScreenState extends State<DrivingScreen> {
  final GpsService gps = GpsService.instance;

  final MediaLauncherService media = MediaLauncherService.instance;

  @override
  void initState() {
    super.initState();

    gps.start();
  }

  double _speedKmh(
    Position position,
  ) {
    if (position.speed < 0) {
      return 0;
    }

    return position.speed * 3.6;
  }

  String _heading(
    double heading,
  ) {
    if (heading < 0) {
      return '--';
    }

    const List<String> directions = <String>[
      'N',
      'NE',
      'E',
      'SE',
      'S',
      'SW',
      'W',
      'NW',
    ];

    final int index = ((heading + 22.5) ~/ 45) % 8;

    return directions[index];
  }

  Future<void> _openMusic() async {
    try {
      await media.openYouTubeMusic();
    } catch (_) {
      if (!mounted) {
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
  }

  void _openNavigation() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (
          context,
        ) {
          return const OfflineNavigationScreen();
        },
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF080B0D,
      ),
      body: ValueListenableBuilder<Position?>(
        valueListenable: gps.position,
        builder: (
          context,
          position,
          child,
        ) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: const EdgeInsets.all(
                  24,
                ),
                child: position == null
                    ? _waitingForGps()
                    : _driveDisplay(
                        position,
                      ),
              ),
              Positioned(
                left: 18,
                top: 18,
                child: _ActionButton(
                  icon: Icons.map,
                  label: 'MAP',
                  onTap: _openNavigation,
                ),
              ),
              Positioned(
                left: 18,
                top: 88,
                child: _ActionButton(
                  icon: Icons.music_note,
                  label: 'MUSIC',
                  onTap: _openMusic,
                ),
              ),
              Positioned(
                right: 18,
                top: 18,
                child: _GpsIndicator(
                  locked: position != null,
                ),
              ),
              Positioned(
                right: 18,
                bottom: 18,
                child: FloatingActionButton(
                  heroTag: 'driving_back',
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pop();
                  },
                  child: const Icon(
                    Icons.dashboard_customize,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _waitingForGps() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.gps_fixed,
            size: 80,
          ),
          const SizedBox(
            height: 20,
          ),
          const Text(
            'WAITING FOR GPS',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          ValueListenableBuilder<String?>(
            valueListenable: gps.error,
            builder: (
              context,
              error,
              child,
            ) {
              if (error == null) {
                return const Text(
                  'Acquiring location...',
                  style: TextStyle(
                    color: Colors.white54,
                  ),
                );
              }

              return Text(
                error,
                style: const TextStyle(
                  color: Colors.orangeAccent,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _driveDisplay(
    Position position,
  ) {
    final double speed = _speedKmh(
      position,
    );

    return Column(
      children: [
        const Spacer(),
        Text(
          speed.toStringAsFixed(
            0,
          ),
          style: const TextStyle(
            fontSize: 150,
            height: 0.85,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        const Text(
          'km/h',
          style: TextStyle(
            fontSize: 24,
            color: Colors.white54,
            letterSpacing: 2,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 18,
          ),
          decoration: BoxDecoration(
            color: const Color(
              0xFF11171A,
            ),
            borderRadius: BorderRadius.circular(
              18,
            ),
            border: Border.all(
              color: const Color(
                0xFF263238,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _GpsValue(
                  title: 'HEADING',
                  value: '${_heading(position.heading)} '
                      '${position.heading.toStringAsFixed(0)}°',
                ),
              ),
              Expanded(
                child: _GpsValue(
                  title: 'ALTITUDE',
                  value: '${position.altitude.toStringAsFixed(0)} m',
                ),
              ),
              Expanded(
                child: _GpsValue(
                  title: 'ACCURACY',
                  value: '${position.accuracy.toStringAsFixed(0)} m',
                ),
              ),
              Expanded(
                child: _GpsValue(
                  title: 'LATITUDE',
                  value: position.latitude.toStringAsFixed(
                    5,
                  ),
                ),
              ),
              Expanded(
                child: _GpsValue(
                  title: 'LONGITUDE',
                  value: position.longitude.toStringAsFixed(
                    5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(
          height: 8,
        ),
      ],
    );
  }
}

class _GpsValue extends StatelessWidget {
  final String title;
  final String value;

  const _GpsValue({
    required this.title,
    required this.value,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white54,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(
          height: 5,
        ),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: const Color(
        0xFF11171A,
      ),
      borderRadius: BorderRadius.circular(
        14,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(
          14,
        ),
        onTap: onTap,
        child: Container(
          width: 125,
          height: 56,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              14,
            ),
            border: Border.all(
              color: const Color(
                0xFF263238,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 26,
              ),
              const SizedBox(
                width: 10,
              ),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GpsIndicator extends StatelessWidget {
  final bool locked;

  const _GpsIndicator({
    required this.locked,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFF11171A,
        ),
        borderRadius: BorderRadius.circular(
          14,
        ),
        border: Border.all(
          color: const Color(
            0xFF263238,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            locked ? Icons.gps_fixed : Icons.gps_off,
            size: 18,
          ),
          const SizedBox(
            width: 7,
          ),
          Text(
            locked ? 'GPS LOCK' : 'NO GPS',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
