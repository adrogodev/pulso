import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../widgets/player_controls/player_controls.dart';
import '../../../../widgets/player_controls/progress_bar.dart';
import '../../../../widgets/ui/track_artwork.dart';
import '../providers/playback_notifier.dart';

/// Pantalla completa del reproductor centrada en la canción en reproducción.
class ExpandedPlayerScreen extends ConsumerWidget {
  final VoidCallback? onOpenQueue;
  final VoidCallback? onToggleFavorite;
  final bool isFavorite;

  const ExpandedPlayerScreen({
    super.key,
    this.onOpenQueue,
    this.onToggleFavorite,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackState = ref.watch(playbackNotifierProvider);
    final notifier = ref.read(playbackNotifierProvider.notifier);
    final track = playbackState.currentTrack;

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

    final int? trackArtworkId = int.tryParse(track.id);
    final screenWidth = MediaQuery.of(context).size.width;
    final artworkSize = (screenWidth * 0.75).clamp(200.0, 340.0);

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
          if (onOpenQueue != null)
            IconButton(
              icon: const Icon(Icons.queue_music_rounded),
              tooltip: 'Cola de reproducción',
              onPressed: onOpenQueue,
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
                    onPressed: onToggleFavorite,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Barra de progreso interactiva
              ProgressBar(
                position: playbackState.position,
                duration: playbackState.duration,
                onSeek: (pos) => notifier.seek(pos),
              ),

              const SizedBox(height: 16),

              // Controles completos del reproductor
              PlayerControls(
                isPlaying: playbackState.isPlaying,
                isBuffering: playbackState.isBuffering,
                isShuffleEnabled: playbackState.isShuffleEnabled,
                loopMode: playbackState.loopMode,
                onPlayPause: () => notifier.togglePlayPause(),
                onPrevious: () => notifier.skipToPrevious(),
                onNext: () => notifier.skipToNext(),
                onToggleShuffle: () => notifier.toggleShuffle(),
                onCycleLoop: () => notifier.cycleLoopMode(),
                buttonSize: 32,
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
