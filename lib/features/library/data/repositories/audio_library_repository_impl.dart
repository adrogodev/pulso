import '../../../../core/result/result.dart';
import '../../../../entities/album/album.dart';
import '../../../../entities/artist/artist.dart';
import '../../../../entities/track/track.dart';
import '../../domain/repositories/audio_library_repository.dart';
import '../datasources/media_store_datasource.dart';

/// Implementación del repositorio de biblioteca musical con caché en memoria.
class AudioLibraryRepositoryImpl implements AudioLibraryRepository {
  final MediaStoreDataSource _dataSource;

  List<Track>? _cachedTracks;
  List<Album>? _cachedAlbums;
  List<Artist>? _cachedArtists;

  AudioLibraryRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<Track>>> getTracks({bool refresh = false}) async {
    if (!refresh && _cachedTracks != null) {
      return Result.ok(_cachedTracks!);
    }

    final res = await _dataSource.fetchSongs();
    if (res is Success<List<Track>>) {
      _cachedTracks = res.data;
    }
    return res;
  }

  @override
  Future<Result<List<Album>>> getAlbums({bool refresh = false}) async {
    if (!refresh && _cachedAlbums != null) {
      return Result.ok(_cachedAlbums!);
    }

    final res = await _dataSource.fetchAlbums();
    if (res is Success<List<Album>>) {
      _cachedAlbums = res.data;
    }
    return res;
  }

  @override
  Future<Result<List<Artist>>> getArtists({bool refresh = false}) async {
    if (!refresh && _cachedArtists != null) {
      return Result.ok(_cachedArtists!);
    }

    final res = await _dataSource.fetchArtists();
    if (res is Success<List<Artist>>) {
      _cachedArtists = res.data;
    }
    return res;
  }

  @override
  Future<Result<Track?>> getTrackById(String id) async {
    final tracksResult = await getTracks();
    if (tracksResult is Err<List<Track>>) {
      return Result.err(tracksResult.failure);
    }
    final tracks = (tracksResult as Success<List<Track>>).data;
    for (final track in tracks) {
      if (track.id == id) {
        return Result.ok(track);
      }
    }
    return const Result.ok(null);
  }

  @override
  Future<Result<List<Track>>> getTracksByAlbum(String albumName) async {
    final tracksResult = await getTracks();
    if (tracksResult is Err<List<Track>>) {
      return Result.err(tracksResult.failure);
    }
    final tracks = (tracksResult as Success<List<Track>>).data;
    final filtered = tracks
        .where((t) => t.album.toLowerCase() == albumName.toLowerCase())
        .toList();
    return Result.ok(filtered);
  }

  @override
  Future<Result<List<Track>>> getTracksByArtist(String artistName) async {
    final tracksResult = await getTracks();
    if (tracksResult is Err<List<Track>>) {
      return Result.err(tracksResult.failure);
    }
    final tracks = (tracksResult as Success<List<Track>>).data;
    final filtered = tracks
        .where((t) => t.artist.toLowerCase() == artistName.toLowerCase())
        .toList();
    return Result.ok(filtered);
  }
}
