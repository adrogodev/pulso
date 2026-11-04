import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulso/shared/ui_kit/theme/app_colors.dart';
import 'package:pulso/shared/ui_kit/theme/app_typography.dart';
import 'package:pulso/features/favorites/presentation/controllers/favorites_notifier.dart';
import 'package:pulso/features/library/presentation/controllers/library_notifier.dart';
import 'package:pulso/features/playback/presentation/controllers/playback_notifier.dart';
import 'package:pulso/features/playback/presentation/widgets/now_playing_navigation.dart';
import 'package:pulso/shared/ui_kit/widgets/pulso_waveform.dart';
import 'package:pulso/shared/ui_kit/widgets/track_artwork.dart';

/// Pantalla dedicada a las canciones marcadas como favoritas por el usuario.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteIds = ref.watch(favoritesNotifierProvider);
    final libraryState = ref.watch(libraryNotifierProvider);
    final favNotifier = ref.read(favoritesNotifierProvider.notifier);
    final playbackNotifier = ref.read(playbackNotifierProvider.notifier);

    // Filtrar canciones de la biblioteca presentes en favoritos
    final favoriteTracks = libraryState.tracks
        .where((track) => favoriteIds.contains(track.id))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('FAVORITOS', style: AppTypography.titleMedium),
            Text(
              '${favoriteTracks.length} ${favoriteTracks.length == 1 ? 'canción' : 'canciones'}',
              style: AppTypography.labelSmall,
            ),
          ],
        ),
        actions: [
          if (favoriteTracks.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.play_circle_fill_rounded, size: 32),
              tooltip: 'Reproducir todo',
              onPressed: () => playbackNotifier.playTracks(favoriteTracks),
            ),
        ],
      ),
      body: favoriteTracks.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const PulsoWaveform(
                    width: 64,
                    height: 64,
                    color: AppColors.textDisabled,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No tienes favoritos aún',
                    style: AppTypography.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Toca el icono de corazón en cualquier canción para guardarla aquí',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: favoriteTracks.length,
              itemBuilder: (context, index) {
                final track = favoriteTracks[index];
                final trackArtworkId = int.tryParse(track.id);

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: TrackArtwork(id: trackArtworkId, size: 48),
                  title: Text(
                    track.title,
                    style: AppTypography.bodyLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    track.artist,
                    style: AppTypography.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        track.formattedDuration,
                        style: AppTypography.labelSmall,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.favorite_rounded,
                          color: AppColors.textPrimary,
                          size: 22,
                        ),
                        tooltip: 'Quitar de favoritos',
                        onPressed: () => favNotifier.toggleFavorite(track.id),
                      ),
                    ],
                  ),
                  onTap: () => playOrOpenNowPlaying(
                    context,
                    ref,
                    track,
                    queue: favoriteTracks,
                  ),
                );
              },
            ),
    );
  }
}
