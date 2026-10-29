import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/base_data/permissions/permission_service.dart';
import '../../../../shared/base_domain/result/result.dart';
import '../../../../shared/base_domain/models/track.dart';
import '../../data/data_sources/local/media_store_datasource_provider.dart';
import '../../data/services/audio_library_repository_impl.dart';
import '../../domain/services/audio_library_repository.dart';
import '../../domain/use_cases/get_albums_usecase.dart';
import '../../domain/use_cases/get_artists_usecase.dart';
import '../../domain/use_cases/get_tracks_usecase.dart';
import '../../domain/use_cases/sort_tracks_usecase.dart';
import 'library_state.dart';

// Providers de infraestructura e inversión de dependencias
final permissionServiceProvider = Provider<PermissionService>((ref) {
  return const PermissionServiceImpl();
});

final audioLibraryRepositoryProvider = Provider<AudioLibraryRepository>((ref) {
  final dataSource = ref.watch(mediaStoreDataSourceProvider);
  return AudioLibraryRepositoryImpl(dataSource);
});

final getTracksUseCaseProvider = Provider<GetTracksUseCase>((ref) {
  final repo = ref.watch(audioLibraryRepositoryProvider);
  return GetTracksUseCase(repo);
});

final getAlbumsUseCaseProvider = Provider<GetAlbumsUseCase>((ref) {
  final repo = ref.watch(audioLibraryRepositoryProvider);
  return GetAlbumsUseCase(repo);
});

final getArtistsUseCaseProvider = Provider<GetArtistsUseCase>((ref) {
  final repo = ref.watch(audioLibraryRepositoryProvider);
  return GetArtistsUseCase(repo);
});

final libraryNotifierProvider = NotifierProvider<LibraryNotifier, LibraryState>(
  LibraryNotifier.new,
);

class LibraryNotifier extends Notifier<LibraryState> {
  PermissionService get _permissionService =>
      ref.read(permissionServiceProvider);
  GetTracksUseCase get _getTracksUseCase => ref.read(getTracksUseCaseProvider);
  GetAlbumsUseCase get _getAlbumsUseCase => ref.read(getAlbumsUseCaseProvider);
  GetArtistsUseCase get _getArtistsUseCase =>
      ref.read(getArtistsUseCaseProvider);

  @override
  LibraryState build() {
    return const LibraryState();
  }

  Future<void> checkPermissionsAndLoad() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final permResult = await _permissionService.hasAudioPermission();
    final hasPerm = permResult.when(
      ok: (granted) => granted,
      err: (_) => false,
    );

    state = state.copyWith(hasPermission: hasPerm);

    if (hasPerm) {
      await _loadLibrary();
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> requestPermissions() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final permResult = await _permissionService.requestAudioPermission();
    if (permResult is Success<bool> && permResult.data) {
      state = state.copyWith(hasPermission: true);
      await _loadLibrary();
    } else {
      final msg = permResult is Err<bool>
          ? permResult.failure.message
          : 'Se requieren permisos para acceder a tu música local.';
      state = state.copyWith(
        isLoading: false,
        hasPermission: false,
        errorMessage: msg,
      );
    }
  }

  Future<void> refreshLibrary() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await _loadLibrary(refresh: true);
  }

  Future<void> _loadLibrary({bool refresh = false}) async {
    final tracksRes = await _getTracksUseCase(refresh: refresh);
    final albumsRes = await _getAlbumsUseCase(refresh: refresh);
    final artistsRes = await _getArtistsUseCase(refresh: refresh);

    if (tracksRes is Success<List<Track>>) {
      state = state.copyWith(
        tracks: tracksRes.data,
        albums: albumsRes.dataOrNull ?? state.albums,
        artists: artistsRes.dataOrNull ?? state.artists,
        isLoading: false,
        clearError: true,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            tracksRes.failureOrNull?.message ??
            'Error al cargar la biblioteca musical.',
      );
    }
  }

  void setSortCriteria(TrackSortCriteria criteria) {
    state = state.copyWith(sortCriteria: criteria);
  }

  void toggleSortOrder() {
    state = state.copyWith(
      sortOrder: state.sortOrder == SortOrder.ascending
          ? SortOrder.descending
          : SortOrder.ascending,
    );
  }
}
