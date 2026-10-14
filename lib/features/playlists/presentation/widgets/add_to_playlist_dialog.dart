import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulso/app/theme/app_colors.dart';
import 'package:pulso/app/theme/app_typography.dart';
import 'package:pulso/entities/track/track.dart';

import '../providers/playlists_notifier.dart';

/// Diálogo para añadir una pista de audio a una lista de reproducción existente o nueva.
class AddToPlaylistDialog extends ConsumerWidget {
  final Track track;

  const AddToPlaylistDialog({super.key, required this.track});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistsNotifierProvider);
    final notifier = ref.read(playlistsNotifierProvider.notifier);

    return AlertDialog(
      title: const Text('AÑADIR A LISTA', style: AppTypography.titleMedium),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.add_circle_outline_rounded,
                color: AppColors.textPrimary,
              ),
              title: const Text(
                'Nueva lista de reproducción',
                style: AppTypography.bodyLarge,
              ),
              onTap: () async {
                Navigator.of(context).pop();
                _showCreatePlaylistDialog(context, notifier, track);
              },
            ),
            const Divider(),
            if (playlists.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No tienes listas creadas todavía',
                  style: AppTypography.bodyMedium,
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    return ListTile(
                      leading: const Icon(
                        Icons.playlist_play_rounded,
                        color: AppColors.textSecondary,
                      ),
                      title: Text(
                        playlist.name,
                        style: AppTypography.bodyLarge,
                      ),
                      subtitle: Text(
                        '${playlist.trackCount} ${playlist.trackCount == 1 ? 'canción' : 'canciones'}',
                        style: AppTypography.labelSmall,
                      ),
                      onTap: () async {
                        await notifier.addTrack(playlist.id, track.id);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Añadida a "${playlist.name}"'),
                              backgroundColor: AppColors.surfaceElevated,
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cerrar',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  static void _showCreatePlaylistDialog(
    BuildContext context,
    PlaylistsNotifier notifier,
    Track? initialTrack,
  ) {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva lista', style: AppTypography.titleMedium),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nombre de la lista'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              final name = textController.text.trim();
              if (name.isNotEmpty) {
                final created = await notifier.createPlaylist(name);
                if (created != null && initialTrack != null) {
                  await notifier.addTrack(created.id, initialTrack.id);
                }
                if (ctx.mounted) Navigator.of(ctx).pop();
              }
            },
            child: const Text(
              'Crear',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
