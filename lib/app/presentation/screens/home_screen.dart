import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/ui_kit/theme/app_colors.dart';
import '../../../shared/ui_kit/theme/app_typography.dart';
import '../../../shared/utils/metadata_formatter.dart';
import '../../../shared/base_domain/models/album.dart';
import '../../../shared/base_domain/models/artist.dart';
import '../../../shared/base_domain/models/track.dart';
import '../../../features/playback/presentation/widgets/mini_player.dart';
import '../../../shared/ui_kit/widgets/pulso_waveform.dart';
import '../../../shared/ui_kit/widgets/track_artwork.dart';
import '../../../shared/ui_kit/widgets/track_info_dialog.dart';
import '../../../features/favorites/presentation/controllers/favorites_notifier.dart';
import '../../../features/favorites/presentation/screens/favorites_screen.dart';
import '../../../features/playback/presentation/controllers/playback_notifier.dart';
import '../../../features/playback/presentation/screens/expanded_player_screen.dart';
import '../../../features/playlists/presentation/screens/playlists_screen.dart';
import '../../../features/playlists/presentation/widgets/add_to_playlist_dialog.dart';
import '../../../features/search/presentation/screens/search_screen.dart';
import '../../../features/settings/presentation/screens/settings_screen.dart';
import '../../../features/library/domain/use_cases/sort_tracks_usecase.dart';
import '../../../features/library/presentation/controllers/library_notifier.dart';
import '../../../features/library/presentation/controllers/library_state.dart';
import '../../../features/library/presentation/screens/album_detail_screen.dart';
import '../../../features/library/presentation/screens/artist_detail_screen.dart';

