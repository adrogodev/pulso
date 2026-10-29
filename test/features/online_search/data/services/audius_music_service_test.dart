import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/features/online_search/data/data_sources/remote/audius_remote_data_source.dart';
import 'package:pulso/features/online_search/data/services/audius_music_service.dart';
import 'package:pulso/shared/base_domain/error/failures.dart';

Map<String, dynamic> _track({
  required String id,
  required String title,
  bool? isStreamable = true,
  Map<String, dynamic>? artwork,
}) => {
  'id': id,
  'title': title,
  'duration': 125,
  'genre': 'Lo-Fi',
  'is_streamable': ?isStreamable,
  'artwork': ?artwork,
  'user': {'name': 'Artista $id', 'handle': 'artista_$id'},
};

void main() {
  group('AudiusMusicService', () {
    late List<Uri> requested;

    AudiusMusicService serviceReturning(List<Map<String, dynamic>> tracks) {
      requested = [];
      return AudiusMusicService(
        AudiusRemoteDataSource(
          httpGet: (uri) async {
            requested.add(uri);
            return jsonEncode({'data': tracks});
          },
        ),
      );
    }

    test(
      'convierte los resultados de Audius en pistas reproducibles',
      () async {
        final service = serviceReturning([
          _track(
            id: 'abc',
            title: 'Lluvia',
            artwork: {'480x480': 'https://img.audius.co/abc-480.jpg'},
          ),
        ]);

        final result = await service.searchTracks('lluvia');
        final tracks = result.dataOrNull!;

        expect(tracks, hasLength(1));
        final track = tracks.single;
        expect(track.id, 'audius:abc');
        expect(track.title, 'Lluvia');
        expect(track.artist, 'Artista abc');
        expect(track.album, 'Audius');
        expect(track.genre, 'Lo-Fi');
        expect(track.duration, const Duration(seconds: 125));
        expect(
          track.uri,
          'https://api.audius.co/v1/tracks/abc/stream?app_name=pulso',
        );
        expect(track.artworkUrl, 'https://img.audius.co/abc-480.jpg');
        expect(track.isRemote, isTrue);
      },
    );

    test('descarta las pistas que Audius no permite reproducir', () async {
      final service = serviceReturning([
        _track(id: 'a', title: 'Libre'),
        _track(id: 'b', title: 'Bloqueada', isStreamable: false),
        _track(id: 'c', title: 'Sin dato', isStreamable: null),
      ]);

      final tracks = (await service.searchTracks('x')).dataOrNull!;

      expect(tracks.map((t) => t.title), ['Libre', 'Sin dato']);
    });

    test('omite los resultados malformados sin perder los válidos', () async {
      final service = serviceReturning([
        {'title': 'Sin id'},
        {'id': 'x', 'title': 'Usuario raro', 'user': 'no-es-un-mapa'},
        _track(id: 'ok', title: 'Válida'),
      ]);

      final tracks = (await service.searchTracks('x')).dataOrNull!;

      expect(tracks.map((t) => t.title), ['Usuario raro', 'Válida']);
      expect(tracks.first.artist, 'Artista desconocido');
    });

    test('solo acepta carátulas servidas por https', () async {
      final service = serviceReturning([
        _track(
          id: 'a',
          title: 'Insegura',
          artwork: {'480x480': 'http://img.audius.co/a.jpg'},
        ),
        _track(
          id: 'b',
          title: 'Local',
          artwork: {'480x480': 'file:///sdcard/a.jpg'},
        ),
      ]);

      final tracks = (await service.searchTracks('x')).dataOrNull!;

      expect(tracks.map((t) => t.artworkUrl), [null, null]);
    });

    test('codifica la búsqueda e identifica la app en la petición', () async {
      final service = serviceReturning(const []);

      await service.searchTracks('  lo fi & chill ');

      final uri = requested.single;
      expect(uri.host, 'api.audius.co');
      expect(uri.path, '/v1/tracks/search');
      expect(uri.queryParameters['query'], 'lo fi & chill');
      expect(uri.queryParameters['app_name'], 'pulso');
    });

    test('no consulta la red cuando la búsqueda está vacía', () async {
      final service = serviceReturning([_track(id: 'a', title: 'A')]);

      final result = await service.searchTracks('   ');

      expect(result.dataOrNull, isEmpty);
      expect(requested, isEmpty);
    });

    test('devuelve NetworkFailure cuando la petición falla', () async {
      final service = AudiusMusicService(
        AudiusRemoteDataSource(
          httpGet: (uri) async => throw Exception('sin conexión'),
        ),
      );

      final result = await service.searchTracks('lluvia');

      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('devuelve NetworkFailure cuando la respuesta no es válida', () async {
      final service = AudiusMusicService(
        AudiusRemoteDataSource(httpGet: (uri) async => '<html>caído</html>'),
      );

      final result = await service.searchTracks('lluvia');

      expect(result.failureOrNull, isA<NetworkFailure>());
      // No debe confundirse con un problema de conexión del usuario.
      expect(result.failureOrNull!.message, contains('respuesta inesperada'));
      expect(result.failureOrNull!.cause, isA<FormatException>());
    });
  });
}
