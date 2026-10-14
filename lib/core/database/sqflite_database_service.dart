import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'database_service.dart';

/// Implementación real de SQLite con soporte para migraciones y transacciones.
class SqfliteDatabaseService implements DatabaseService {
  Database? _db;

  @override
  Future<void> initialize() async {
    if (_db != null) return;

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'pulso_music.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE favorites (
            track_id TEXT PRIMARY KEY,
            added_at INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE playlists (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE playlist_tracks (
            playlist_id TEXT NOT NULL,
            track_id TEXT NOT NULL,
            position INTEGER NOT NULL,
            PRIMARY KEY (playlist_id, track_id),
            FOREIGN KEY (playlist_id) REFERENCES playlists (id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE preferences (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE playback_session (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            track_id TEXT,
            position_ms INTEGER,
            updated_at INTEGER
          )
        ''');
      },
    );
  }

  Database get _database {
    final db = _db;
    if (db == null) {
      throw StateError('La base de datos SQLite no ha sido inicializada.');
    }
    return db;
  }

  @override
  Future<Set<String>> getFavoriteTrackIds() async {
    final rows = await _database.query('favorites', columns: ['track_id']);
    return rows.map((r) => r['track_id'] as String).toSet();
  }

  @override
  Future<void> addFavorite(String trackId) async {
    await _database.insert('favorites', {
      'track_id': trackId,
      'added_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> removeFavorite(String trackId) async {
    await _database.delete(
      'favorites',
      where: 'track_id = ?',
      whereArgs: [trackId],
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getPlaylists() async {
    return _database.query('playlists', orderBy: 'updated_at DESC');
  }

  @override
  Future<void> insertPlaylist(Map<String, dynamic> row) async {
    await _database.insert(
      'playlists',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updatePlaylist(String id, String name, int updatedAt) async {
    await _database.update(
      'playlists',
      {'name': name, 'updated_at': updatedAt},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deletePlaylist(String id) async {
    await _database.transaction((txn) async {
      await txn.delete(
        'playlist_tracks',
        where: 'playlist_id = ?',
        whereArgs: [id],
      );
      await txn.delete('playlists', where: 'id = ?', whereArgs: [id]);
    });
  }

  @override
  Future<List<String>> getPlaylistTrackIds(String playlistId) async {
    final rows = await _database.query(
      'playlist_tracks',
      columns: ['track_id'],
      where: 'playlist_id = ?',
      whereArgs: [playlistId],
      orderBy: 'position ASC',
    );
    return rows.map((r) => r['track_id'] as String).toList();
  }

  @override
  Future<void> insertPlaylistTrack(
    String playlistId,
    String trackId,
    int position,
  ) async {
    await _database.insert('playlist_tracks', {
      'playlist_id': playlistId,
      'track_id': trackId,
      'position': position,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    await updatePlaylist(playlistId, '', DateTime.now().millisecondsSinceEpoch);
  }

  @override
  Future<void> deletePlaylistTrack(String playlistId, String trackId) async {
    await _database.delete(
      'playlist_tracks',
      where: 'playlist_id = ? AND track_id = ?',
      whereArgs: [playlistId, trackId],
    );
  }

  @override
  Future<void> updatePlaylistTracksOrder(
    String playlistId,
    List<String> trackIds,
  ) async {
    await _database.transaction((txn) async {
      await txn.delete(
        'playlist_tracks',
        where: 'playlist_id = ?',
        whereArgs: [playlistId],
      );
      for (var i = 0; i < trackIds.length; i++) {
        await txn.insert('playlist_tracks', {
          'playlist_id': playlistId,
          'track_id': trackIds[i],
          'position': i,
        });
      }
    });
  }

  @override
  Future<String?> getPreference(String key) async {
    final rows = await _database.query(
      'preferences',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  @override
  Future<void> setPreference(String key, String value) async {
    await _database.insert('preferences', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
