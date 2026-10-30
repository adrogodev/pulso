import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/features/online_search/data/data_sources/remote/http_get.dart';
import 'package:pulso/features/online_search/data/data_sources/remote/internet_archive_remote_data_source.dart';
import 'package:pulso/features/online_search/data/data_sources/remote/jamendo_remote_data_source.dart';
import 'package:pulso/features/online_search/data/services/source_music_services.dart';

/// Responde según la ruta pedida y guarda cada URL.
HttpGet _fakeHttp(List<Uri> requested, Map<String, Object> byPath) {
  return (uri) async {
    requested.add(uri);
    final body = byPath[uri.path];
    if (body == null) throw Exception('sin respuesta para ${uri.path}');
    return jsonEncode(body);
  };
}

void main() {
  late List<Uri> requested;
  setUp(() => requested = []);

  group('JamendoMusicService', () {
    test('devuelve canciones completas e incluye el client_id', () async {
      final service = JamendoMusicService(
        JamendoRemoteDataSource(
          clientId: 'clave',
          httpGet: _fakeHttp(requested, {
            '/v3.0/tracks/': {
              'headers': {'status': 'success', 'code': 0},
              'results': [
                {
                  'id': '1532',
                  'name': 'Amanecer',
                  'duration': 215,
                  'artist_name': 'Nueva Banda',
                  'album_name': 'Primero',
                  'releasedate': '2025-02-01',
                  'audio': 'https://prod-1.storage.jamendo.com/?trackid=1532',
                  'image': 'https://usercontent.jamendo.com/a.jpg',
                },
              ],
            },
          }),
        ),
      );

      final track = (await service.searchTracks('amanecer')).dataOrNull!.single;

      expect(track.id, 'jamendo:1532');
      expect(track.duration, const Duration(seconds: 215));
      expect(track.year, 2025);
      expect(track.uri, 'https://prod-1.storage.jamendo.com/?trackid=1532');
      expect(requested.single.queryParameters['client_id'], 'clave');
      expect(requested.single.queryParameters['search'], 'amanecer');
    });

    test(
      'informa el rechazo del client_id como respuesta inesperada',
      () async {
        final service = JamendoMusicService(
          JamendoRemoteDataSource(
            clientId: 'mala',
            httpGet: _fakeHttp(requested, {
              '/v3.0/tracks/': {
                'headers': {
                  'status': 'failed',
                  'code': 5,
                  'error_message': 'Your credential is not authorized.',
                },
                'results': <Object>[],
              },
            }),
          ),
        );

        final result = await service.searchTracks('amanecer');

        expect(result.failureOrNull!.message, contains('respuesta inesperada'));
      },
    );
  });

  group('InternetArchiveMusicService', () {
    test('devuelve las pistas MP3 de cada ítem encontrado', () async {
      final service = InternetArchiveMusicService(
        InternetArchiveRemoteDataSource(
          httpGet: _fakeHttp(requested, {
            '/advancedsearch.php': {
              'response': {
                'docs': [
                  {'identifier': 'boleros1957'},
                  {'identifier': 'caido'},
                ],
              },
            },
            '/metadata/boleros1957': {
              'metadata': {
                'title': 'Boleros de 1957',
                'creator': ['Trío Antiguo'],
                'date': '1957-03-01',
              },
              'files': [
                {'name': '01 Besame.flac', 'format': 'Flac'},
                {'name': '01 Besame.mp3', 'title': 'Bésame', 'length': '185.4'},
                {'name': '01 Besame_64kb.mp3', 'title': 'Bésame'},
                {'name': '02 Luna.mp3', 'length': '03:05'},
              ],
            },
          }),
        ),
      );

      final tracks = (await service.searchTracks('boleros')).dataOrNull!;

      expect(tracks.map((t) => t.title), ['Bésame', '02 Luna']);
      final first = tracks.first;
      expect(first.id, 'archive:boleros1957/01 Besame.mp3');
      expect(first.artist, 'Trío Antiguo');
      expect(first.album, 'Boleros de 1957');
      expect(first.year, 1957);
      expect(first.duration, const Duration(seconds: 185));
      expect(tracks.last.duration, const Duration(seconds: 185));
      expect(
        first.uri,
        'https://archive.org/download/boleros1957/01%20Besame.mp3',
      );
      expect(first.artworkUrl, 'https://archive.org/services/img/boleros1957');
      // La consulta solo pide ítems de audio.
      expect(
        requested.first.queryParameters['q'],
        '(boleros) AND mediatype:(audio)',
      );
    });
  });
}
