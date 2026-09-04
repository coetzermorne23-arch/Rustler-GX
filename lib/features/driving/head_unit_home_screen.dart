import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/media_playback_data.dart';
import '../../models/vehicle_obd_data.dart';
import '../../models/head_unit_platform_state.dart';
import '../../services/gps_service.dart';
import '../../services/media_session_service.dart';
import '../../services/head_unit_runtime_service.dart';
import '../../services/head_unit_platform_service.dart';
import '../../services/installation_identity_service.dart';
import '../../services/vehicle_data_service.dart';
import '../../services/obd_service.dart';
import '../settings/rigos_settings_screen.dart';

import 'driving_screen.dart';
import 'offline_navigation_screen.dart';
import 'gps_custom_screen.dart';
import 'media_source_screen.dart';
import 'obd_dashboard_screen.dart';

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

  final MediaSessionService mediaSession = MediaSessionService.instance;

  final HeadUnitRuntimeService runtime = HeadUnitRuntimeService.instance;

  final HeadUnitPlatformService platform = HeadUnitPlatformService.instance;

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
    unawaited(ObdService.instance.start());

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
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const MediaSourceScreen(),
      ),
    );
  }

  void _openGpsDetails() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const GpsCustomScreen(),
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

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const RigOsSettingsScreen()),
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
        child: Stack(
          children: [
            Column(
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
            ValueListenableBuilder<HeadUnitCallState>(
              valueListenable: platform.call,
              builder: (context, call, child) {
                if (!call.active) return const SizedBox.shrink();
                return Positioned.fill(child: _buildCallOverlay(call));
              },
            ),
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
            'RigOS',
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.4),
          ),
          const SizedBox(width: 10),
          FutureBuilder<String>(
            future: InstallationIdentityService.instance.getInstallationName(),
            builder: (context, snapshot) => Text(
              snapshot.data == null || snapshot.data == 'RigOS'
                  ? ''
                  : snapshot.data!,
              style: const TextStyle(fontSize: 11, color: Colors.white38),
            ),
          ),
          const Spacer(),
          ValueListenableBuilder<List<HeadUnitStorageVolume>>(
            valueListenable: platform.storageVolumes,
            builder: (context, volumes, child) {
              final bool usb = platform.hasUsbMusicStorage;
              return Row(
                children: [
                  Icon(usb ? Icons.usb : Icons.usb_off, size: 18),
                  const SizedBox(width: 5),
                  Text(usb ? 'USB' : 'YT MUSIC',
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 18),
                ],
              );
            },
          ),
          ValueListenableBuilder<Position?>(
            valueListenable: gps.position,
            builder: (
              context,
              position,
              child,
            ) {
              return InkWell(
                onTap: _openGpsDetails,
                borderRadius: BorderRadius.circular(16),
                child: Row(
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
                ),
              );
            },
          ),
          const SizedBox(width: 14),
          IconButton(
            tooltip: 'RigOS Settings',
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_rounded),
          ),
          const SizedBox(width: 8),
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

  Widget _buildCallOverlay(HeadUnitCallState call) {
    return ColoredBox(
      color: const Color(0xE6080B0D),
      child: Center(
        child: Container(
          width: 560,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF11171A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF3D4B52)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.call, size: 52),
              const SizedBox(height: 14),
              Text(call.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 25, fontWeight: FontWeight.w900)),
              if (call.text.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(call.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white60)),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: platform.answerCall,
                    icon: const Icon(Icons.call),
                    label: const Text('ANSWER'),
                  ),
                  const SizedBox(width: 18),
                  OutlinedButton.icon(
                    onPressed: platform.declineCall,
                    icon: const Icon(Icons.call_end),
                    label: const Text('DECLINE / END'),
                  ),
                ],
              ),
            ],
          ),
        ),
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
          child: _buildObdQuickPanel(),
        ),
      ],
    );
  }

  Widget _buildObdQuickPanel() {
    return ValueListenableBuilder<VehicleObdData>(
      valueListenable: VehicleDataService.instance.data,
      builder: (context, data, _) => Material(
        color: const Color(0xFF11171A),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const ObdDashboardScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF263238)),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(
                    data.connected
                        ? Icons.bluetooth_connected
                        : Icons.bluetooth_disabled,
                    size: 20),
                const SizedBox(width: 8),
                const Text('OBD LIVE',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.4)),
                const Spacer(),
                Text(data.connected ? 'CONNECTED' : 'NOT CONNECTED',
                    style: TextStyle(
                        fontSize: 10,
                        color: data.connected
                            ? Colors.greenAccent
                            : Colors.white38)),
              ]),
              const Spacer(),
              Row(children: [
                Expanded(
                    child: _MiniInfo(
                        title: 'RPM',
                        value: data.rpm == null
                            ? '--'
                            : data.rpm!.round().toString())),
                Expanded(
                    child: _MiniInfo(
                        title: 'BOOST',
                        value: data.boostBar == null
                            ? '--'
                            : '${data.boostBar!.toStringAsFixed(2)} bar')),
                Expanded(
                    child: _MiniInfo(
                        title: 'COOLANT',
                        value: data.coolantTemperatureC == null
                            ? '--'
                            : '${data.coolantTemperatureC!.round()}°C')),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: _MiniInfo(
                        title: 'BATTERY',
                        value: data.batteryVoltage == null
                            ? '--'
                            : '${data.batteryVoltage!.toStringAsFixed(1)} V')),
                Expanded(
                    child: _MiniInfo(
                        title: 'LOAD',
                        value: data.engineLoadPercent == null
                            ? '--'
                            : '${data.engineLoadPercent!.round()}%')),
                Expanded(
                    child: _MiniInfo(
                        title: 'SPEED',
                        value: data.vehicleSpeedKmh == null
                            ? '--'
                            : '${data.vehicleSpeedKmh!.round()} km/h')),
              ]),
            ]),
          ),
        ),
      ),
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
            icon: Icons.settings_rounded,
            label: 'SETTINGS',
            selected: false,
            onTap: _openSettings,
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
