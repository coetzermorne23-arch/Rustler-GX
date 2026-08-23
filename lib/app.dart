import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'features/splash/splash_screen.dart';

class RustlerGXApp extends StatelessWidget {
  const RustlerGXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rustler GX',
      debugShowCheckedModeBanner: false,
      theme: rustlerTheme,
      home: const SplashScreen(),
    );
  }
}