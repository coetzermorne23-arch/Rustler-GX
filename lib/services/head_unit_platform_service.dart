import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/head_unit_platform_state.dart';

class HeadUnitPlatformService {
  HeadUnitPlatformService._();

  static final HeadUnitPlatformService instance = HeadUnitPlatformService._();

  static const MethodChannel _channel = MethodChannel('rustler_gx/head_unit');

  final ValueNotifier<bool> defaultHome = ValueNotifier<bool>(false);
  final ValueNotifier<List<HeadUnitStorageVolume>> storageVolumes =
      ValueNotifier<List<HeadUnitStorageVolume>>(<HeadUnitStorageVolume>[]);
  final ValueNotifier<HeadUnitCallState> call =
      ValueNotifier<HeadUnitCallState>(const HeadUnitCallState.idle());

  Timer? _timer;

  bool get hasUsbMusicStorage => storageVolumes.value.any(
        (HeadUnitStorageVolume volume) =>
            volume.removable && volume.state == 'mounted',
      );

  Future<void> start() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    await refresh();
    _timer ??= Timer.periodic(const Duration(seconds: 2), (_) => refresh());
  }

  Future<void> refresh() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      defaultHome.value =
          await _channel.invokeMethod<bool>('isDefaultHome') ?? false;
      final List<dynamic>? raw =
          await _channel.invokeMethod<List<dynamic>>('storageVolumes');
      storageVolumes.value = (raw ?? <dynamic>[])
          .whereType<Map<dynamic, dynamic>>()
          .map(HeadUnitStorageVolume.fromMap)
          .toList(growable: false);
      call.value = HeadUnitCallState.fromMap(
        await _channel.invokeMapMethod<dynamic, dynamic>('getCallState'),
      );
    } catch (_) {}
  }

  Future<void> requestHomeRole() async {
    try {
      await _channel.invokeMethod('requestHomeRole');
    } catch (_) {}
  }

  Future<void> answerCall() async {
    try {
      await _channel.invokeMethod('answerCall');
    } catch (_) {}
    await refresh();
  }

  Future<void> declineCall() async {
    try {
      await _channel.invokeMethod('declineCall');
    } catch (_) {}
    await refresh();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
