import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';

class MediaLauncherService {
  MediaLauncherService._();

  static final MediaLauncherService instance =
      MediaLauncherService._();

  static const String youtubeMusicPackage =
      'com.google.android.apps.youtube.music';

  Future<void> openYouTubeMusic() async {
    try {
      const AndroidIntent intent =
          AndroidIntent(
        action: 'android.intent.action.MAIN',
        category:
            'android.intent.category.LAUNCHER',
        package: youtubeMusicPackage,
      );

      await intent.launch();
    } catch (error) {
      debugPrint(
        'Could not open YouTube Music: $error',
      );

      rethrow;
    }
  }
}