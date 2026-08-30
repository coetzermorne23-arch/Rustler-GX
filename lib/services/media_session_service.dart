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

  final ValueNotifier<bool> notificationAccess = ValueNotifier<bool>(
    false,
  );

  final ValueNotifier<String?> error = ValueNotifier<String?>(
    null,
  );

  Timer? _timer;

  bool _refreshing = false;

  bool get running => _timer != null;

  Future<void> start() async {
    if (_timer != null) {
      return;
    }

    await checkAccess();
    await refresh();

    _timer = Timer.periodic(
      const Duration(
        milliseconds: 750,
      ),
      (_) {
        refresh();
      },
    );
  }

  Future<void> checkAccess() async {
    try {
      notificationAccess.value = await _channel.invokeMethod<bool>(
            'hasNotificationAccess',
          ) ??
          false;
    } catch (exception) {
      notificationAccess.value = false;

      debugPrint(
        'Notification access check failed: '
        '$exception',
      );
    }
  }

  Future<void> refresh() async {
    if (_refreshing) {
      return;
    }

    _refreshing = true;

    try {
      final Map<dynamic, dynamic>? data =
          await _channel.invokeMapMethod<dynamic, dynamic>(
        'getPlayback',
      );

      if (data == null) {
        playback.value = MediaPlaybackData.empty();

        error.value = null;

        return;
      }

      playback.value = MediaPlaybackData.fromMap(
        data,
      );

      error.value = null;
    } on MissingPluginException {
      error.value = 'Media controls are only available on Android.';
    } catch (exception) {
      error.value = exception.toString();

      debugPrint(
        'Media session read failed: '
        '$exception',
      );
    } finally {
      _refreshing = false;
    }
  }

  Future<bool> hasAccess() async {
    await checkAccess();

    return notificationAccess.value;
  }

  Future<void> openAccessSettings() async {
    try {
      await _channel.invokeMethod(
        'openNotificationAccess',
      );
    } catch (exception) {
      debugPrint(
        'Could not open notification access settings: '
        '$exception',
      );
    }
  }

  Future<void> playPause() async {
    try {
      await _channel.invokeMethod(
        'playPause',
      );

      await _delayedRefresh();
    } catch (exception) {
      debugPrint(
        'Play/pause failed: '
        '$exception',
      );
    }
  }

  Future<void> play() async {
    try {
      await _channel.invokeMethod(
        'play',
      );

      await _delayedRefresh();
    } catch (exception) {
      debugPrint(
        'Play failed: '
        '$exception',
      );
    }
  }

  Future<void> pause() async {
    try {
      await _channel.invokeMethod(
        'pause',
      );

      await _delayedRefresh();
    } catch (exception) {
      debugPrint(
        'Pause failed: '
        '$exception',
      );
    }
  }

  Future<void> next() async {
    try {
      await _channel.invokeMethod(
        'next',
      );

      await _delayedRefresh();
    } catch (exception) {
      debugPrint(
        'Next failed: '
        '$exception',
      );
    }
  }

  Future<void> previous() async {
    try {
      await _channel.invokeMethod(
        'previous',
      );

      await _delayedRefresh();
    } catch (exception) {
      debugPrint(
        'Previous failed: '
        '$exception',
      );
    }
  }

  Future<void> seekTo(
    int milliseconds,
  ) async {
    try {
      await _channel.invokeMethod(
        'seekTo',
        <String, dynamic>{
          'positionMs': milliseconds,
        },
      );

      await _delayedRefresh();
    } catch (exception) {
      debugPrint(
        'Seek failed: '
        '$exception',
      );
    }
  }

  Future<void> _delayedRefresh() async {
    await Future<void>.delayed(
      const Duration(
        milliseconds: 150,
      ),
    );

    await refresh();
  }

  Future<void> stop() async {
    _timer?.cancel();

    _timer = null;
  }
}
