/// Contrato abstracto para el almacenamiento estructurado y persistencia de Pulso.
abstract class DatabaseService {
  Future<void> initialize();

  // Favoritos
  Future<Set<String>> getFavoriteTrackIds();
  Future<void> addFavorite(String trackId);
  Future<void> removeFavorite(String trackId);

  // Listas de reproducción
  Future<List<Map<String, dynamic>>> getPlaylists();
  Future<void> insertPlaylist(Map<String, dynamic> row);
  Future<void> updatePlaylist(String id, String name, int updatedAt);
  Future<void> deletePlaylist(String id);

  // Pistas en listas
  Future<List<String>> getPlaylistTrackIds(String playlistId);
  Future<void> insertPlaylistTrack(
    String playlistId,
    String trackId,
    int position,
  );
  Future<void> deletePlaylistTrack(String playlistId, String trackId);
  Future<void> updatePlaylistTracksOrder(
    String playlistId,
    List<String> trackIds,
  );

  // Preferencias y última sesión
  Future<String?> getPreference(String key);
  Future<void> setPreference(String key, String value);
  Future<void> close();
}
