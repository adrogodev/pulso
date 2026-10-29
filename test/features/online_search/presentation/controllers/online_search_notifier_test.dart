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

    test('ignora búsquedas vacías', () async {
      await container.read(onlineSearchNotifierProvider.notifier).search('  ');

      expect(service.queries, isEmpty);
      expect(container.read(onlineSearchNotifierProvider).hasSearched, isFalse);
    });
  });
}
