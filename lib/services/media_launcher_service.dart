import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';

class MediaLauncherService {
  MediaLauncherService._();

  static final MediaLauncherService instance = MediaLauncherService._();

  static const String youtubeMusicPackage =
      'com.google.android.apps.youtube.music';

  Future<void> openYouTubeMusic() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      throw UnsupportedError(
        'YouTube Music launcher is only available on Android.',
      );
    }

    try {
      const AndroidIntent intent = AndroidIntent(
        action: 'android.intent.action.MAIN',
        category: 'android.intent.category.LAUNCHER',
        package: youtubeMusicPackage,
      );

      await intent.launch();
    } catch (exception) {
      debugPrint(
        'Could not open YouTube Music: '
        '$exception',
      );

      rethrow;
    }
  }

  Future<void> openAndroidSettings() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      const AndroidIntent intent = AndroidIntent(
        action: 'android.settings.SETTINGS',
      );

      await intent.launch();
    } catch (exception) {
      debugPrint(
        'Could not open Android settings: '
        '$exception',
      );

      rethrow;
    }
  }

  Future<void> openBluetoothSettings() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      const AndroidIntent intent = AndroidIntent(
        action: 'android.settings.BLUETOOTH_SETTINGS',
      );

      await intent.launch();
    } catch (exception) {
      debugPrint(
        'Could not open Bluetooth settings: '
        '$exception',
      );

      rethrow;
    }
  }

  Future<void> openLocationSettings() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      const AndroidIntent intent = AndroidIntent(
        action: 'android.settings.LOCATION_SOURCE_SETTINGS',
      );

      await intent.launch();
    } catch (exception) {
      debugPrint(
        'Could not open location settings: '
        '$exception',
      );

      rethrow;
    }
  }
}
