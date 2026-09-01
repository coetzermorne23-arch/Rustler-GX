import 'package:flutter/foundation.dart';

import 'gps_service.dart';
import 'head_unit_service.dart';
import 'media_session_service.dart';

class HeadUnitRuntimeService {
  HeadUnitRuntimeService._();

  static final HeadUnitRuntimeService instance = HeadUnitRuntimeService._();

  final GpsService gps = GpsService.instance;

  final HeadUnitService headUnit = HeadUnitService.instance;

  final MediaSessionService media = MediaSessionService.instance;

  final ValueNotifier<bool> running = ValueNotifier<bool>(
    false,
  );

  Future<void> start() async {
    await headUnit.initialise();

    await Future.wait<void>([
      gps.start(),
      media.start(),
    ]);

    running.value = true;
  }

  Future<void> resume() async {
    await headUnit.restoreHeadUnitUi();

    await media.checkAccess();
    await media.refresh();

    if (!running.value) {
      await start();
    }
  }

  Future<void> leaveHeadUnitMode() async {
    await headUnit.normalSystemUi();

    running.value = false;
  }
}
