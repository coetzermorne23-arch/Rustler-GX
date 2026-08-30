import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class HeadUnitService {
  HeadUnitService._();

  static final HeadUnitService instance = HeadUnitService._();

  static const MethodChannel _channel = MethodChannel(
    'rustler_gx/head_unit',
  );

  final ValueNotifier<bool> ready = ValueNotifier<bool>(
    false,
  );

  Future<void> initialise() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      ready.value = false;

      return;
    }

    try {
      await _channel.invokeMethod(
        'keepScreenOn',
      );

      ready.value = true;
    } catch (_) {
      ready.value = false;
    }
  }

  Future<void> immersiveMode() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      await _channel.invokeMethod(
        'immersiveMode',
      );
    } catch (_) {}
  }

  Future<void> normalSystemUi() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      await _channel.invokeMethod(
        'normalSystemUi',
      );
    } catch (_) {}
  }

  Future<void> keepScreenOn() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      await _channel.invokeMethod(
        'keepScreenOn',
      );
    } catch (_) {}
  }
}
