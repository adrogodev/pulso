import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/features/online_search/data/services/multi_source_music_service.dart';
import 'package:pulso/features/online_search/domain/services/online_music_service.dart';
import 'package:pulso/shared/base_domain/error/failures.dart';
import 'package:pulso/shared/base_domain/models/track.dart';
import 'package:pulso/shared/base_domain/result/result.dart';

Track _track(String id, {String? title, String artist = 'Artista'}) => Track(
  id: id,
  title: title ?? id,
  artist: artist,
  album: 'Álbum',
  durationMs: 1000,
  uri: 'https://example.com/$id.mp3',
);

/// Fuente de prueba: responde lo indicado y registra las consultas.
class _FakeSource implements OnlineMusicService {
  final Future<Result<List<Track>>> Function() respond;
  final List<String> queries = [];

  _FakeSource(this.respond);

  factory _FakeSource.ok(List<Track> tracks) =>
      _FakeSource(() async => Result.ok(tracks));

  factory _FakeSource.failing([String message = 'caída']) =>
      _FakeSource(() async => Result.err(NetworkFailure(message)));

  @override
  Future<Result<List<Track>>> searchTracks(String query) {
    queries.add(query);
    return respond();
  }
}

void main() {
  group('MultiSourceMusicService', () {
    test('combina los resultados de todas las fuentes', () async {
      final service = MultiSourceMusicService([
        _FakeSource.ok([_track('a:1', title: 'lluvia uno')]),
        _FakeSource.ok([_track('b:1', title: 'lluvia dos')]),
      ]);

      final tracks = (await service.searchTracks('lluvia')).dataOrNull!;

      expect(tracks.map((t) => t.id), ['a:1', 'b:1']);
    });

    test('consulta todas las fuentes en paralelo', () async {
      final slow = Completer<Result<List<Track>>>();
      final first = _FakeSource(() => slow.future);
      final second = _FakeSource.ok(const []);
      final service = MultiSourceMusicService([first, second]);

      final pending = service.searchTracks('salsa');
      await Future<void>.delayed(Duration.zero);

      // La segunda fuente arrancó sin esperar a la primera.
      expect(second.queries, ['salsa']);
      slow.complete(const Result.ok([]));
      await pending;
    });

    test('una fuente caída no rompe la búsqueda', () async {
      final service = MultiSourceMusicService([
        _FakeSource.failing(),
        _FakeSource.ok([_track('b:1', title: 'salsa')]),
      ]);

      final result = await service.searchTracks('salsa');

      expect(result.dataOrNull!.map((t) => t.id), ['b:1']);
    });

    test('una fuente lenta se descarta al vencer el tiempo límite', () async {
      final service = MultiSourceMusicService([
        _FakeSource(() => Completer<Result<List<Track>>>().future),
        _FakeSource.ok([_track('b:1', title: 'salsa')]),
      ], timeout: const Duration(milliseconds: 50));

      final result = await service.searchTracks('salsa');

      expect(result.dataOrNull!.map((t) => t.id), ['b:1']);
    });

    test('si todas las fuentes fallan devuelve el error', () async {
      final service = MultiSourceMusicService([
        _FakeSource.failing('sin red'),
        _FakeSource.failing('sin red'),
      ]);

      final result = await service.searchTracks('salsa');

      expect(result.failureOrNull, isA<NetworkFailure>());
      expect(result.failureOrNull!.message, 'sin red');
    });

    test('no repite una canción y conserva la de la primera fuente', () async {
      final service = MultiSourceMusicService([
        _FakeSource.ok([_track('audius:1', title: 'Lejos', artist: 'Ana')]),
        _FakeSource.ok([_track('jamendo:1', title: 'LEJOS', artist: 'Ána')]),
      ]);

      final tracks = (await service.searchTracks('lejos')).dataOrNull!;

      expect(tracks.map((t) => t.id), ['audius:1']);
    });

    test('reconoce la misma canción aunque cambien los créditos', () async {
      final service = MultiSourceMusicService([
        _FakeSource.ok([
          _track(
            'archive:1',
            title: 'Tú Fuiste Culpable',
            artist: 'Los Astros, Rene Alvarez & Rubén Gonzáles',
          ),
        ]),
        _FakeSource.ok([
          _track(
            'archive:2',
            title: 'Tu Fuiste Culpable (Remastered)',
            artist: 'Rene Alvarez',
          ),
        ]),
      ]);

      final tracks = (await service.searchTracks('culpable')).dataOrNull!;

      expect(tracks.map((t) => t.id), ['archive:1']);
    });

    test('conserva canciones con el mismo título y otro artista', () async {
      final service = MultiSourceMusicService([
        _FakeSource.ok([_track('a:1', title: 'Lejos', artist: 'Ana')]),
        _FakeSource.ok([_track('b:1', title: 'Lejos', artist: 'Beto')]),
      ]);

      final tracks = (await service.searchTracks('lejos')).dataOrNull!;

      expect(tracks.map((t) => t.id), ['a:1', 'b:1']);
    });

    test('prioriza las canciones del artista buscado', () async {
      final service = MultiSourceMusicService([
        _FakeSource.ok([
          _track('a:1', title: 'Bad Bunny - Remix', artist: 'DJ Nadie'),
        ]),
        _FakeSource.ok([_track('b:1', title: 'NUEVAYoL', artist: 'Bad Bunny')]),
      ]);

      final tracks = (await service.searchTracks('bad bunny')).dataOrNull!;

      expect(tracks.map((t) => t.id), ['b:1', 'a:1']);
    });

    test('ordena primero lo que coincide con la búsqueda', () async {
      final service = MultiSourceMusicService([
        _FakeSource.ok([_track('a:1', title: 'Otra cosa', artist: 'Nadie')]),
        _FakeSource.ok([
          _track('b:1', title: 'Mi canción', artist: 'Samu Robles'),
        ]),
      ]);

      final tracks = (await service.searchTracks('samu robles')).dataOrNull!;

      expect(tracks.map((t) => t.id), ['b:1', 'a:1']);
    });

    test('alterna las fuentes cuando la relevancia es la misma', () async {
      final service = MultiSourceMusicService([
        _FakeSource.ok([
          _track('a:1', title: 'salsa 1'),
          _track('a:2', title: 'salsa 2'),
        ]),
        _FakeSource.ok([
          _track('b:1', title: 'salsa 3'),
          _track('b:2', title: 'salsa 4'),
        ]),
      ]);

      final tracks = (await service.searchTracks('salsa')).dataOrNull!;

      expect(tracks.map((t) => t.id), ['a:1', 'b:1', 'a:2', 'b:2']);
    });

    test('no consulta las fuentes cuando la búsqueda está vacía', () async {
      final source = _FakeSource.ok([_track('a:1')]);
      final service = MultiSourceMusicService([source]);

      final result = await service.searchTracks('   ');

      expect(result.dataOrNull, isEmpty);
      expect(source.queries, isEmpty);
    });
  });
}
