import 'package:flutter/material.dart';

import '../../services/device_profile_service.dart';
import '../../services/head_unit_runtime_service.dart';
import '../../services/head_unit_service.dart';
import '../dashboard/dashboard_screen.dart';
import '../driving/head_unit_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final DeviceProfileService profile = DeviceProfileService.instance;

  final HeadUnitRuntimeService runtime = HeadUnitRuntimeService.instance;

  final HeadUnitService headUnit = HeadUnitService.instance;

  bool loading = true;
  bool choosing = false;

  RustlerDeviceProfile selectedProfile = RustlerDeviceProfile.standard;

  @override
  void initState() {
    super.initState();

    _boot();
  }

  Future<void> _boot() async {
    await profile.initialise();

    final bool hasSaved = await profile.hasSavedProfile();

    if (!mounted) {
      return;
    }

    if (!hasSaved) {
      setState(() {
        loading = false;
        choosing = true;
      });

      return;
    }

    selectedProfile = profile.profile.value;

    await _openSelectedProfile();
  }

  Future<void> _chooseStandard() async {
    selectedProfile = RustlerDeviceProfile.standard;

    await profile.setStandard();

    await _openSelectedProfile();
  }

  Future<void> _chooseRanger() async {
    selectedProfile = RustlerDeviceProfile.rangerHeadUnit;

    await profile.setRangerHeadUnit();

    await _openSelectedProfile();
  }

  Future<void> _openSelectedProfile() async {
    if (selectedProfile == RustlerDeviceProfile.rangerHeadUnit) {
      await runtime.start();
    } else {
      await headUnit.normalSystemUi();
    }

    await Future<void>.delayed(
      const Duration(
        milliseconds: 650,
      ),
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => selectedProfile == RustlerDeviceProfile.rangerHeadUnit
            ? const HeadUnitHomeScreen()
            : const DashboardScreen(),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    if (choosing) {
      return Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 620,
            ),
            child: Padding(
              padding: const EdgeInsets.all(
                28,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.directions_car_filled,
                    size: 72,
                  ),
                  const SizedBox(
                    height: 18,
                  ),
                  const Text(
                    'RUSTLER GX',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  const Text(
                    'Choose how this device '
                    'will be used. This choice '
                    'is saved locally.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                    height: 28,
                  ),
                  _ModeButton(
                    icon: Icons.phone_android,
                    title: 'STANDARD',
                    subtitle: 'Phone, tablet or normal '
                        'Rustler GX use',
                    onTap: _chooseStandard,
                  ),
                  const SizedBox(
                    height: 14,
                  ),
                  _ModeButton(
                    icon: Icons.car_rental,
                    title: 'RANGER_GX',
                    subtitle: 'Dedicated Ford Ranger '
                        'head unit',
                    onTap: _chooseRanger,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final bool ranger =
        profile.profile.value == RustlerDeviceProfile.rangerHeadUnit;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              ranger ? Icons.directions_car_filled : Icons.electric_bolt,
              size: 70,
            ),
            const SizedBox(
              height: 18,
            ),
            Text(
              ranger ? 'RANGER_GX' : 'RUSTLER GX',
              style: const TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 7,
            ),
            Text(
              ranger ? 'FORD RANGER 4X4' : 'VEHICLE & CAMP SYSTEM',
              style: const TextStyle(
                letterSpacing: 2,
                color: Colors.white70,
              ),
            ),
            const SizedBox(
              height: 28,
            ),
            const SizedBox(
              width: 220,
              child: LinearProgressIndicator(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Future<void> Function() onTap;

  const _ModeButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: () async {
          await onTap();
        },
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.all(
            18,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 34,
            ),
            const SizedBox(
              width: 16,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    subtitle,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
            ),
          ],
        ),
      ),
    );
  }
}
