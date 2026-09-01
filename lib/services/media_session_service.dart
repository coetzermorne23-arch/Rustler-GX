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
  int _ticks = 0;

  bool get running => _timer != null;

  Future<void> start() async {
    if (_timer != null) {
      await checkAccess();
      await refresh();
      return;
    }

    await checkAccess();
    await refresh();

    _timer = Timer.periodic(
      const Duration(
        milliseconds: 750,
      ),
      (_) async {
        _ticks++;

        if (_ticks % 5 == 0) {
          await checkAccess();
        }

        await refresh();
      },
    );
  }

  Future<void> checkAccess() async {
    try {
      notificationAccess.value = await _channel.invokeMethod<bool>(
            'hasNotificationAccess',
          ) ??
          false;

      error.value = null;
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
        return;
      }

      playback.value = MediaPlaybackData.fromMap(
        data,
      );

      error.value = null;
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
    try {
      await _channel.invokeMethod(
        'openNotificationAccess',
      );
    } catch (exception) {
      debugPrint(
        'Could not open notification '
        'access settings: $exception',
      );
    }
  }

  Future<void> playPause() async {
    await _invokeControl(
      'playPause',
    );
  }

  Future<void> play() async {
    await _invokeControl(
      'play',
    );
  }

  Future<void> pause() async {
    await _invokeControl(
      'pause',
    );
  }

  Future<void> next() async {
    await _invokeControl(
      'next',
    );
  }

  Future<void> previous() async {
    await _invokeControl(
      'previous',
    );
  }

  Future<void> seekTo(
    int positionMs,
  ) async {
    try {
      await _channel.invokeMethod(
        'seekTo',
        <String, dynamic>{
          'positionMs': positionMs,
        },
      );

      await refresh();
    } catch (exception) {
      debugPrint(
        'Media seek failed: $exception',
      );
    }
  }

  Future<void> _invokeControl(
    String method,
  ) async {
    try {
      await _channel.invokeMethod(
        method,
      );

      await refresh();
    } catch (exception) {
      debugPrint(
        'Media control $method failed: '
        '$exception',
      );
    }
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _ticks = 0;
  }
}
