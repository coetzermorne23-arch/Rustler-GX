import 'package:flutter/material.dart';

import 'app.dart';
import 'services/capability_runtime_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await CapabilityRuntimeService.instance.initialize();

  runApp(
    const RustlerGXApp(),
  );
}
