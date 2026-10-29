import 'package:pulso/shared/base_data/database/database_service.dart';
import 'package:pulso/shared/base_domain/error/failures.dart';
import 'package:pulso/shared/base_domain/result/result.dart';
import 'package:pulso/shared/base_domain/models/playlist.dart';
import 'package:uuid/uuid.dart';

import '../../domain/services/playlists_repository.dart';

class PlaylistsRepositoryImpl implements PlaylistsRepository {
  final DatabaseService _dbService;
  final Uuid _uuid;

  PlaylistsRepositoryImpl(this._dbService, [Uuid? uuid])
    : _uuid = uuid ?? const Uuid();

  @override
  Future<Result<List<Playlist>>> getPlaylists() async {
    try {
      final rows = await _dbService.getPlaylists();
      final list = <Playlist>[];

      for (final r in rows) {
        final id = r['id'] as String;
        final trackIds = await _dbService.getPlaylistTrackIds(id);
        list.add(
          Playlist(
            id: id,
            name: r['name'] as String,
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              r['created_at'] as int,
            ),
            updatedAt: DateTime.fromMillisecondsSinceEpoch(
              r['updated_at'] as int,
            ),
            trackCount: trackIds.length,
          ),
        );
      }

      return Result.ok(list);
    } catch (e) {
      return Result.err(
        StorageFailure('Error al leer listas de reproducción', cause: e),
      );
    }
  }

  @override
  Future<Result<Playlist>> createPlaylist(String name) async {
    try {
      final id = _uuid.v4();
      final now = DateTime.now();
      final row = {
        'id': id,
        'name': name.trim(),
        'created_at': now.millisecondsSinceEpoch,
        'updated_at': now.millisecondsSinceEpoch,
      };

      await _dbService.insertPlaylist(row);
      return Result.ok(
        Playlist(
          id: id,
          name: name.trim(),
          createdAt: now,
          updatedAt: now,
          trackCount: 0,
        ),
      );
    } catch (e) {
      return Result.err(
        StorageFailure('Error al crear lista de reproducción', cause: e),
      );
    }
  }

  @override
  Future<Result<void>> renamePlaylist(String id, String newName) async {
    try {
      await _dbService.updatePlaylist(
        id,
        newName.trim(),
        DateTime.now().millisecondsSinceEpoch,
      );
      return const Result.ok(null);
    } catch (e) {
      return Result.err(
        StorageFailure('Error al renombrar lista de reproducción', cause: e),
      );
    }
  }

  @override
  Future<Result<void>> deletePlaylist(String id) async {
    try {
      await _dbService.deletePlaylist(id);
      return const Result.ok(null);
    } catch (e) {
      return Result.err(
        StorageFailure('Error al eliminar lista de reproducción', cause: e),
      );
    }
  }

  @override
  Future<Result<List<String>>> getPlaylistTrackIds(String playlistId) async {
    try {
      final ids = await _dbService.getPlaylistTrackIds(playlistId);
      return Result.ok(ids);
    } catch (e) {
      return Result.err(
        StorageFailure('Error al leer pistas de la lista', cause: e),
      );
    }
  }

  @override
  Future<Result<void>> addTrackToPlaylist(
    String playlistId,
    String trackId,
  ) async {
    try {
      final existing = await _dbService.getPlaylistTrackIds(playlistId);
      if (!existing.contains(trackId)) {
        await _dbService.insertPlaylistTrack(
          playlistId,
          trackId,
          existing.length,
        );
      }
      return const Result.ok(null);
    } catch (e) {
      return Result.err(
        StorageFailure('Error al añadir canción a la lista', cause: e),
      );
    }
  }

  @override
  Future<Result<void>> removeTrackFromPlaylist(
    String playlistId,
    String trackId,
  ) async {
    try {
      await _dbService.deletePlaylistTrack(playlistId, trackId);
      return const Result.ok(null);
    } catch (e) {
      return Result.err(
        StorageFailure('Error al remover canción de la lista', cause: e),
      );
    }
  }

  @override
  Future<Result<void>> reorderPlaylistTracks(
    String playlistId,
    int oldIndex,
    int newIndex,
  ) async {
    try {
      final ids = await _dbService.getPlaylistTrackIds(playlistId);
      if (oldIndex < 0 ||
          oldIndex >= ids.length ||
          newIndex < 0 ||
          newIndex > ids.length) {
        return const Result.ok(null);
      }

      final updated = List<String>.from(ids);
      var adjustedNewIndex = newIndex;
      if (oldIndex < adjustedNewIndex) {
        adjustedNewIndex -= 1;
      }
      final moved = updated.removeAt(oldIndex);
      updated.insert(adjustedNewIndex, moved);

      await _dbService.updatePlaylistTracksOrder(playlistId, updated);
      return const Result.ok(null);
    } catch (e) {
      return Result.err(
        StorageFailure('Error al reordenar lista de reproducción', cause: e),
      );
    }
  }
}
