class MediaPlaybackData {
  final String title;
  final String artist;
  final String album;
  final String packageName;

  final bool playing;
  final bool active;

  final int positionMs;
  final int durationMs;

  const MediaPlaybackData({
    required this.title,
    required this.artist,
    required this.album,
    required this.packageName,
    required this.playing,
    required this.active,
    required this.positionMs,
    required this.durationMs,
  });

  factory MediaPlaybackData.empty() {
    return const MediaPlaybackData(
      title: '',
      artist: '',
      album: '',
      packageName: '',
      playing: false,
      active: false,
      positionMs: 0,
      durationMs: 0,
    );
  }

  factory MediaPlaybackData.fromMap(
    Map<dynamic, dynamic> map,
  ) {
    return MediaPlaybackData(
      title: _string(
        map['title'],
      ),
      artist: _string(
        map['artist'],
      ),
      album: _string(
        map['album'],
      ),
      packageName: _string(
        map['packageName'],
      ),
      playing: map['playing'] == true,
      active: map['active'] == true,
      positionMs: _integer(
        map['positionMs'],
      ),
      durationMs: _integer(
        map['durationMs'],
      ),
    );
  }

  static String _string(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    return value.toString();
  }

  static int _integer(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.round();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  bool get hasMedia => active || title.isNotEmpty || artist.isNotEmpty;

  double get progress {
    if (durationMs <= 0) {
      return 0;
    }

    return (positionMs / durationMs).clamp(
      0.0,
      1.0,
    );
  }

  String get displayTitle {
    if (title.trim().isEmpty) {
      return 'Nothing playing';
    }

    return title.trim();
  }

  String get displayArtist {
    if (artist.trim().isEmpty) {
      return 'YouTube Music';
    }

    return artist.trim();
  }

  MediaPlaybackData copyWith({
    String? title,
    String? artist,
    String? album,
    String? packageName,
    bool? playing,
    bool? active,
    int? positionMs,
    int? durationMs,
  }) {
    return MediaPlaybackData(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      packageName: packageName ?? this.packageName,
      playing: playing ?? this.playing,
      active: active ?? this.active,
      positionMs: positionMs ?? this.positionMs,
      durationMs: durationMs ?? this.durationMs,
    );
  }
}
