import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/ui_kit/theme/app_colors.dart';
import '../../../../shared/ui_kit/theme/app_typography.dart';
import '../../../../shared/ui_kit/widgets/pulso_waveform.dart';
import '../../../../shared/ui_kit/widgets/track_artwork.dart';
import '../../../playback/presentation/controllers/playback_notifier.dart';

/// Pantalla interactiva para visualizar, reordenar y gestionar la cola de reproducción.
class QueueScreen extends ConsumerWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackState = ref.watch(playbackNotifierProvider);
    final notifier = ref.read(playbackNotifierProvider.notifier);
    final queue = playbackState.queue;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'COLA DE REPRODUCCIÓN',
              style: AppTypography.titleMedium,
            ),
            Text(
              '${queue.length} ${queue.length == 1 ? 'canción' : 'canciones'}',
              style: AppTypography.labelSmall,
            ),
          ],
        ),
        actions: [
          if (queue.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all_rounded),
              tooltip: 'Vaciar cola',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('¿Vaciar cola?'),
                    content: const Text(
                      'Se detendrá la reproducción y se limpiará la lista de espera.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text(
                          'Vaciar',
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await notifier.clearQueue();
                }
              },
            ),
        ],
      ),
      body: queue.isEmpty
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
                    'La cola está vacía',
                    style: AppTypography.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Reproduce una canción para comenzar la lista',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: queue.length,
              onReorderItem: (oldIndex, newIndex) {
                notifier.reorderQueue(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final track = queue[index];
                final isCurrent = index == playbackState.currentIndex;
                final trackArtworkId = int.tryParse(track.id);

                return Material(
                  key: ValueKey('queue_item_${track.id}_$index'),
                  color: isCurrent
                      ? AppColors.surfaceElevated
                      : AppColors.primaryBackground,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ReorderableDragStartListener(
                          index: index,
                          child: const Icon(
                            Icons.drag_indicator_rounded,
                            color: AppColors.iconMuted,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        TrackArtwork(
                          id: trackArtworkId,
                          size: 44,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    ),
                    title: Text(
                      track.title,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isCurrent
                            ? AppColors.textPrimary
                            : AppColors.textPrimary.withValues(alpha: 0.9),
                      ),
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
                        if (isCurrent)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(
                              playbackState.isPlaying
                                  ? Icons.volume_up_rounded
                                  : Icons.volume_mute_rounded,
                              color: AppColors.textPrimary,
                              size: 20,
                            ),
                          ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.iconMuted,
                            size: 20,
                          ),
                          tooltip: 'Quitar de la cola',
                          onPressed: () => notifier.removeFromQueue(index),
                        ),
                      ],
                    ),
                    onTap: () {
                      notifier.skipToIndex(index);
                    },
                  ),
                );
              },
            ),
    );
  }
}
