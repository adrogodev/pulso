import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/ui_kit/theme/app_colors.dart';
import '../../../../shared/ui_kit/theme/app_typography.dart';
import '../../../../shared/utils/metadata_formatter.dart';
import '../../../../shared/base_domain/models/artist.dart';
import '../../../../shared/base_domain/models/track.dart';
import '../../../playback/presentation/widgets/mini_player.dart';
import '../../../../shared/ui_kit/widgets/pulso_waveform.dart';
import '../../../../shared/ui_kit/widgets/track_artwork.dart';
import '../../../../shared/ui_kit/widgets/track_info_dialog.dart';
import '../../../favorites/presentation/controllers/favorites_notifier.dart';
import '../../../playback/presentation/controllers/playback_notifier.dart';
import '../../../playback/presentation/screens/expanded_player_screen.dart';
import '../../../playlists/presentation/widgets/add_to_playlist_dialog.dart';
import '../controllers/library_notifier.dart';

/// Pantalla de detalle de un artista con listado de sus canciones y reproducción global.
class ArtistDetailScreen extends ConsumerWidget {
  final Artist artist;
  final List<Track>? initialTracks;

  const ArtistDetailScreen({
    super.key,
    required this.artist,
    this.initialTracks,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(libraryNotifierProvider);
    final nowPlaying = ref.watch(
      playbackNotifierProvider.select(
        (s) => (trackId: s.currentTrack?.id, isPlaying: s.isPlaying),
      ),
    );
    final playbackNotifier = ref.read(playbackNotifierProvider.notifier);
    final favorites = ref.watch(favoritesNotifierProvider);
    final favoritesNotifier = ref.read(favoritesNotifierProvider.notifier);

    final tracks =
        initialTracks ??
        libraryState.tracks.where((t) => t.artist == artist.name).toList();

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Text(artist.name),
        backgroundColor: AppColors.primaryBackground,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // Cabecera del Artista
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surface,
                          border: Border.all(
                            color: AppColors.border,
                            width: 1.5,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.person,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        artist.name,
                        style: AppTypography.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${artist.numOfAlbums} ${artist.numOfAlbums == 1 ? "álbum" : "álbumes"} • ${MetadataFormatter.formatSongCount(artist.numOfTracks)}',
                        style: AppTypography.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FilledButton.icon(
                            onPressed: tracks.isEmpty
                                ? null
                                : () => playbackNotifier.playTracks(tracks),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Reproducir'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: tracks.isEmpty
                                ? null
                                : () async {
                                    final shuffled = List<Track>.from(tracks)
                                      ..shuffle();
                                    await playbackNotifier.playTracks(shuffled);
                                  },
                            icon: const Icon(Icons.shuffle),
                            label: const Text('Aleatorio'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 8),

                // Lista de pistas del artista
                ...List.generate(tracks.length, (index) {
                  final track = tracks[index];
                  final isCurrent = nowPlaying.trackId == track.id;
                  final isFav = favorites.contains(track.id);

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: TrackArtwork(
                      id: int.tryParse(track.id),
                      size: 48,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    title: Text(
                      track.title,
                      style: AppTypography.bodyLarge.copyWith(
                        color: isCurrent
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${track.album} • ${MetadataFormatter.formatDurationMs(track.duration.inMilliseconds)}',
                      style: AppTypography.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCurrent && nowPlaying.isPlaying)
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: PulsoWaveform(width: 20, height: 16),
                          ),
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert,
                            color: AppColors.textSecondary,
                          ),
                          onSelected: (value) async {
                            switch (value) {
                              case 'play_next':
                                await playbackNotifier.playNext(track);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Se reproducirá a continuación',
                                      ),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                }
                              case 'add_queue':
                                await playbackNotifier.addToQueue(track);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Añadida a la cola'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                }
                              case 'favorite':
                                await favoritesNotifier.toggleFavorite(
                                  track.id,
                                );
                              case 'add_playlist':
                                if (context.mounted) {
                                  await AddToPlaylistDialog.show(
                                    context,
                                    track: track,
                                  );
                                }
                              case 'info':
                                if (context.mounted) {
                                  await TrackInfoDialog.show(context, track);
                                }
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'play_next',
                              child: Text('Reproducir a continuación'),
                            ),
                            const PopupMenuItem(
                              value: 'add_queue',
                              child: Text('Añadir a la cola'),
                            ),
                            PopupMenuItem(
                              value: 'favorite',
                              child: Text(
                                isFav
                                    ? 'Quitar de favoritos'
                                    : 'Añadir a favoritos',
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'add_playlist',
                              child: Text('Añadir a lista...'),
                            ),
                            const PopupMenuItem(
                              value: 'info',
                              child: Text('Información del archivo'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    onTap: () => playbackNotifier.playTracks(
                      tracks,
                      initialIndex: index,
                    ),
                  );
                }),
              ],
            ),
          ),
          MiniPlayer(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ExpandedPlayerScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
