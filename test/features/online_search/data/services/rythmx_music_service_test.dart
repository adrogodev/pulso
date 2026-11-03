import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/features/online_search/data/data_sources/remote/rythmx_remote_data_source.dart';
import 'package:pulso/features/online_search/data/services/rythmx_music_service.dart';
import 'package:pulso/shared/base_domain/error/failures.dart';

const _baseUrl = 'http://localhost:8000';

Map<String, dynamic> _song({
  required String id,
  required String title,
  List<String> artists = const ['Daft Punk'],
  String? album = 'Random Access Memories',
  int? durationSeconds = 370,
  String? thumbnail = 'https://lh3.googleusercontent.com/xyz',
  String? streamUrl,
}) => {
  'id': id,
  'title': title,
  'thumbnail': ?thumbnail,
  'duration_seconds': ?durationSeconds,
  'is_explicit': false,
  'artists': [
    for (final name in artists)
      {
        'id': 'UC$name',
        'name': name,
        'songs': <Object>[],
        'albums': <Object>[],
      },
  ],
  if (album != null)
    'album': {
      'id': 'MPREb',
      'title': album,
      'artists': <Object>[],
      'songs': <Object>[],
    },
  'stream_url': streamUrl ?? '$_baseUrl/api/stream/$id',
};

String _envelope(List<Map<String, dynamic>> songs) => jsonEncode({
  'success': true,
  'message': 'Busqueda exitosa',
  'data': {
    'artists': <Object>[],
    'songs': songs,
    'videos': <Object>[],
    'albums': <Object>[],
  },
});

void main() {
  group('RythmxMusicService', () {
    late List<Uri> requested;

    RythmxMusicService serviceReturning(List<Map<String, dynamic>> songs) {
      requested = [];
      return RythmxMusicService(
        RythmxRemoteDataSource(
          baseUrl: _baseUrl,
          httpGet: (uri) async {
            requested.add(uri);
            return _envelope(songs);
          },
        ),
      );
    }

    test('convierte las canciones de la API en pistas reproducibles', () async {
      final service = serviceReturning([
        _song(
          id: '4D7u5KF7SP8',
          title: 'Get Lucky',
          artists: ['Daft Punk', 'Pharrell Williams'],
        ),
      ]);

      final track = (await service.searchTracks('get lucky'))
          .dataOrNull!
          .single;

      expect(track.id, 'rythmx:4D7u5KF7SP8');
      expect(track.title, 'Get Lucky');
      expect(track.artist, 'Daft Punk, Pharrell Williams');
      expect(track.album, 'Random Access Memories');
      expect(track.duration, const Duration(seconds: 370));
      expect(track.uri, '$_baseUrl/api/stream/4D7u5KF7SP8');
      expect(track.artworkUrl, 'https://lh3.googleusercontent.com/xyz');
      expect(track.isRemote, isTrue);
    });

    test('pide solo canciones y codifica la búsqueda', () async {
      final service = serviceReturning(const []);

      await service.searchTracks('  bad bunny & friends ');

      final uri = requested.single;
      expect(uri.scheme, 'http');
      expect(uri.host, 'localhost');
      expect(uri.port, 8000);
      expect(uri.path, '/api/search');
      expect(uri.queryParameters['query'], 'bad bunny & friends');
      expect(uri.queryParameters['filter'], 'songs');
      expect(uri.queryParameters['limit'], '${RythmxRemoteDataSource.limit}');
    });

    test('respeta una URL base con ruta y barra final', () async {
      requested = [];
      final service = RythmxMusicService(
        RythmxRemoteDataSource(
          baseUrl: 'https://api.ejemplo.com/rythmx/',
          httpGet: (uri) async {
            requested.add(uri);
            return _envelope(const []);
          },
        ),
      );

      await service.searchTracks('x');

      expect(
        requested.single.toString(),
        startsWith('https://api.ejemplo.com/rythmx/api/search?'),
      );
    });

    test('completa los campos opcionales que la API omite', () async {
      final service = serviceReturning([
        _song(
          id: 'aaaaaaaaaaa',
          title: 'Sencillo',
          artists: const [],
          album: null,
          durationSeconds: null,
          thumbnail: null,
        ),
      ]);

      final track = (await service.searchTracks('x')).dataOrNull!.single;

      expect(track.artist, 'Artista desconocido');
      expect(track.album, 'YouTube Music');
      expect(track.durationMs, 0);
      expect(track.artworkUrl, isNull);
    });

    test('omite las canciones sin id o sin stream_url válido', () async {
      final service = serviceReturning([
        {'title': 'Sin id', 'stream_url': '$_baseUrl/api/stream/x'},
        _song(id: 'bbbbbbbbbbb', title: 'Sin stream', streamUrl: 'nada'),
        _song(
          id: 'ccccccccccc',
          title: 'Archivo local',
          streamUrl: 'file:///sdcard/a.m4a',
        ),
        _song(id: 'ddddddddddd', title: 'Válida'),
      ]);

      final tracks = (await service.searchTracks('x')).dataOrNull!;

      expect(tracks.map((t) => t.title), ['Válida']);
    });

    test('solo acepta carátulas servidas por https', () async {
      final service = serviceReturning([
        _song(id: 'a', title: 'A', thumbnail: 'http://lh3.example.com/a'),
      ]);

      final track = (await service.searchTracks('x')).dataOrNull!.single;

      expect(track.artworkUrl, isNull);
    });

    test('no consulta la red cuando la búsqueda está vacía', () async {
      final service = serviceReturning([_song(id: 'a', title: 'A')]);

      final result = await service.searchTracks('   ');

      expect(result.dataOrNull, isEmpty);
      expect(requested, isEmpty);
    });

    test('devuelve NetworkFailure cuando el servidor no responde', () async {
      final service = RythmxMusicService(
        RythmxRemoteDataSource(
          baseUrl: _baseUrl,
          httpGet: (uri) async => throw const SocketException('rechazada'),
        ),
      );

      final result = await service.searchTracks('lluvia');

      expect(result.failureOrNull, isA<NetworkFailure>());
      expect(result.failureOrNull!.cause, isA<SocketException>());
    });

    test(
      'trata un sobre con success false como respuesta inesperada',
      () async {
        final service = RythmxMusicService(
          RythmxRemoteDataSource(
            baseUrl: _baseUrl,
            httpGet: (uri) async => jsonEncode({
              'success': false,
              'message': 'Invalid request',
              'error': {'code': 'VALIDATION_ERROR'},
            }),
          ),
        );

        final result = await service.searchTracks('lluvia');

        expect(result.failureOrNull, isA<NetworkFailure>());
        expect(result.failureOrNull!.message, contains('respuesta inesperada'));
        expect(result.failureOrNull!.cause, isA<FormatException>());
      },
    );

    test(
      'trata una respuesta sin lista de canciones como inesperada',
      () async {
        final service = RythmxMusicService(
          RythmxRemoteDataSource(
            baseUrl: _baseUrl,
            httpGet: (uri) async => '<html>caído</html>',
          ),
        );

        final result = await service.searchTracks('lluvia');

        expect(result.failureOrNull!.message, contains('respuesta inesperada'));
      },
    );
  });
}
