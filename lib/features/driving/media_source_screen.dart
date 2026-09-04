import 'package:flutter/material.dart';
import '../../services/media_session_service.dart';

class MediaSourceScreen extends StatelessWidget {
  const MediaSourceScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('MEDIA SOURCES')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 2.2,
            children: [
              _Source(
                icon: Icons.music_note_rounded,
                title: 'YOUTUBE MUSIC',
                subtitle: 'Background playback • RigOS controls',
                onTap: () async {
                  await MediaSessionService.instance.play();
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              const _Source(
                icon: Icons.usb_rounded,
                title: 'USB',
                subtitle: 'USB music source',
              ),
              const _Source(
                icon: Icons.bluetooth_audio_rounded,
                title: 'BLUETOOTH',
                subtitle: 'Phone Bluetooth audio',
              ),
              const _Source(
                icon: Icons.radio_rounded,
                title: 'RADIO',
                subtitle: 'FM / AM tuner',
              ),
            ],
          ),
        ),
      );
}

class _Source extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _Source({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xFF11171A),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap ??
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '$title is in the RigOS UI; the radio hardware API '
                      'will be connected after the app baseline is finished.',
                    ),
                  ),
                );
              },
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF2B383E)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 42),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
