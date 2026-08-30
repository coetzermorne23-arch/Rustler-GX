import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../services/gps_service.dart';
import '../../services/media_launcher_service.dart';

import 'driving_screen.dart';
import 'offline_navigation_screen.dart';

class HeadUnitHomeScreen extends StatefulWidget {
  const HeadUnitHomeScreen({
    super.key,
  });

  @override
  State<HeadUnitHomeScreen> createState() => _HeadUnitHomeScreenState();
}

class _HeadUnitHomeScreenState extends State<HeadUnitHomeScreen> {
  final GpsService gps = GpsService.instance;

  final MediaLauncherService media = MediaLauncherService.instance;

  int selectedPage = 0;

  Timer? clockTimer;

  DateTime now = DateTime.now();

  @override
  void initState() {
    super.initState();

    gps.start();

    clockTimer = Timer.periodic(
      const Duration(
        seconds: 1,
      ),
      (_) {
        if (!mounted) {
          return;
        }

        setState(() {
          now = DateTime.now();
        });
      },
    );
  }

  @override
  void dispose() {
    clockTimer?.cancel();

    super.dispose();
  }

  String _twoDigits(
    int value,
  ) {
    return value.toString().padLeft(
          2,
          '0',
        );
  }

  String get timeText {
    return '${_twoDigits(now.hour)}:'
        '${_twoDigits(now.minute)}';
  }

  String get dateText {
    const List<String> months = <String>[
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];

    return '${now.day} '
        '${months[now.month - 1]} '
        '${now.year}';
  }

  double _speedKmh(
    Position? position,
  ) {
    if (position == null || position.speed < 0) {
      return 0;
    }

    return position.speed * 3.6;
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

  void _openDriving() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (
          context,
        ) {
          return const DrivingScreen();
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
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: IndexedStack(
                index: selectedPage,
                children: [
                  _buildHome(),
                  const OfflineNavigationScreen(),
                  const DrivingScreen(),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
      ),
      decoration: const BoxDecoration(
        color: Color(
          0xFF101518,
        ),
        border: Border(
          bottom: BorderSide(
            color: Color(
              0xFF263238,
            ),
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.directions_car_filled,
            size: 32,
          ),
          const SizedBox(
            width: 12,
          ),
          const Text(
            'RUSTLER GX',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          ValueListenableBuilder<Position?>(
            valueListenable: gps.position,
            builder: (
              context,
              position,
              child,
            ) {
              return Row(
                children: [
                  Icon(
                    position == null ? Icons.gps_off : Icons.gps_fixed,
                    size: 20,
                  ),
                  const SizedBox(
                    width: 7,
                  ),
                  Text(
                    position == null
                        ? 'GPS'
                        : '${_speedKmh(position).round()} km/h',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(
            width: 28,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeText,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                dateText,
                style: const TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHome() {
    return Padding(
      padding: const EdgeInsets.all(
        22,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: _buildDrivePanel(),
          ),
          const SizedBox(
            width: 20,
          ),
          Expanded(
            flex: 4,
            child: _buildLauncherPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildDrivePanel() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(
          0xFF11171A,
        ),
        borderRadius: BorderRadius.circular(
          24,
        ),
        border: Border.all(
          color: const Color(
            0xFF263238,
          ),
        ),
      ),
      child: ValueListenableBuilder<Position?>(
        valueListenable: gps.position,
        builder: (
          context,
          position,
          child,
        ) {
          final double speed = _speedKmh(
            position,
          );

          return InkWell(
            borderRadius: BorderRadius.circular(
              24,
            ),
            onTap: _openNavigation,
            child: Padding(
              padding: const EdgeInsets.all(
                28,
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.navigation,
                        size: 30,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        'DRIVE',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    speed.toStringAsFixed(
                      0,
                    ),
                    style: const TextStyle(
                      fontSize: 118,
                      height: 0.9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  const Text(
                    'km/h',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white54,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniInfo(
                          title: 'GPS',
                          value: position == null ? 'WAITING' : 'LOCKED',
                        ),
                      ),
                      Expanded(
                        child: _MiniInfo(
                          title: 'HEADING',
                          value: position == null
                              ? '--'
                              : '${position.heading.round()}°',
                        ),
                      ),
                      Expanded(
                        child: _MiniInfo(
                          title: 'ALTITUDE',
                          value: position == null
                              ? '--'
                              : '${position.altitude.round()} m',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLauncherPanel() {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _LauncherButton(
                  icon: Icons.navigation,
                  title: 'NAVIGATION',
                  subtitle: 'Offline maps',
                  onTap: _openNavigation,
                ),
              ),
              const SizedBox(
                width: 14,
              ),
              Expanded(
                child: _LauncherButton(
                  icon: Icons.music_note,
                  title: 'MUSIC',
                  subtitle: 'YouTube Music',
                  onTap: _openMusic,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(
          height: 14,
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _LauncherButton(
                  icon: Icons.speed,
                  title: 'DRIVE',
                  subtitle: 'GPS telemetry',
                  onTap: _openDriving,
                ),
              ),
              const SizedBox(
                width: 14,
              ),
              Expanded(
                child: _LauncherButton(
                  icon: Icons.dashboard_customize,
                  title: 'GX',
                  subtitle: 'Vehicle systems',
                  onTap: () {
                    Navigator.of(
                      context,
                    ).pop();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      height: 74,
      decoration: const BoxDecoration(
        color: Color(
          0xFF101518,
        ),
        border: Border(
          top: BorderSide(
            color: Color(
              0xFF263238,
            ),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _BottomButton(
            icon: Icons.home,
            label: 'HOME',
            selected: selectedPage == 0,
            onTap: () {
              setState(() {
                selectedPage = 0;
              });
            },
          ),
          _BottomButton(
            icon: Icons.map,
            label: 'MAP',
            selected: selectedPage == 1,
            onTap: () {
              setState(() {
                selectedPage = 1;
              });
            },
          ),
          _BottomButton(
            icon: Icons.speed,
            label: 'DRIVE',
            selected: selectedPage == 2,
            onTap: () {
              setState(() {
                selectedPage = 2;
              });
            },
          ),
          _BottomButton(
            icon: Icons.music_note,
            label: 'MUSIC',
            selected: false,
            onTap: _openMusic,
          ),
          _BottomButton(
            icon: Icons.dashboard_customize,
            label: 'GX',
            selected: false,
            onTap: () {
              Navigator.of(
                context,
              ).pop();
            },
          ),
        ],
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final String title;
  final String value;

  const _MiniInfo({
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
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(
          height: 5,
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _LauncherButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _LauncherButton({
    required this.icon,
    required this.title,
    required this.subtitle,
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
        20,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(
          20,
        ),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(
            20,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              20,
            ),
            border: Border.all(
              color: const Color(
                0xFF263238,
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 50,
              ),
              const SizedBox(
                height: 14,
              ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(
                height: 4,
              ),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BottomButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return SizedBox(
      width: 110,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 27,
              color: selected
                  ? Theme.of(
                      context,
                    ).colorScheme.primary
                  : Colors.white70,
            ),
            const SizedBox(
              height: 4,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: selected
                    ? Theme.of(
                        context,
                      ).colorScheme.primary
                    : Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
