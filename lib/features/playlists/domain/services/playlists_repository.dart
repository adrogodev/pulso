import 'package:pulso/shared/base_domain/result/result.dart';
import 'package:pulso/shared/base_domain/models/playlist.dart';

/// Contrato del repositorio para la gestión completa de listas de reproducción.
abstract class PlaylistsRepository {
  Future<Result<List<Playlist>>> getPlaylists();
  Future<Result<Playlist>> createPlaylist(String name);
  Future<Result<void>> renamePlaylist(String id, String newName);
  Future<Result<void>> deletePlaylist(String id);
  Future<Result<List<String>>> getPlaylistTrackIds(String playlistId);
  Future<Result<void>> addTrackToPlaylist(String playlistId, String trackId);
  Future<Result<void>> removeTrackFromPlaylist(
    String playlistId,
    String trackId,
  );
  Future<Result<void>> reorderPlaylistTracks(
    String playlistId,
    int oldIndex,
    int newIndex,
  );
}
