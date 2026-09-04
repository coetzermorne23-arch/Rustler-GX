import 'dart:async';
import 'package:flutter/material.dart';
import 'app.dart';
import 'services/capability_runtime_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(
    CapabilityRuntimeService.instance.initialize().catchError((Object error) {
      debugPrint('RigOS background runtime init failed: $error');
    }),
  );
  runApp(const RustlerGXApp());
}
