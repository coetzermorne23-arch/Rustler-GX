import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/media_playback_data.dart';

class MediaSessionService {
  MediaSessionService._();

  static final MediaSessionService instance = MediaSessionService._();

  static const MethodChannel _channel = MethodChannel(
    'rustler_gx/media',
  );

  final ValueNotifier<MediaPlaybackData> playback =
      ValueNotifier<MediaPlaybackData>(
    MediaPlaybackData.empty(),
  );

  Timer? _timer;

  Future<void> start() async {
    await refresh();

    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(
        seconds: 1,
      ),
      (_) {
        refresh();
      },
    );
  }

  Future<void> refresh() async {
    try {
      final Map<dynamic, dynamic>? data =
          await _channel.invokeMapMethod<dynamic, dynamic>(
        'getPlayback',
      );

      if (data == null) {
        playback.value = MediaPlaybackData.empty();

        return;
      }

      playback.value = MediaPlaybackData.fromMap(
        data,
      );
    } catch (error) {
      debugPrint(
        'Media session read failed: $error',
      );
    }
  }

  Future<bool> hasAccess() async {
    try {
      return await _channel.invokeMethod<bool>(
            'hasNotificationAccess',
          ) ??
          false;
    } catch (_) {
      return false;
    }
  }

  Future<void> openAccessSettings() async {
    await _channel.invokeMethod(
      'openNotificationAccess',
    );
  }

  Future<void> playPause() async {
    await _channel.invokeMethod(
      'playPause',
    );

    await refresh();
  }

  Future<void> next() async {
    await _channel.invokeMethod(
      'next',
    );

    await refresh();
  }

  Future<void> previous() async {
    await _channel.invokeMethod(
      'previous',
    );

    await refresh();
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
  }
}
