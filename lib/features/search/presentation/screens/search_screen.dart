import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/ui_kit/theme/app_colors.dart';
import '../../../../shared/ui_kit/theme/app_typography.dart';
import '../../../../shared/ui_kit/widgets/pulso_waveform.dart';
import '../../../../shared/ui_kit/widgets/track_artwork.dart';
import '../../../../shared/utils/metadata_formatter.dart';
import '../../../playback/presentation/controllers/playback_notifier.dart';
import '../controllers/search_notifier.dart';
import '../controllers/search_state.dart';

/// Pantalla de búsqueda local con filtrado por canciones, artistas y álbumes.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchNotifierProvider);
    final notifier = ref.read(searchNotifierProvider.notifier);
    final playbackNotifier = ref.read(playbackNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: const Text('BÚSQUEDA', style: AppTypography.titleMedium),
      ),
      body: Column(
        children: [
          // Campo de búsqueda de texto
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _controller,
              style: AppTypography.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Buscar canciones, artistas o álbumes...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textSecondary,
                ),
                suffixIcon: searchState.hasQuery
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear_rounded,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          _controller.clear();
                          notifier.clearSearch();
                        },
                      )
                    : null,
              ),
              onChanged: (text) => notifier.onQueryChanged(text),
            ),
          ),

          // Chips de filtro
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    'Todo',
                    SearchFilter.all,
                    searchState.activeFilter,
                    notifier,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Canciones',
                    SearchFilter.tracks,
                    searchState.activeFilter,
                    notifier,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Álbumes',
                    SearchFilter.albums,
                    searchState.activeFilter,
                    notifier,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Artistas',
                    SearchFilter.artists,
                    searchState.activeFilter,
                    notifier,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Contenido principal de resultados o estado vacío
          Expanded(child: _buildBody(searchState, playbackNotifier)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    SearchFilter filter,
    SearchFilter current,
    SearchNotifier notifier,
  ) {
    final isSelected = filter == current;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => notifier.setFilter(filter),
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.textPrimary,
      labelStyle: TextStyle(
        color: isSelected
            ? AppColors.primaryBackground
            : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? AppColors.textPrimary : AppColors.border,
          width: 0.8,
        ),
      ),
    );
  }

  Widget _buildBody(SearchState state, PlaybackNotifier playbackNotifier) {
    if (!state.hasQuery) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PulsoWaveform(
              width: 60,
              height: 60,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: 16),
            const Text('Explora tu música', style: AppTypography.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Escribe el nombre de una pista, artista o álbum',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final result = state.result;
    final showTracks =
        state.activeFilter == SearchFilter.all ||
        state.activeFilter == SearchFilter.tracks;
    final showAlbums =
        state.activeFilter == SearchFilter.all ||
        state.activeFilter == SearchFilter.albums;
    final showArtists =
        state.activeFilter == SearchFilter.all ||
        state.activeFilter == SearchFilter.artists;

    final hasAnyMatch =
        (showTracks && result.tracks.isNotEmpty) ||
        (showAlbums && result.albums.isNotEmpty) ||
        (showArtists && result.artists.isNotEmpty);

    if (!hasAnyMatch) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 54,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: 12),
            Text(
              'Sin coincidencias para "${state.query}"',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'Prueba con otro término de búsqueda',
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (showTracks && result.tracks.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text('CANCIONES', style: AppTypography.labelSmall),
          ),
          ...result.tracks.map((track) {
            final trackArtworkId = int.tryParse(track.id);
            return ListTile(
              leading: TrackArtwork(id: trackArtworkId, size: 44),
              title: Text(
                track.title,
                style: AppTypography.bodyLarge,
                maxLines: 1,
              ),
              subtitle: Text(
                track.artist,
                style: AppTypography.bodyMedium,
                maxLines: 1,
              ),
              trailing: Text(
                track.formattedDuration,
                style: AppTypography.labelSmall,
              ),
              onTap: () {
                playbackNotifier.playTrack(track, inQueue: result.tracks);
              },
            );
          }),
        ],

        if (showAlbums && result.albums.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('ÁLBUMES', style: AppTypography.labelSmall),
          ),
          ...result.albums.map((album) {
            return ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border, width: 0.6),
                ),
                child: const Icon(
                  Icons.album_rounded,
                  color: AppColors.textSecondary,
                ),
              ),
              title: Text(
                album.title,
                style: AppTypography.bodyLarge,
                maxLines: 1,
              ),
              subtitle: Text(
                album.artist,
                style: AppTypography.bodyMedium,
                maxLines: 1,
              ),
              trailing: Text(
                MetadataFormatter.formatSongCount(album.numOfSongs),
                style: AppTypography.labelSmall,
              ),
            );
          }),
        ],

        if (showArtists && result.artists.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('ARTISTAS', style: AppTypography.labelSmall),
          ),
          ...result.artists.map((artist) {
            return ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.textSecondary,
                ),
              ),
              title: Text(
                artist.name,
                style: AppTypography.bodyLarge,
                maxLines: 1,
              ),
              trailing: Text(
                '${artist.numOfTracks} pistas',
                style: AppTypography.labelSmall,
              ),
            );
          }),
        ],
      ],
    );
  }
}
