import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/shared/base_domain/models/album.dart';
import 'package:pulso/shared/base_domain/models/artist.dart';
import 'package:pulso/shared/base_domain/models/track.dart';
import 'package:pulso/features/search/domain/use_cases/search_library_usecase.dart';

void main() {
  group('SearchLibraryUseCase', () {
    const useCase = SearchLibraryUseCase();

    final tracks = [
      const Track(
        id: '1',
        title: 'Noche Estrellada',
        artist: 'Pulso Sonora',
        album: 'Cosmos',
        durationMs: 190000,
        uri: 'uri/1',
      ),
      const Track(
        id: '2',
        title: 'Luz Lunar',
        artist: 'Astral Wave',
        album: 'Satélites',
        durationMs: 220000,
        uri: 'uri/2',
      ),
      const Track(
        id: '3',
        title: 'Gravedad Cero',
        artist: 'Pulso Sonora',
        album: 'Órbitas',
        durationMs: 250000,
        uri: 'uri/3',
      ),
    ];

    final albums = [
      const Album(
        id: 1,
        title: 'Cosmos',
        artist: 'Pulso Sonora',
        numOfSongs: 5,
      ),
      const Album(
        id: 2,
        title: 'Satélites',
        artist: 'Astral Wave',
        numOfSongs: 8,
      ),
    ];

    final artists = [
      const Artist(
        id: 1,
        name: 'Pulso Sonora',
        numOfTracks: 12,
        numOfAlbums: 2,
      ),
      const Artist(id: 2, name: 'Astral Wave', numOfTracks: 8, numOfAlbums: 1),
    ];

    test('retorna resultado vacío con consulta en blanco', () {
      final res = useCase(
        query: '   ',
        tracks: tracks,
        albums: albums,
        artists: artists,
      );
      expect(res.isEmpty, isTrue);
    });

    test('busca por título ignorando mayúsculas y minúsculas', () {
      final res = useCase(
        query: 'noche',
        tracks: tracks,
        albums: albums,
        artists: artists,
      );
      expect(res.tracks.length, 1);
      expect(res.tracks.first.title, 'Noche Estrellada');
    });

    test('busca por artista y encuentra coincidencias en canciones, álbumes y artistas', () {
      final res = useCase(
        query: 'pulso',
        tracks: tracks,
        albums: albums,
        artists: artists,
      );
      expect(res.tracks.length, 2);
      expect(res.albums.length, 1);
      expect(res.artists.length, 1);
    });

    test('busca por álbum adecuadamente', () {
      final res = useCase(
        query: 'cosmos',
        tracks: tracks,
        albums: albums,
        artists: artists,
      );
      expect(res.tracks.length, 1);
      expect(res.albums.length, 1);
    });
  });
}
