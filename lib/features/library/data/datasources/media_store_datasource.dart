import 'package:flutter/foundation.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/result/result.dart';
import '../../../../entities/album/album.dart';
import '../../../../entities/artist/artist.dart';
import '../../../../entities/track/track.dart';

/// Fuente de datos abstracta para consultar el MediaStore de Android.
abstract class MediaStoreDataSource {
  Future<Result<List<Track>>> fetchSongs();
  Future<Result<List<Album>>> fetchAlbums();
  Future<Result<List<Artist>>> fetchArtists();
}

/// Implementación real mediante el paquete [OnAudioQuery].
class MediaStoreDataSourceImpl implements MediaStoreDataSource {
  final OnAudioQuery _audioQuery;

  MediaStoreDataSourceImpl({OnAudioQuery? audioQuery})
    : _audioQuery = audioQuery ?? OnAudioQuery();

  @override
  Future<Result<List<Track>>> fetchSongs() async {
    try {
      final songs = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      final tracks = <Track>[];
      for (final song in songs) {
        // Filtrar pistas de duración inválida o extremadamente cortas (< 3 segundos)
        final duration = song.duration ?? 0;
        if (duration < 3000) continue;

        final rawTitle = (song.title).trim();
        final title = rawTitle.isEmpty || rawTitle == '<unknown>'
            ? 'Título desconocido'
            : rawTitle;

        final rawArtist = (song.artist ?? '').trim();
        final artist = rawArtist.isEmpty || rawArtist == '<unknown>'
            ? 'Artista desconocido'
            : rawArtist;

        final rawAlbum = (song.album ?? '').trim();
        final album = rawAlbum.isEmpty || rawAlbum == '<unknown>'
            ? 'Álbum desconocido'
            : rawAlbum;

        final uri = song.uri ?? song.data;
        if (uri.isEmpty) continue;

        tracks.add(
          Track(
            id: song.id.toString(),
            title: title,
            artist: artist,
            album: album,
            durationMs: duration,
            uri: uri,
            trackNumber: song.track,
            genre: song.genre,
            fileExtension: song.fileExtension,
            albumId: song.albumId,
            size: song.size,
            dateAdded: song.dateAdded,
          ),
        );
      }

      return Result.ok(tracks);
    } catch (e, st) {
      debugPrint('Error al consultar MediaStore canciones: $e\n$st');
      return Result.err(
        AudioScanFailure(
          'No se pudieron leer las canciones del almacenamiento local',
          cause: e,
        ),
      );
    }
  }

  @override
  Future<Result<List<Album>>> fetchAlbums() async {
    try {
      final albums = await _audioQuery.queryAlbums(
        sortType: AlbumSortType.ALBUM,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      final list = albums.map((a) {
        final rawTitle = a.album.trim();
        final title = rawTitle.isEmpty || rawTitle == '<unknown>'
            ? 'Álbum desconocido'
            : rawTitle;

        final rawArtist = (a.artist ?? '').trim();
        final artist = rawArtist.isEmpty || rawArtist == '<unknown>'
            ? 'Artista desconocido'
            : rawArtist;

        return Album(
          id: a.id,
          title: title,
          artist: artist,
          numOfSongs: a.numOfSongs,
        );
      }).toList();

      return Result.ok(list);
    } catch (e) {
      return Result.err(
        AudioScanFailure(
          'No se pudieron leer los álbumes del almacenamiento local',
          cause: e,
        ),
      );
    }
  }

  @override
  Future<Result<List<Artist>>> fetchArtists() async {
    try {
      final artists = await _audioQuery.queryArtists(
        sortType: ArtistSortType.ARTIST,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      final list = artists.map((a) {
        final rawArtist = a.artist.trim();
        final name = rawArtist.isEmpty || rawArtist == '<unknown>'
            ? 'Artista desconocido'
            : rawArtist;

        return Artist(
          id: a.id,
          name: name,
          numOfTracks: a.numberOfTracks ?? 0,
          numOfAlbums: a.numberOfAlbums ?? 0,
        );
      }).toList();

      return Result.ok(list);
    } catch (e) {
      return Result.err(
        AudioScanFailure(
          'No se pudieron leer los artistas del almacenamiento local',
          cause: e,
        ),
      );
    }
  }
}
