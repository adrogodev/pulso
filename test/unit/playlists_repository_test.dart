import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/core/database/memory_database_service.dart';
import 'package:pulso/core/result/result.dart';
import 'package:pulso/entities/playlist/playlist.dart';
import 'package:pulso/features/playlists/data/repositories/playlists_repository_impl.dart';

void main() {
  group('PlaylistsRepositoryImpl', () {
    late MemoryDatabaseService dbService;
    late PlaylistsRepositoryImpl repository;

    setUp(() {
      dbService = MemoryDatabaseService();
      repository = PlaylistsRepositoryImpl(dbService);
    });

    tearDown(() async {
      await dbService.close();
    });

    test('crea, renombra, agrega pistas y elimina listas', () async {
      // 1. Crear lista
      final createRes = await repository.createPlaylist('Favoritas Rock');
      expect(createRes.isSuccess, isTrue);
      final playlist = (createRes as Success<Playlist>).data;
      expect(playlist.name, 'Favoritas Rock');

      // 2. Agregar pistas
      await repository.addTrackToPlaylist(playlist.id, 'track-1');
      await repository.addTrackToPlaylist(playlist.id, 'track-2');

      final trackIdsRes = await repository.getPlaylistTrackIds(playlist.id);
      expect((trackIdsRes as Success<List<String>>).data, [
        'track-1',
        'track-2',
      ]);

      // 3. Reordenar pistas
      await repository.reorderPlaylistTracks(playlist.id, 0, 2);
      final reorderedRes = await repository.getPlaylistTrackIds(playlist.id);
      expect((reorderedRes as Success<List<String>>).data, [
        'track-2',
        'track-1',
      ]);

      // 4. Renombrar lista
      await repository.renamePlaylist(playlist.id, 'Rock Clásico');
      final playlistsRes = await repository.getPlaylists();
      final all = (playlistsRes as Success<List<Playlist>>).data;
      expect(all.first.name, 'Rock Clásico');

      // 5. Eliminar pista
      await repository.removeTrackFromPlaylist(playlist.id, 'track-2');
      final tracksAfterRemove = await repository.getPlaylistTrackIds(
        playlist.id,
      );
      expect((tracksAfterRemove as Success<List<String>>).data, ['track-1']);

      // 6. Eliminar lista
      await repository.deletePlaylist(playlist.id);
      final emptyPlaylists = await repository.getPlaylists();
      expect((emptyPlaylists as Success<List<Playlist>>).data, isEmpty);
    });
  });
}
