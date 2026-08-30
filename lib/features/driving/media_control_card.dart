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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MediaPlaybackData>(
      valueListenable: media.playback,
      builder: (
        context,
        playback,
        child,
      ) {
        return Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(
              14,
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () async {
                    await launcher.openYouTubeMusic();
                  },
                  borderRadius: BorderRadius.circular(
                    10,
                  ),
                  child: Container(
                    width: 54,
                    height: 54,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.music_note,
                      size: 34,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        playback.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      Text(
                        playback.artist.isEmpty
                            ? 'YouTube Music'
                            : playback.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Previous',
                  onPressed: media.previous,
                  icon: const Icon(
                    Icons.skip_previous,
                  ),
                ),
                IconButton.filled(
                  tooltip: playback.playing ? 'Pause' : 'Play',
                  onPressed: media.playPause,
                  icon: Icon(
                    playback.playing ? Icons.pause : Icons.play_arrow,
                  ),
                ),
                IconButton(
                  tooltip: 'Next',
                  onPressed: media.next,
                  icon: const Icon(
                    Icons.skip_next,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
