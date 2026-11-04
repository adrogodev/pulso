import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulso/shared/ui_kit/theme/app_colors.dart';
import 'package:pulso/shared/ui_kit/theme/app_typography.dart';
import 'package:pulso/shared/base_domain/models/playlist.dart';
import 'package:pulso/shared/base_domain/models/track.dart';
import 'package:pulso/features/library/presentation/controllers/library_notifier.dart';
import 'package:pulso/features/playback/presentation/controllers/playback_notifier.dart';
import 'package:pulso/features/playback/presentation/widgets/now_playing_navigation.dart';
import 'package:pulso/shared/ui_kit/widgets/pulso_waveform.dart';
import 'package:pulso/shared/ui_kit/widgets/track_artwork.dart';

import '../controllers/playlists_notifier.dart';

/// Pantalla de detalle de una lista de reproducción con ordenación y reproducción completa.
class PlaylistDetailScreen extends ConsumerStatefulWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  ConsumerState<PlaylistDetailScreen> createState() =>
      _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends ConsumerState<PlaylistDetailScreen> {
  List<Track> _tracks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    setState(() => _isLoading = true);
    final allTracks = ref.read(libraryNotifierProvider).tracks;
    final tracks = await ref
        .read(playlistsNotifierProvider.notifier)
        .getPlaylistTracks(widget.playlist.id, allTracks);

    if (mounted) {
      setState(() {
        _tracks = tracks;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final playbackNotifier = ref.read(playbackNotifierProvider.notifier);
    final playlistNotifier = ref.read(playlistsNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Text(widget.playlist.name, style: AppTypography.titleMedium),
        actions: [
          if (_tracks.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.play_circle_fill_rounded, size: 30),
              tooltip: 'Reproducir lista',
              onPressed: () => playbackNotifier.playTracks(_tracks),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.textPrimary),
              ),
            )
          : _tracks.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const PulsoWaveform(
                    width: 60,
                    height: 60,
                    color: AppColors.textDisabled,
                  ),
                  const SizedBox(height: 16),
                  const Text('Lista vacía', style: AppTypography.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    'Añade canciones desde la biblioteca musical',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _tracks.length,
              onReorderItem: (oldIndex, newIndex) async {
                setState(() {
                  var adjusted = newIndex;
                  if (oldIndex < adjusted) adjusted -= 1;
                  final item = _tracks.removeAt(oldIndex);
                  _tracks.insert(adjusted, item);
                });
                await playlistNotifier.reorderTracks(
                  widget.playlist.id,
                  oldIndex,
                  newIndex,
                );
              },
              itemBuilder: (context, index) {
                final track = _tracks[index];
                final trackArtworkId = int.tryParse(track.id);

                return Material(
                  key: ValueKey('playlist_track_${track.id}_$index'),
                  color: AppColors.primaryBackground,
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
                            Icons.drag_handle_rounded,
                            color: AppColors.iconMuted,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TrackArtwork(id: trackArtworkId, size: 44),
                      ],
                    ),
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
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline_rounded,
                        color: AppColors.iconMuted,
                        size: 20,
                      ),
                      tooltip: 'Quitar de la lista',
                      onPressed: () async {
                        await playlistNotifier.removeTrack(
                          widget.playlist.id,
                          track.id,
                        );
                        await _loadTracks();
                      },
                    ),
                    onTap: () => playOrOpenNowPlaying(
                      context,
                      ref,
                      track,
                      queue: _tracks,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
