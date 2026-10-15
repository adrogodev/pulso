import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulso/app/theme/app_colors.dart';
import 'package:pulso/app/theme/app_typography.dart';
import 'package:pulso/entities/playlist/playlist.dart';
import 'package:pulso/widgets/ui/pulso_waveform.dart';

import '../providers/playlists_notifier.dart';
import 'playlist_detail_screen.dart';

/// Pantalla principal para visualizar y gestionar listas de reproducción.
class PlaylistsScreen extends ConsumerWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistsNotifierProvider);
    final notifier = ref.read(playlistsNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'LISTAS DE REPRODUCCIÓN',
              style: AppTypography.titleMedium,
            ),
            Text(
              '${playlists.length} ${playlists.length == 1 ? 'lista' : 'listas'}',
              style: AppTypography.labelSmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 28),
            tooltip: 'Crear lista',
            onPressed: () => _showCreateDialog(context, notifier),
          ),
        ],
      ),
      body: playlists.isEmpty
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
                    'No tienes listas creadas',
                    style: AppTypography.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Crea listas para organizar tu música local',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Crear primera lista'),
                    onPressed: () => _showCreateDialog(context, notifier),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                final playlist = playlists[index];

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border, width: 0.6),
                    ),
                    child: const Icon(
                      Icons.queue_music_rounded,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  title: Text(
                    playlist.name,
                    style: AppTypography.bodyLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${playlist.trackCount} ${playlist.trackCount == 1 ? 'canción' : 'canciones'}',
                    style: AppTypography.labelSmall,
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: AppColors.iconMuted,
                    ),
                    color: AppColors.surfaceElevated,
                    onSelected: (action) {
                      if (action == 'rename') {
                        _showRenameDialog(context, notifier, playlist);
                      } else if (action == 'delete') {
                        _showDeleteDialog(context, notifier, playlist);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'rename',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_rounded,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(width: 10),
                            Text('Renombrar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: AppColors.error,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Eliminar',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            PlaylistDetailScreen(playlist: playlist),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  static void _showCreateDialog(
    BuildContext context,
    PlaylistsNotifier notifier,
  ) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva lista de reproducción'),
        content: TextField(
          controller: controller,
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
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await notifier.createPlaylist(name);
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

  static void _showRenameDialog(
    BuildContext context,
    PlaylistsNotifier notifier,
    Playlist playlist,
  ) {
    final controller = TextEditingController(text: playlist.name);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renombrar lista'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nuevo nombre'),
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
              final name = controller.text.trim();
              if (name.isNotEmpty && name != playlist.name) {
                await notifier.renamePlaylist(playlist.id, name);
                if (ctx.mounted) Navigator.of(ctx).pop();
              }
            },
            child: const Text(
              'Guardar',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  static void _showDeleteDialog(
    BuildContext context,
    PlaylistsNotifier notifier,
    Playlist playlist,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar lista?'),
        content: Text(
          'Se eliminará "${playlist.name}". Los archivos de música permanecerán intactos en tu dispositivo.',
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
              await notifier.deletePlaylist(playlist.id);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
