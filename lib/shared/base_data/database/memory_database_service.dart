import 'database_service.dart';

/// Implementación en memoria de [DatabaseService] para pruebas rápidas y deterministas.
class MemoryDatabaseService implements DatabaseService {
  final Set<String> _favorites = {};
  final Map<String, Map<String, dynamic>> _playlists = {};
  final Map<String, List<String>> _playlistTracks = {};
  final Map<String, String> _preferences = {};

  @override
  Future<void> initialize() async {}

  @override
  Future<Set<String>> getFavoriteTrackIds() async {
    return Set.unmodifiable(_favorites);
  }

  @override
  Future<void> addFavorite(String trackId) async {
    _favorites.add(trackId);
  }

  @override
  Future<void> removeFavorite(String trackId) async {
    _favorites.remove(trackId);
  }

  @override
  Future<List<Map<String, dynamic>>> getPlaylists() async {
    return _playlists.values.map((p) => Map<String, dynamic>.from(p)).toList();
  }

  @override
  Future<void> insertPlaylist(Map<String, dynamic> row) async {
    final id = row['id'] as String;
    _playlists[id] = Map<String, dynamic>.from(row);
    _playlistTracks[id] = [];
  }

  @override
  Future<void> updatePlaylist(String id, String name, int updatedAt) async {
    if (_playlists.containsKey(id)) {
      _playlists[id]!['name'] = name;
      _playlists[id]!['updated_at'] = updatedAt;
    }
  }

  @override
  Future<void> deletePlaylist(String id) async {
    _playlists.remove(id);
    _playlistTracks.remove(id);
  }

  @override
  Future<List<String>> getPlaylistTrackIds(String playlistId) async {
    return List.unmodifiable(_playlistTracks[playlistId] ?? []);
  }

  @override
  Future<void> insertPlaylistTrack(
    String playlistId,
    String trackId,
    int position,
  ) async {
    final list = _playlistTracks.putIfAbsent(playlistId, () => []);
    if (!list.contains(trackId)) {
      list.add(trackId);
    }
    if (_playlists.containsKey(playlistId)) {
      _playlists[playlistId]!['updated_at'] =
          DateTime.now().millisecondsSinceEpoch;
    }
  }

  @override
  Future<void> deletePlaylistTrack(String playlistId, String trackId) async {
    final list = _playlistTracks[playlistId];
    if (list != null) {
      list.remove(trackId);
      if (_playlists.containsKey(playlistId)) {
        _playlists[playlistId]!['updated_at'] =
            DateTime.now().millisecondsSinceEpoch;
      }
    }
  }

  @override
  Future<void> updatePlaylistTracksOrder(
    String playlistId,
    List<String> trackIds,
  ) async {
    _playlistTracks[playlistId] = List.from(trackIds);
    if (_playlists.containsKey(playlistId)) {
      _playlists[playlistId]!['updated_at'] =
          DateTime.now().millisecondsSinceEpoch;
    }
  }

  @override
  Future<String?> getPreference(String key) async {
    return _preferences[key];
  }

  @override
  Future<void> setPreference(String key, String value) async {
    _preferences[key] = value;
  }

  @override
  Future<void> close() async {
    _favorites.clear();
    _playlists.clear();
    _playlistTracks.clear();
    _preferences.clear();
  }
}
