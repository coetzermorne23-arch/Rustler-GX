import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/media_playback_data.dart';
import '../../services/gps_service.dart';
import '../../services/media_launcher_service.dart';
import '../../services/media_session_service.dart';
import '../../services/head_unit_runtime_service.dart';

import '../dashboard/dashboard_screen.dart';

import 'driving_screen.dart';
import 'offline_navigation_screen.dart';

class HeadUnitHomeScreen extends StatefulWidget {
  const HeadUnitHomeScreen({
    super.key,
  });

  @override
  State<HeadUnitHomeScreen> createState() => _HeadUnitHomeScreenState();
}

class _HeadUnitHomeScreenState extends State<HeadUnitHomeScreen>
    with WidgetsBindingObserver {
  final GpsService gps = GpsService.instance;

  final MediaLauncherService mediaLauncher = MediaLauncherService.instance;

  final MediaSessionService mediaSession = MediaSessionService.instance;

  final HeadUnitRuntimeService runtime = HeadUnitRuntimeService.instance;

  int selectedPage = 0;

  Timer? clockTimer;

  DateTime now = DateTime.now();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(
      this,
    );

    runtime.start();

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
    WidgetsBinding.instance.removeObserver(
      this,
    );

    clockTimer?.cancel();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state == AppLifecycleState.resumed) {
      runtime.resume();
    }
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

  String _durationText(
    int milliseconds,
  ) {
    if (milliseconds <= 0) {
      return '0:00';
    }

    final Duration duration = Duration(
      milliseconds: milliseconds,
    );

    final int minutes = duration.inMinutes;

    final int seconds = duration.inSeconds.remainder(
      60,
    );

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _openMusic() async {
    try {
      await mediaLauncher.openYouTubeMusic();
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

  void _openGx() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const DashboardScreen(),
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
            'RANGER_GX',
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
            child: _buildRightPanel(),
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
            onTap: _openDriving,
            child: Padding(
              padding: const EdgeInsets.all(
                28,
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.speed,
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

  Widget _buildRightPanel() {
    return Column(
      children: [
        Expanded(
          flex: 6,
          child: _buildMediaPanel(),
        ),
        const SizedBox(
          height: 14,
        ),
        Expanded(
          flex: 4,
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
                  icon: Icons.dashboard_customize,
                  title: 'GX',
                  subtitle: 'Vehicle systems',
                  onTap: _openGx,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMediaPanel() {
    return ValueListenableBuilder<bool>(
      valueListenable: mediaSession.notificationAccess,
      builder: (
        context,
        hasAccess,
        child,
      ) {
        if (!hasAccess) {
          return _buildMediaPermissionPanel();
        }

        return ValueListenableBuilder<MediaPlaybackData>(
          valueListenable: mediaSession.playback,
          builder: (
            context,
            playback,
            child,
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
                onTap: _openMusic,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    14,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.music_note,
                            size: 22,
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          const Text(
                            'NOW PLAYING',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const Spacer(),
                          if (playback.playing)
                            const Icon(
                              Icons.graphic_eq,
                              size: 20,
                            ),
                        ],
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      Text(
                        playback.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        playback.displayArtist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white60,
                        ),
                      ),
                      const Spacer(),
                      if (playback.hasMedia) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            10,
                          ),
                          child: LinearProgressIndicator(
                            value: playback.progress,
                            minHeight: 5,
                            backgroundColor: const Color(
                              0xFF263238,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Row(
                          children: [
                            Text(
                              _durationText(
                                playback.positionMs,
                              ),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white54,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _durationText(
                                playback.durationMs,
                              ),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(
                        height: 6,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _MediaButton(
                            icon: Icons.skip_previous_rounded,
                            onTap: () {
                              mediaSession.previous();
                            },
                          ),
                          const SizedBox(
                            width: 16,
                          ),
                          _MediaButton(
                            icon: playback.playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            large: true,
                            onTap: () {
                              mediaSession.playPause();
                            },
                          ),
                          const SizedBox(
                            width: 16,
                          ),
                          _MediaButton(
                            icon: Icons.skip_next_rounded,
                            onTap: () {
                              mediaSession.next();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMediaPermissionPanel() {
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
        onTap: () {
          mediaSession.openAccessSettings();
        },
        child: Container(
          width: double.infinity,
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
              const Icon(
                Icons.music_off_rounded,
                size: 42,
              ),
              const SizedBox(
                height: 10,
              ),
              const Text(
                'MEDIA ACCESS REQUIRED',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(
                height: 5,
              ),
              const Text(
                'Tap to enable Notification Access',
                textAlign: TextAlign.center,
                style: TextStyle(
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
            onTap: _openGx,
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
            16,
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
                size: 38,
              ),
              const SizedBox(
                height: 9,
              ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(
                height: 3,
              ),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
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

class _MediaButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool large;

  const _MediaButton({
    required this.icon,
    required this.onTap,
    this.large = false,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final double size = large ? 48 : 38;

    return Material(
      color: large
          ? Theme.of(
              context,
            ).colorScheme.primary
          : const Color(
              0xFF1C2529,
            ),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            size: large ? 30 : 24,
            color: large ? Colors.black : Colors.white,
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
