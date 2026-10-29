import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/shared/base_data/database/memory_database_service.dart';
import 'package:pulso/shared/base_domain/result/result.dart';
import 'package:pulso/features/favorites/data/services/favorites_repository_impl.dart';

void main() {
  group('FavoritesRepositoryImpl', () {
    late MemoryDatabaseService dbService;
    late FavoritesRepositoryImpl repository;

    setUp(() {
      dbService = MemoryDatabaseService();
      repository = FavoritesRepositoryImpl(dbService);
    });

    tearDown(() async {
      await dbService.close();
    });

    test('agrega y remueve favoritos correctamente', () async {
      var idsResult = await repository.getFavoriteTrackIds();
      expect((idsResult as Success<Set<String>>).data, isEmpty);

      // Agregar favorito
      await repository.toggleFavorite('track-101');
      idsResult = await repository.getFavoriteTrackIds();
      expect(
        (idsResult as Success<Set<String>>).data.contains('track-101'),
        isTrue,
      );

      final isFav = await repository.isFavorite('track-101');
      expect((isFav as Success<bool>).data, isTrue);

      // Quitar favorito al volver a llamar toggle
      await repository.toggleFavorite('track-101');
      idsResult = await repository.getFavoriteTrackIds();
      expect(
        (idsResult as Success<Set<String>>).data.contains('track-101'),
        isFalse,
      );
    });
  });
}
