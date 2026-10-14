import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/core/result/result.dart';
import 'package:pulso/entities/album/album.dart';
import 'package:pulso/entities/artist/artist.dart';
import 'package:pulso/entities/track/track.dart';
import 'package:pulso/features/library/data/datasources/media_store_datasource.dart';
import 'package:pulso/features/library/data/repositories/audio_library_repository_impl.dart';

class FakeMediaStoreDataSource implements MediaStoreDataSource {
  int fetchSongsCount = 0;
  final List<Track> songs;

  FakeMediaStoreDataSource({required this.songs});

  @override
  Future<Result<List<Track>>> fetchSongs() async {
    fetchSongsCount++;
    return Result.ok(songs);
  }

  @override
  Future<Result<List<Album>>> fetchAlbums() async {
    return const Result.ok([
      Album(id: 1, title: 'Nocturno', artist: 'Pulso', numOfSongs: 3),
    ]);
  }

  @override
  Future<Result<List<Artist>>> fetchArtists() async {
    return const Result.ok([
      Artist(id: 1, name: 'Pulso', numOfTracks: 3, numOfAlbums: 1),
    ]);
  }
}

void main() {
  group('AudioLibraryRepositoryImpl', () {
    const track1 = Track(
      id: '1',
      title: 'Latido 1',
      artist: 'Pulso',
      album: 'Nocturno',
      durationMs: 180000,
      uri: '/storage/music/latido1.mp3',
    );
    const track2 = Track(
      id: '2',
      title: 'Latido 2',
      artist: 'Pulso',
      album: 'Diurno',
      durationMs: 200000,
      uri: '/storage/music/latido2.mp3',
    );

    test('reutiliza la caché en memoria y solo consulta la fuente cuando refresh=true', () async {
      final fakeDs = FakeMediaStoreDataSource(songs: [track1, track2]);
      final repo = AudioLibraryRepositoryImpl(fakeDs);

      final firstCall = await repo.getTracks();
      expect(firstCall.isSuccess, isTrue);
      expect(fakeDs.fetchSongsCount, 1);

      // Segunda llamada sin refresco no incrementa llamadas a la fuente
      final secondCall = await repo.getTracks();
      expect(secondCall.isSuccess, isTrue);
      expect(fakeDs.fetchSongsCount, 1);

      // Con refresh=true fuerza nueva consulta
      final refreshCall = await repo.getTracks(refresh: true);
      expect(refreshCall.isSuccess, isTrue);
      expect(fakeDs.fetchSongsCount, 2);
    });

    test('filtra canciones por álbum correctamente', () async {
      final fakeDs = FakeMediaStoreDataSource(songs: [track1, track2]);
      final repo = AudioLibraryRepositoryImpl(fakeDs);

      final albumTracksResult = await repo.getTracksByAlbum('Nocturno');
      expect(albumTracksResult.isSuccess, isTrue);
      final tracks = (albumTracksResult as Success<List<Track>>).data;
      expect(tracks.length, 1);
      expect(tracks.first.title, 'Latido 1');
    });

    test('obtiene pista por identificador', () async {
      final fakeDs = FakeMediaStoreDataSource(songs: [track1, track2]);
      final repo = AudioLibraryRepositoryImpl(fakeDs);

      final trackResult = await repo.getTrackById('2');
      expect(trackResult.isSuccess, isTrue);
      final track = (trackResult as Success<Track?>).data;
      expect(track?.title, 'Latido 2');

      final notFoundResult = await repo.getTrackById('999');
      expect((notFoundResult as Success<Track?>).data, isNull);
    });
  });
}
