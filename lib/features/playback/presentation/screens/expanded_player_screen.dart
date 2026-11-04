import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/ui_kit/theme/app_colors.dart';
import '../../../../shared/ui_kit/theme/app_typography.dart';
import '../widgets/player_controls.dart';
import '../widgets/progress_bar.dart';
import '../../../../shared/ui_kit/widgets/track_artwork.dart';
import '../../../favorites/presentation/controllers/favorites_notifier.dart';
import '../../../playlists/presentation/widgets/add_to_playlist_dialog.dart';
import '../../../queue/presentation/screens/queue_screen.dart';
import '../controllers/playback_notifier.dart';

/// Pantalla completa del reproductor centrada en la canción en reproducción.
class ExpandedPlayerScreen extends ConsumerWidget {
  const ExpandedPlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Cada sección escucha solo lo que pinta: la posición cambia varias veces
    // por segundo y no debe redibujar la carátula ni los metadatos.
    final track = ref.watch(
      playbackNotifierProvider.select((s) => s.currentTrack),
    );

    if (track == null) {
      return Scaffold(
        backgroundColor: AppColors.primaryBackground,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: Text(
            'No hay ninguna canción en reproducción',
            style: AppTypography.bodyMedium,
          ),
        ),
      );
    }

    // El favorito se resuelve aquí: antes dependía de callbacks que ninguna
    // pantalla pasaba, y el botón quedaba sin efecto.
    final isFavorite = ref.watch(
      favoritesNotifierProvider.select((ids) => ids.contains(track.id)),
    );
    final int? trackArtworkId = int.tryParse(track.id);
    // Limitada también por el alto: en horizontal o pantallas cortas, una
    // carátula calculada solo por el ancho desbordaba los controles.
    final screenSize = MediaQuery.sizeOf(context);
    final artworkSize = [
      screenSize.width * 0.75,
      screenSize.height * 0.4,
    ].reduce((a, b) => a < b ? a : b).clamp(120.0, 340.0);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
          tooltip: 'Cerrar reproductor',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('EN REPRODUCCIÓN', style: AppTypography.labelSmall),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.queue_music_rounded),
            tooltip: 'Cola de reproducción',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const QueueScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // Carátula grande centrada
              Center(
                child: Hero(
                  tag: 'track_artwork_${track.id}',
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.04),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: TrackArtwork(
                      id: trackArtworkId,
                      url: track.artworkUrl,
                      size: artworkSize,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // Metadatos y botón de Favorito
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.title,
                          style: AppTypography.displayLarge.copyWith(
                            fontSize: 22,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          track.artist,
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Las listas guardan ids de la biblioteca local (numéricos):
                  // una canción en línea o abierta desde otra app no se podría
                  // volver a encontrar.
                  if (trackArtworkId != null)
                    IconButton(
                      icon: const Icon(
                        Icons.playlist_add_rounded,
                        color: AppColors.iconMuted,
                        size: 28,
                      ),
                      tooltip: 'Añadir a una lista',
                      onPressed: () =>
                          AddToPlaylistDialog.show(context, track: track),
                    ),
                  IconButton(
                    icon: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFavorite
                          ? AppColors.textPrimary
                          : AppColors.iconMuted,
                      size: 28,
                    ),
                    tooltip: isFavorite
                        ? 'Quitar de favoritos'
                        : 'Añadir a favoritos',
                    onPressed: () => ref
                        .read(favoritesNotifierProvider.notifier)
                        .toggleFavorite(track.id),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Barra de progreso interactiva
              const _PlayerProgress(),

              const SizedBox(height: 16),

              // Controles completos del reproductor
              const _PlayerControlsSection(),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerProgress extends ConsumerWidget {
  const _PlayerProgress();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(
      playbackNotifierProvider.select(
        (s) => (position: s.position, duration: s.duration),
      ),
    );
    final notifier = ref.read(playbackNotifierProvider.notifier);

    return ProgressBar(
      position: progress.position,
      duration: progress.duration,
      onSeek: (pos) => notifier.seek(pos),
    );
  }
}

class _PlayerControlsSection extends ConsumerWidget {
  const _PlayerControlsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controls = ref.watch(
      playbackNotifierProvider.select(
        (s) => (
          isPlaying: s.isPlaying,
          isBuffering: s.isBuffering,
          isShuffleEnabled: s.isShuffleEnabled,
          loopMode: s.loopMode,
        ),
      ),
    );
    final notifier = ref.read(playbackNotifierProvider.notifier);

    return PlayerControls(
      isPlaying: controls.isPlaying,
      isBuffering: controls.isBuffering,
      isShuffleEnabled: controls.isShuffleEnabled,
      loopMode: controls.loopMode,
      onPlayPause: () => notifier.togglePlayPause(),
      onPrevious: () => notifier.skipToPrevious(),
      onNext: () => notifier.skipToNext(),
      onToggleShuffle: () => notifier.toggleShuffle(),
      onCycleLoop: () => notifier.cycleLoopMode(),
      buttonSize: 32,
    );
  }
}
