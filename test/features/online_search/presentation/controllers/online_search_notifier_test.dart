import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/features/online_search/domain/services/online_music_service.dart';
import 'package:pulso/features/online_search/presentation/controllers/online_search_notifier.dart';
import 'package:pulso/shared/base_domain/error/failures.dart';
import 'package:pulso/shared/base_domain/models/track.dart';
import 'package:pulso/shared/base_domain/result/result.dart';

class _FakeOnlineMusicService implements OnlineMusicService {
  Result<List<Track>> response = const Result.ok([]);
  final List<String> queries = [];

  @override
  Future<Result<List<Track>>> searchTracks(String query) async {
    queries.add(query);
    return response;
  }
}

/// Responde cada búsqueda solo cuando el test completa su [Completer].
class _ControlledOnlineMusicService implements OnlineMusicService {
  _ControlledOnlineMusicService(this.pending);

  final List<Completer<Result<List<Track>>>> pending;

  @override
  Future<Result<List<Track>>> searchTracks(String query) {
    final completer = Completer<Result<List<Track>>>();
    pending.add(completer);
    return completer.future;
  }
}

const _track = Track(
  id: 'audius:abc',
  title: 'Lluvia',
  artist: 'Artista',
  album: 'Audius',
  durationMs: 1000,
  uri: 'https://api.audius.co/v1/tracks/abc/stream?app_name=pulso',
);

void main() {
  group('OnlineSearchNotifier', () {
    late _FakeOnlineMusicService service;
    late ProviderContainer container;

    setUp(() {
      service = _FakeOnlineMusicService();
      container = ProviderContainer(
        overrides: [onlineMusicServiceProvider.overrideWithValue(service)],
      );
    });

    tearDown(() => container.dispose());

    test('guarda los resultados de una búsqueda exitosa', () async {
      service.response = const Result.ok([_track]);

      await container
          .read(onlineSearchNotifierProvider.notifier)
          .search('lluvia');

      final state = container.read(onlineSearchNotifierProvider);
      expect(state.query, 'lluvia');
      expect(state.results, [_track]);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.hasSearched, isTrue);
    });

    test('expone el error y limpia los resultados cuando falla', () async {
      service.response = const Result.err(NetworkFailure('Sin conexión'));

      await container
          .read(onlineSearchNotifierProvider.notifier)
          .search('lluvia');

      final state = container.read(onlineSearchNotifierProvider);
      expect(state.results, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, 'Sin conexión');
    });

    test('descarta una respuesta vieja aunque se repita la consulta', () async {
      final pending = <Completer<Result<List<Track>>>>[];
      container.dispose();
      container = ProviderContainer(
        overrides: [
          onlineMusicServiceProvider.overrideWithValue(
            _ControlledOnlineMusicService(pending),
          ),
        ],
      );
      final notifier = container.read(onlineSearchNotifierProvider.notifier);
      const stale = Track(
        id: 'audius:viejo',
        title: 'Vieja',
        artist: 'A',
        album: 'Audius',
        durationMs: 1,
        uri: 'https://api.audius.co/v1/tracks/viejo/stream?app_name=pulso',
      );

      final first = notifier.search('a');
      final second = notifier.search('b');
      final third = notifier.search('a');

      // La primera búsqueda de "a" responde tarde, con la tercera en curso.
      pending[0].complete(const Result.ok([stale]));
      await first;

      final state = container.read(onlineSearchNotifierProvider);
      expect(state.results, isEmpty);
      expect(state.isLoading, isTrue);

      pending[1].complete(const Result.ok([]));
      pending[2].complete(const Result.ok([_track]));
      await Future.wait([second, third]);

      expect(container.read(onlineSearchNotifierProvider).results, [_track]);
    });

    test('ignora búsquedas vacías', () async {
      await container.read(onlineSearchNotifierProvider.notifier).search('  ');

      expect(service.queries, isEmpty);
      expect(container.read(onlineSearchNotifierProvider).hasSearched, isFalse);
    });
  });
}