/// Pantalla principal de Pulso: biblioteca musical con canciones, álbumes, artistas y mini reproductor.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(libraryNotifierProvider.notifier).checkPermissionsAndLoad();
    });
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(libraryNotifierProvider);
    final libraryNotifier = ref.read(libraryNotifierProvider.notifier);
    // Solo lo que la lista necesita: escuchar el estado completo redibujaba
    // toda la pantalla en cada tick de posición.
    final nowPlaying = ref.watch(
      playbackNotifierProvider.select(
        (s) => (trackId: s.currentTrack?.id, isPlaying: s.isPlaying),
      ),
    );
    final playbackNotifier = ref.read(playbackNotifierProvider.notifier);
    final favorites = ref.watch(favoritesNotifierProvider);
    final favoritesNotifier = ref.read(favoritesNotifierProvider.notifier);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.primaryBackground,
        appBar: AppBar(
          backgroundColor: AppColors.primaryBackground,
          title: const Row(
            children: [
              PulsoWaveform(width: 26, height: 26),
              SizedBox(width: 10),
              Text('Pulso', style: AppTypography.titleLarge),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: AppColors.textPrimary),
              tooltip: 'Buscar',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SearchScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.favorite_border,
                color: AppColors.textPrimary,
              ),
              tooltip: 'Favoritos',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const FavoritesScreen(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.playlist_play,
                color: AppColors.textPrimary,
              ),
              tooltip: 'Listas',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PlaylistsScreen(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.settings_outlined,
                color: AppColors.textPrimary,
              ),
              tooltip: 'Ajustes',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Canciones'),
              Tab(text: 'Álbumes'),
              Tab(text: 'Artistas'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Barra de resumen y ordenación
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.surface,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${libraryState.tracks.length} canciones • ${libraryState.albums.length} álbumes',
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                  // Botón de ordenación
                  PopupMenuButton<TrackSortCriteria>(
                    icon: const Icon(
                      Icons.sort,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    tooltip: 'Ordenar por',
                    onSelected: (criteria) {
                      if (libraryState.sortCriteria == criteria) {
                        libraryNotifier.toggleSortOrder();
                      } else {
                        libraryNotifier.setSortCriteria(criteria);
                      }
                    },
                    itemBuilder: (ctx) => [
                      _sortItem(
                        TrackSortCriteria.title,
                        'Título',
                        libraryState.sortCriteria,
                        libraryState.sortOrder,
                      ),
                      _sortItem(
                        TrackSortCriteria.artist,
                        'Artista',
                        libraryState.sortCriteria,
                        libraryState.sortOrder,
                      ),
                      _sortItem(
                        TrackSortCriteria.album,
                        'Álbum',
                        libraryState.sortCriteria,
                        libraryState.sortOrder,
                      ),
                      _sortItem(
                        TrackSortCriteria.duration,
                        'Duración',
                        libraryState.sortCriteria,
                        libraryState.sortOrder,
                      ),
                    ],
                  ),
                  // Botón de refresco
                  IconButton(
                    icon: const Icon(
                      Icons.refresh,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    tooltip: 'Reescanear biblioteca',
                    onPressed: () => libraryNotifier.refreshLibrary(),
                  ),
                ],
              ),
            ),

            // Contenido de las pestañas
            Expanded(
              child: libraryState.isLoading
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(strokeWidth: 2),
                          SizedBox(height: 16),
                          Text(
                            'Buscando música en el dispositivo...',
                            style: AppTypography.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  : TabBarView(
                      children: [
                        // Pestaña 1: Canciones
                        _buildTracksTab(
                          context,
                          libraryState.sortedTracks,
                          nowPlaying,
                          playbackNotifier,
                          favorites,
                          favoritesNotifier,
                          libraryNotifier,
                        ),

                        // Pestaña 2: Álbumes
                        _buildAlbumsTab(
                          context,
                          libraryState.albums,
                          libraryState,
                        ),

                        // Pestaña 3: Artistas
                        _buildArtistsTab(
                          context,
                          libraryState.artists,
                          libraryState,
                        ),
                      ],
                    ),
            ),

            // Mini Reproductor acoplado
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
      ),
    );
  }

  PopupMenuItem<TrackSortCriteria> _sortItem(
    TrackSortCriteria value,
    String label,
    TrackSortCriteria current,
    SortOrder order,
  ) {
    final isSelected = current == value;
    final suffix = isSelected
        ? (order == SortOrder.ascending ? ' ↑' : ' ↓')
        : '';
    return PopupMenuItem<TrackSortCriteria>(
      value: value,
      child: Text(
        '$label$suffix',
        style: TextStyle(
          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildTracksTab(
    BuildContext context,
    List<Track> tracks,
    ({String? trackId, bool isPlaying}) nowPlaying,
    PlaybackNotifier playbackNotifier,
    Set<String> favorites,
    FavoritesNotifier favoritesNotifier,
    LibraryNotifier libraryNotifier,
  ) {
    if (tracks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PulsoWaveform(width: 64, height: 64),
              const SizedBox(height: 20),
              const Text(
                'No se encontraron canciones',
                style: AppTypography.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Asegúrate de tener música en tu dispositivo y haber concedido los permisos de almacenamiento.',
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => libraryNotifier.checkPermissionsAndLoad(),
                icon: const Icon(Icons.refresh),
                label: const Text('Escanear biblioteca'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: tracks.length,
      itemBuilder: (ctx, index) {
        final track = tracks[index];
        final isCurrent = nowPlaying.trackId == track.id;
        final isFav = favorites.contains(track.id);

        return ListTile(
          leading: TrackArtwork(
            id: int.tryParse(track.id),
            size: 48,
            borderRadius: BorderRadius.circular(6),
          ),
          title: Text(
            track.title,
            style: AppTypography.bodyLarge.copyWith(
              color: isCurrent
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${track.artist} • ${MetadataFormatter.formatDurationMs(track.duration.inMilliseconds)}',
            style: AppTypography.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isCurrent && nowPlaying.isPlaying)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: PulsoWaveform(width: 20, height: 16),
                ),
              PopupMenuButton<String>(
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
                            content: Text('Se reproducirá a continuación'),
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
                        await AddToPlaylistDialog.show(context, track: track);
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
                      isFav ? 'Quitar de favoritos' : 'Añadir a favoritos',
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
            ],
          ),
          onTap: () => playbackNotifier.playTracks(tracks, initialIndex: index),
        );
      },
    );
  }

  Widget _buildAlbumsTab(
    BuildContext context,
    List<Album> albums,
    LibraryState libraryState,
  ) {
    if (albums.isEmpty) {
      return const Center(
        child: Text(
          'No hay álbumes disponibles',
          style: AppTypography.bodyMedium,
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.78,
      ),
      itemCount: albums.length,
      itemBuilder: (ctx, index) {
        final album = albums[index];
        final matchingTracks = libraryState.tracks
            .where((t) => t.albumId == album.id || t.album == album.title)
            .toList();
        final firstTrackId = matchingTracks.isNotEmpty
            ? matchingTracks.first.id
            : null;

        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => AlbumDetailScreen(
                  album: album,
                  initialTracks: matchingTracks,
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: TrackArtwork(
                    id: int.tryParse(firstTrackId ?? ''),
                    size: double.infinity,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                album.title,
                style: AppTypography.bodyLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                album.artist,
                style: AppTypography.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${album.numOfSongs} canciones',
                style: AppTypography.labelSmall,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildArtistsTab(
    BuildContext context,
    List<Artist> artists,
    LibraryState libraryState,
  ) {
    if (artists.isEmpty) {
      return const Center(
        child: Text(
          'No hay artistas disponibles',
          style: AppTypography.bodyMedium,
        ),
      );
    }

    return ListView.builder(
      itemCount: artists.length,
      itemBuilder: (ctx, index) {
        final artist = artists[index];
        final matchingTracks = libraryState.tracks
            .where((t) => t.artist == artist.name)
            .toList();

        return ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
            ),
            child: const Center(
              child: Icon(Icons.person, color: AppColors.textSecondary),
            ),
          ),
          title: Text(artist.name, style: AppTypography.bodyLarge),
          subtitle: Text(
            '${artist.numOfAlbums} ${artist.numOfAlbums == 1 ? "álbum" : "álbumes"} • ${artist.numOfTracks} canciones',
            style: AppTypography.bodyMedium,
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: AppColors.textSecondary,
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ArtistDetailScreen(
                  artist: artist,
                  initialTracks: matchingTracks,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
