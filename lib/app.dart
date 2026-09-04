import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'features/splash/splash_screen.dart';
import 'widgets/vehicle_warning_overlay.dart';

class RustlerGXApp extends StatelessWidget {
  const RustlerGXApp({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return MaterialApp(
      title: 'RigOS',
      debugShowCheckedModeBanner: false,
      theme: rustlerTheme,
      home: const SplashScreen(),
      builder: (
        context,
        child,
      ) {
        return VehicleWarningOverlay(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
