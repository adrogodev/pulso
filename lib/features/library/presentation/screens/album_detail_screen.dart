import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/ui_kit/theme/app_colors.dart';
import '../../../../shared/ui_kit/theme/app_typography.dart';
import '../../../../shared/utils/metadata_formatter.dart';
import '../../../../shared/base_domain/models/album.dart';
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

/// Pantalla de detalle de un álbum musical con reproducción integral y listado de pistas.
class AlbumDetailScreen extends ConsumerWidget {
  final Album album;
  final List<Track>? initialTracks;

  const AlbumDetailScreen({super.key, required this.album, this.initialTracks});

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

    final albumTracks =
        initialTracks ??
        libraryState.tracks
            .where((t) => t.albumId == album.id || t.album == album.title)
            .toList();

    final sortedTracks = List<Track>.from(albumTracks)
      ..sort((a, b) {
        if (a.trackNumber != null && b.trackNumber != null) {
          return a.trackNumber!.compareTo(b.trackNumber!);
        }
        return a.title.compareTo(b.title);
      });

    final year = album.firstYear ?? album.lastYear;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Text(album.title),
        backgroundColor: AppColors.primaryBackground,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // Cabecera del Álbum
                Center(
                  child: Column(
                    children: [
                      TrackArtwork(
                        id: sortedTracks.isNotEmpty
                            ? int.tryParse(sortedTracks.first.id)
                            : null,
                        size: 160,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        album.title,
                        style: AppTypography.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        album.artist,
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${sortedTracks.length} canciones${year != null && year > 0 ? ' • $year' : ''}',
                        style: AppTypography.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      // Botones de acción rápida: Reproducir y Aleatorio
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FilledButton.icon(
                            onPressed: sortedTracks.isEmpty
                                ? null
                                : () =>
                                      playbackNotifier.playTracks(sortedTracks),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Reproducir'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: sortedTracks.isEmpty
                                ? null
                                : () async {
                                    final shuffled = List<Track>.from(
                                      sortedTracks,
                                    )..shuffle();
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

                // Lista de pistas del álbum
                ...List.generate(sortedTracks.length, (index) {
                  final track = sortedTracks[index];
                  final isCurrent = nowPlaying.trackId == track.id;
                  final isFav = favorites.contains(track.id);

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: SizedBox(
                      width: 36,
                      child: Center(
                        child: isCurrent && nowPlaying.isPlaying
                            ? const PulsoWaveform(width: 24, height: 18)
                            : Text(
                                track.trackNumber != null &&
                                        track.trackNumber! > 0
                                    ? MetadataFormatter.formatTrackNumber(
                                        track.trackNumber,
                                      )
                                    : '${index + 1}',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: isCurrent
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                                  fontWeight: isCurrent
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                      ),
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
                      MetadataFormatter.formatDurationMs(
                        track.duration.inMilliseconds,
                      ),
                      style: AppTypography.bodyMedium,
                    ),
                    trailing: PopupMenuButton<String>(
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
                            await favoritesNotifier.toggleFavorite(track.id);
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
                    onTap: () => playbackNotifier.playTracks(
                      sortedTracks,
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
