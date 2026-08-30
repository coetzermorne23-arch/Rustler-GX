class MediaPlaybackData {
  final String title;
  final String artist;
  final String album;
  final bool playing;
  final String? packageName;

  const MediaPlaybackData({
    required this.title,
    required this.artist,
    required this.album,
    required this.playing,
    this.packageName,
  });

  factory MediaPlaybackData.empty() {
    return const MediaPlaybackData(
      title: 'Nothing playing',
      artist: 'YouTube Music',
      album: '',
      playing: false,
    );
  }

  factory MediaPlaybackData.fromMap(
    Map<dynamic, dynamic> map,
  ) {
    return MediaPlaybackData(
      title:
          map['title']?.toString() ??
          'Nothing playing',
      artist:
          map['artist']?.toString() ??
          '',
      album:
          map['album']?.toString() ??
          '',
      playing:
          map['playing'] == true,
      packageName:
          map['packageName']?.toString(),
    );
  }
}