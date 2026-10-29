import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulso/shared/base_domain/result/result.dart';
import 'package:pulso/shared/base_domain/models/playlist.dart';
import 'package:pulso/shared/base_domain/models/track.dart';
import 'package:pulso/features/favorites/presentation/controllers/favorites_notifier.dart';

import '../../data/services/playlists_repository_impl.dart';
import '../../domain/services/playlists_repository.dart';

final playlistsRepositoryProvider = Provider<PlaylistsRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return PlaylistsRepositoryImpl(dbService);
});

final playlistsNotifierProvider =
    NotifierProvider<PlaylistsNotifier, List<Playlist>>(PlaylistsNotifier.new);

class PlaylistsNotifier extends Notifier<List<Playlist>> {
  PlaylistsRepository get _repo => ref.read(playlistsRepositoryProvider);

  @override
  List<Playlist> build() {
    loadPlaylists();
    return const [];
  }

  Future<void> loadPlaylists() async {
    final result = await _repo.getPlaylists();
    if (result is Success<List<Playlist>>) {
      state = result.data;
    }
  }

  Future<Playlist?> createPlaylist(String name) async {
    final result = await _repo.createPlaylist(name);
    if (result is Success<Playlist>) {
      await loadPlaylists();
      return result.data;
    }
    return null;
  }

  Future<void> renamePlaylist(String id, String newName) async {
    final result = await _repo.renamePlaylist(id, newName);
    if (result is Success) {
      await loadPlaylists();
    }
  }

  Future<void> deletePlaylist(String id) async {
    final result = await _repo.deletePlaylist(id);
    if (result is Success) {
      await loadPlaylists();
    }
  }

  Future<void> addTrack(String playlistId, String trackId) async {
    final result = await _repo.addTrackToPlaylist(playlistId, trackId);
    if (result is Success) {
      await loadPlaylists();
    }
  }

  Future<void> removeTrack(String playlistId, String trackId) async {
    final result = await _repo.removeTrackFromPlaylist(playlistId, trackId);
    if (result is Success) {
      await loadPlaylists();
    }
  }

  Future<void> reorderTracks(
    String playlistId,
    int oldIndex,
    int newIndex,
  ) async {
    await _repo.reorderPlaylistTracks(playlistId, oldIndex, newIndex);
    await loadPlaylists();
  }

  Future<List<Track>> getPlaylistTracks(
    String playlistId,
    List<Track> allLibraryTracks,
  ) async {
    final result = await _repo.getPlaylistTrackIds(playlistId);
    if (result is! Success<List<String>>) return [];

    final trackIds = result.data;
    final trackMap = {for (final t in allLibraryTracks) t.id: t};

    final playlistTracks = <Track>[];
    for (final id in trackIds) {
      final found = trackMap[id];
      if (found != null) {
        playlistTracks.add(found);
      }
    }
    return playlistTracks;
  }
}
