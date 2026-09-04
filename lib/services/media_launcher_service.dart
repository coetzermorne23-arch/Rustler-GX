import 'package:flutter/foundation.dart';

class MediaLauncherService {
  MediaLauncherService._();
  static final MediaLauncherService instance = MediaLauncherService._();

  static const String youtubeMusicPackage =
      'com.google.android.apps.youtube.music';

  Future<void> openYouTubeMusic() async {
    debugPrint(
      'RigOS: YouTube Music foreground Activity suppressed; '
      'playback remains on the Android media-session layer.',
    );
  }
}
