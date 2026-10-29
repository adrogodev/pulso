import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/ui_kit/theme/app_colors.dart';
import '../../../../shared/ui_kit/theme/app_typography.dart';
import '../controllers/playback_notifier.dart';
import '../../../../shared/ui_kit/widgets/track_artwork.dart';

/// Mini reproductor persistente monocromático y sincronizado con el motor de audio.
class MiniPlayer extends ConsumerWidget {
  final VoidCallback? onTap;

  const MiniPlayer({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // La posición se escucha solo en [_MiniProgressBar] para no redibujar
    // todo el mini reproductor en cada tick.
    final track = ref.watch(
      playbackNotifierProvider.select((s) => s.currentTrack),
    );
    final isPlaying = ref.watch(
      playbackNotifierProvider.select((s) => s.isPlaying),
    );

    // Desaparece limpiamente si no hay pista cargada
    if (track == null) {
      return const SizedBox.shrink();
    }

    final notifier = ref.read(playbackNotifierProvider.notifier);
    final int? trackArtworkId = int.tryParse(track.id);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Material(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Barra de progreso delgada superior
                const _MiniProgressBar(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      // Carátula o fallback
                      TrackArtwork(
                        id: trackArtworkId,
                        size: 44,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      const SizedBox(width: 12),

                      // Título y Artista
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              track.title,
                              style: AppTypography.titleMedium.copyWith(
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              track.artist,
                              style: AppTypography.bodyMedium.copyWith(
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Botón Anterior (opcional en mini)
                      IconButton(
                        icon: const Icon(
                          Icons.skip_previous_rounded,
                          color: AppColors.iconActive,
                          size: 26,
                        ),
                        tooltip: 'Anterior',
                        onPressed: () => notifier.skipToPrevious(),
                      ),

                      // Botón Reproducir / Pausar
                      IconButton(
                        icon: Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: AppColors.iconActive,
                          size: 30,
                        ),
                        tooltip: isPlaying ? 'Pausar' : 'Reproducir',
                        onPressed: () => notifier.togglePlayPause(),
                      ),

                      // Botón Siguiente
                      IconButton(
                        icon: const Icon(
                          Icons.skip_next_rounded,
                          color: AppColors.iconActive,
                          size: 26,
                        ),
                        tooltip: 'Siguiente',
                        onPressed: () => notifier.skipToNext(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniProgressBar extends ConsumerWidget {
  const _MiniProgressBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(
      playbackNotifierProvider.select((s) => s.progress),
    );

    return LinearProgressIndicator(
      value: progress,
      backgroundColor: Colors.transparent,
      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.textPrimary),
      minHeight: 2,
    );
  }
}
