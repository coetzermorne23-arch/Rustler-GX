import 'package:flutter/material.dart';

import '../../models/media_playback_data.dart';
import '../../services/media_launcher_service.dart';
import '../../services/media_session_service.dart';

class MediaControlCard extends StatefulWidget {
  const MediaControlCard({
    super.key,
  });

  @override
  State<MediaControlCard> createState() => _MediaControlCardState();
}

class _MediaControlCardState extends State<MediaControlCard> {
  final MediaSessionService media = MediaSessionService.instance;

  final MediaLauncherService launcher = MediaLauncherService.instance;

  @override
  void initState() {
    super.initState();

    media.start();
  }

  String _duration(
    int milliseconds,
  ) {
    if (milliseconds <= 0) {
      return '0:00';
    }

    final Duration duration = Duration(
      milliseconds: milliseconds,
    );

    final int minutes = duration.inMinutes;

    final int seconds = duration.inSeconds % 60;

    return '$minutes:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _openMusic() async {
    try {
      await launcher.openYouTubeMusic();
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open YouTube Music.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return ValueListenableBuilder<MediaPlaybackData>(
      valueListenable: media.playback,
      builder: (
        context,
        playback,
        child,
      ) {
        return Material(
          color: Colors.transparent,
          child: Container(
            height: 132,
            padding: const EdgeInsets.all(
              14,
            ),
            decoration: BoxDecoration(
              color: const Color(
                0xF211171A,
              ),
              borderRadius: BorderRadius.circular(
                18,
              ),
              border: Border.all(
                color: const Color(
                  0xFF334047,
                ),
              ),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 18,
                  offset: Offset(
                    0,
                    5,
                  ),
                  color: Colors.black45,
                ),
              ],
            ),
            child: Row(
              children: [
                _albumPlaceholder(
                  playback,
                ),
                const SizedBox(
                  width: 14,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              playback.displayTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Open YouTube Music',
                            onPressed: _openMusic,
                            icon: const Icon(
                              Icons.open_in_new,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        playback.displayArtist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white60,
                        ),
                      ),
                      const Spacer(),
                      if (playback.durationMs > 0)
                        Row(
                          children: [
                            Text(
                              _duration(
                                playback.positionMs,
                              ),
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.white54,
                              ),
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  10,
                                ),
                                child: LinearProgressIndicator(
                                  value: playback.progress,
                                  minHeight: 4,
                                  backgroundColor: Colors.white12,
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Text(
                              _duration(
                                playback.durationMs,
                              ),
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(
                        height: 4,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _controlButton(
                            icon: Icons.skip_previous_rounded,
                            onPressed: media.previous,
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          _playButton(
                            playback,
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          _controlButton(
                            icon: Icons.skip_next_rounded,
                            onPressed: media.next,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _albumPlaceholder(
    MediaPlaybackData playback,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(
        14,
      ),
      onTap: _openMusic,
      child: Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            14,
          ),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(
                0xFF263238,
              ),
              Color(
                0xFF11171A,
              ),
            ],
          ),
          border: Border.all(
            color: Colors.white12,
          ),
        ),
        child: Icon(
          playback.playing
              ? Icons.graphic_eq_rounded
              : Icons.music_note_rounded,
          size: 45,
        ),
      ),
    );
  }

  Widget _playButton(
    MediaPlaybackData playback,
  ) {
    return SizedBox(
      width: 48,
      height: 48,
      child: FloatingActionButton.small(
        heroTag: null,
        elevation: 0,
        onPressed: media.playPause,
        child: Icon(
          playback.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
          size: 31,
        ),
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required Future<void> Function() onPressed,
  }) {
    return IconButton(
      onPressed: () {
        onPressed();
      },
      icon: Icon(
        icon,
        size: 31,
      ),
    );
  }
}
